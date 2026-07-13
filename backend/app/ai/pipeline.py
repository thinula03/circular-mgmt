"""AIEngine — real implementation of NLPPipeline (FR-11 to FR-16).

Three-stage pipeline, all running locally on the server (NFR-08):

  Stage 1  spaCy (en_core_web_sm)   -> sentence split, POS, NER         (FR-11)
  Stage 2  BERT  (bert-base-uncased) -> sentence embeddings, top-K       (FR-12)
  Stage 3  BART  (facebook/bart-large-cnn) -> abstractive summary        (FR-13)

Models are heavy, so they load lazily on first use and are cached on the instance
(the package exposes a singleton via get_engine()). Heavy libraries are imported
inside the loader, not at module import, to keep app startup fast.
"""
import os
import re
import time
import logging

from .interface import NLPPipeline, SummaryResult
from .llm_summarizer import LLMSummarizer

log = logging.getLogger(__name__)

# backend/model_cache/hub — where Phase 0 downloaded the Hugging Face models.
_BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
_HUB_CACHE = os.path.join(_BACKEND_ROOT, "model_cache", "hub")
# Force offline so inference never reaches the network (NFR-08).
os.environ.setdefault("HF_HUB_OFFLINE", "1")
os.environ.setdefault("TRANSFORMERS_OFFLINE", "1")

# ---- summary length policy (1-page rule) ----------------------------------
# Every circular is condensed to roughly one page (~500 words), regardless of
# how long it is, via budget-allocated map-reduce. A single BART pass only emits
# ~200 words, so long documents are chunked, each chunk gets a slice of the page
# budget, and the parts are combined (and reduced again if still too long).
# Length policy: summarise to ~1/3 of the source, capped at one page (400 words).
# Short circulars get a proportional (1/3) summary; long ones get the one-page cap.
PAGE_WORDS = 400        # one-page cap (upper bound on any summary)
MIN_SUMMARY_WORDS = 80  # floor so tiny circulars still get a usable summary
SUMMARY_RATIO = 3       # 1/3 rule: target ≈ source_words / 3
CHUNK_WORDS = 700       # source chunk size (fits BART's ~1024-token input)
PER_CHUNK_CAP = 250     # max words from one BART pass
PER_CHUNK_FLOOR = 60    # keep each chunk summary readable
STOP_FACTOR = 1.4       # accept the result once it is within 1.4x the page target
MAX_DEPTH = 4           # recursion guard

# Sentences expressing an obligation/action get boosted into the Key Points list.
_REQUIRE_RE = re.compile(
    r"\b(shall|must|required|require|mandatory|deadline|effective|"
    r"within\s+\d+|by\s+\d{1,2}[./]|no later than|prohibited|not permitted|"
    r"with effect from)\b", re.IGNORECASE)

# Circular/direction number references, e.g. "Circular No. 32/2017",
# "Directions No. 03 of 2017", "No. 04 of 2024", "04/2024", "04 of 2024".
_CIRCULAR_NO_RE = re.compile(
    r"\b(?:Circular|Direction|Directions|Instruction|Instructions)?\s*"
    r"No\.?\s*\d+\s*(?:of|/)\s*\d{4}\b"
    r"|\b\d+\s+of\s+\d{4}\b"
    r"|\b\d+/\d{4}\b",
    re.IGNORECASE,
)

# spaCy entity labels we surface as tags (FR-15).
_KEEP_LABELS = {"DATE", "MONEY", "PERCENT", "ORG", "GPE", "LAW", "CARDINAL"}
# Words that mark a genuine organisation — used to reject spaCy's false ORG tags
# on generic title-case phrases like "Aggregate Capital".
_ORG_KEYWORDS = ("bank", "association", "department", "authority", "commission",
                 "ministry", "corporation", "ltd", "limited", "plc", "company",
                 "board", "unit", "agency", "fund", "institute", "council",
                 "bureau", "office", "division", "committee", "central", "sri lanka")
# Map spaCy labels to the friendlier tags used in the UI.
_LABEL_ALIAS = {"GPE": "PLACE", "ORG": "ORG", "LAW": "REGULATION", "CARDINAL": "NUMBER"}


def _clean_text(text: str) -> str:
    """FR-11 preprocessing: normalise PDF-extracted text.

    PDF extraction often leaves hard line breaks mid-sentence and drops spaces
    where lines were joined. Collapsing whitespace and re-inserting spaces at
    glued word/number boundaries gives spaCy clean sentences and stops BART from
    hallucinating on fragmented input.
    """
    if not text:
        return ""
    # Re-insert a space where a line-join glued two words (e.g. "2024Date").
    text = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", " ", text)
    text = re.sub(r"(?<=[.:;])(?=[A-Za-z])", " ", text)
    # Collapse all whitespace (including newlines) to single spaces.
    text = re.sub(r"\s+", " ", text)
    return text.strip()


class AIEngine(NLPPipeline):
    """Real engine: spaCy -> BERT -> BART, loaded offline from the local cache."""

    USE_REAL_MODELS = True

    def __init__(self, config=None):
        self.config = config or {}
        self.bert_model_name = self.config.get("BERT_MODEL", "bert-base-uncased")
        self.bart_model_name = self.config.get("BART_MODEL", "facebook/bart-large-cnn")
        self.bart_fallback_name = self.config.get(
            "BART_FALLBACK_MODEL", "sshleifer/distilbart-cnn-12-6"
        )
        self._spacy = None
        self._bert_tok = None
        self._bert = None
        self._bart = None
        self._bart_used = None  # records which BART model actually loaded (FR-16)
        self._llm = None        # local LLM summariser (Ollama), lazy

    # ---- lazy model loaders -------------------------------------------
    def _load_spacy(self):
        if self._spacy is None:
            import spacy
            self._spacy = spacy.load("en_core_web_sm")
        return self._spacy

    def _load_bert(self):
        if self._bert is None:
            import torch  # noqa: F401
            from transformers import AutoTokenizer, AutoModel
            kw = {"cache_dir": _HUB_CACHE, "local_files_only": True}
            self._bert_tok = AutoTokenizer.from_pretrained(self.bert_model_name, **kw)
            self._bert = AutoModel.from_pretrained(self.bert_model_name, **kw)
            self._bert.eval()
        return self._bert_tok, self._bert

    def _load_bart(self):
        if self._bart is None:
            from transformers import (
                AutoTokenizer,
                AutoModelForSeq2SeqLM,
                pipeline as hf_pipeline,
            )
            kw = {"cache_dir": _HUB_CACHE, "local_files_only": True}
            # Try the full model first; fall back to distilbart (FR-16).
            for name in (self.bart_model_name, self.bart_fallback_name):
                try:
                    tok = AutoTokenizer.from_pretrained(name, **kw)
                    mdl = AutoModelForSeq2SeqLM.from_pretrained(name, **kw)
                    self._bart = hf_pipeline("summarization", model=mdl, tokenizer=tok)
                    self._bart_used = name
                    break
                except Exception:  # noqa: BLE001 — try the fallback model
                    continue
            if self._bart is None:
                raise RuntimeError("No BART summarization model could be loaded.")
        return self._bart

    # ---- public API ----------------------------------------------------
    def summarize(self, text: str, page_words: int = None) -> SummaryResult:
        """Condense a circular into a clear, structured summary.

        Length: the 1/3 rule — target ≈ source_words / 3, capped at one page
        (PAGE_WORDS) and floored at MIN_SUMMARY_WORDS. An explicit page_words
        overrides the computed target.

        Structure (not one blob): an abstractive **Overview** paragraph (spaCy →
        BERT → BART, FR-12/13) followed by a **Key Points** bullet list of the
        most salient/obligation sentences. spaCy NER (FR-11) runs on the whole
        document.
        """
        start = time.perf_counter()
        text = _clean_text(text)
        src_words = max(1, len(text.split()))
        target = int(page_words) if page_words else min(
            max(src_words // SUMMARY_RATIO, MIN_SUMMARY_WORDS), PAGE_WORDS)

        # Preferred: a local instruction-tuned LLM (Ollama) — far more fluent and
        # coherent than BART. Falls back to the BART pipeline if it's unavailable.
        summary, model_used = self._llm_summary(text, target)
        if summary is None:
            # ~55% of the budget to the overview paragraph, the rest to key points.
            overview = self._summarize_to_page(text, max(50, int(target * 0.55)))
            pts_budget = max(40, target - len(overview.split()))
            points = self._key_points(text, max_points=6, budget=pts_budget)
            summary = self._format_structured(overview, points)
            model_used = self._bart_used or self.bart_model_name
        # Key topics: prefer LLM-extracted terms; fall back to KeyBERT-style
        # phrase ranking relevant to the summary (FR-15).
        try:
            entities = self._llm_keywords(summary) or self.extract_keywords(
                text, reference=summary)
        except Exception as exc:  # noqa: BLE001
            log.warning("Keyword extraction failed (%s); using entity fallback.", exc)
            entities = self.extract_entities(text)

        elapsed = round(time.perf_counter() - start, 2)
        return SummaryResult(
            summary_text=summary,
            entities=entities,
            word_count=len(summary.split()),
            bert_model=self.bert_model_name,
            bart_model=model_used,          # provenance: which model produced it
            processing_seconds=elapsed,
        )

    def _llm_summary(self, text, target):
        """Try the local LLM; return (summary, model_name) or (None, None)."""
        if not self.config.get("USE_LLM_SUMMARY", False):
            return None, None
        if self._llm is None:
            self._llm = LLMSummarizer(self.config)
        if not self._llm.available():
            log.info("Ollama not reachable; using BART summariser.")
            return None, None
        # Summary length drives generation time on CPU, so keep it to ~1/3 of the
        # source capped at ~450 words — enough for coverage, much faster than 800.
        src = len(text.split())
        llm_target = min(max(src // 3, 150), 450)
        # Retry once — small models occasionally refuse or return junk.
        for attempt in range(2):
            try:
                summary = self._llm.summarize(text, llm_target)
            except Exception as exc:  # noqa: BLE001 — network/model failure
                log.warning("LLM summary failed (%s); falling back to BART.", exc)
                break
            if self._valid_summary(summary):
                return summary, self._llm.last_model or self.config.get(
                    "OLLAMA_MODEL", "ollama")
            log.info("LLM returned unusable output (attempt %d); retrying.", attempt + 1)
        return None, None

    @staticmethod
    def _valid_summary(summary):
        """Reject refusals / junk (e.g. 'I can't fulfill this request')."""
        if not summary or len(summary.split()) < 25:
            return False
        return "overview" in summary.lower() and "key point" in summary.lower()

    def _llm_keywords(self, summary):
        """LLM-extracted key terms as [{text, label}], or None to fall back."""
        if not self.config.get("USE_LLM_SUMMARY", False):
            return None
        if self._llm is None:
            self._llm = LLMSummarizer(self.config)
        if not self._llm.available():
            return None
        try:
            terms = self._llm.keywords(summary, n=5)
        except Exception as exc:  # noqa: BLE001 — network/model failure
            log.warning("LLM keyword extraction failed (%s); using KeyBERT.", exc)
            return None
        if not terms:
            return None
        return [{"text": t, "label": self._kw_label(t)} for t in terms]

    # ---- structured summary helpers ------------------------------------
    def _key_points(self, text: str, max_points: int = 6, budget: int = 200) -> list:
        """Top salient/obligation sentences as concise bullet points (verbatim-ish).

        Enumerated sub-items in one sentence — "(a) … (b) … (c) …" — are split into
        separate bullets so each requirement gets its own row.
        """
        points, words = [], 0
        for s in self._top_sentences(text, max_points):
            for piece in self._split_enumerated(s):
                piece = re.sub(r"\s+", " ", piece).strip()
                # Trim dangling connectors/punctuation left by the split.
                piece = re.sub(r"[\s,;]+and[\s,;]*$", "", piece, flags=re.IGNORECASE)
                piece = piece.strip().strip(",;").strip()
                if not piece:
                    continue
                w = len(piece.split())
                if words + w > budget and points:
                    return points
                points.append(piece)
                words += w
        return points

    @staticmethod
    def _split_enumerated(sentence: str) -> list:
        """Split "(a) … (b) … (c) …" into separate items; else return as-is."""
        parts = [p for p in re.split(r"\s*(?=\([a-z0-9]{1,3}\))", sentence) if p.strip()]
        return parts if len(parts) > 1 else [sentence]

    def _top_sentences(self, text: str, k: int) -> list:
        """K most central sentences (BERT), boosting obligation sentences, in order."""
        sentences = self._sentences(text)
        if not sentences:
            return []
        if len(sentences) <= k:
            return sentences

        candidates = sentences[:80]                 # bound CPU (NFR-02)
        import torch
        tok, model = self._load_bert()
        inputs = tok(candidates, padding=True, truncation=True, max_length=128,
                     return_tensors="pt")
        with torch.no_grad():
            out = model(**inputs)
        mask = inputs["attention_mask"].unsqueeze(-1).float()
        emb = (out.last_hidden_state * mask).sum(1) / mask.sum(1).clamp(min=1e-9)
        emb = torch.nn.functional.normalize(emb, dim=1)
        doc_emb = torch.nn.functional.normalize(emb.mean(0, keepdim=True), dim=1)
        scores = (emb @ doc_emb.T).squeeze(1)
        # Boost obligations/deadlines so requirements surface as key points.
        boost = torch.tensor([0.12 if _REQUIRE_RE.search(s) else 0.0
                              for s in candidates])
        scores = scores + boost
        top_idx = sorted(torch.topk(scores, k).indices.tolist())  # keep reading order
        return [candidates[i] for i in top_idx]

    @staticmethod
    def _format_structured(overview: str, points: list) -> str:
        """Assemble the Overview + Key Points sections into one structured string."""
        blocks = []
        if overview.strip():
            blocks.append("Overview:\n" + overview.strip())
        if points:
            blocks.append("Key Points:\n" + "\n".join(f"- {p}" for p in points))
        return "\n\n".join(blocks)

    def _summarize_to_page(self, text: str, page_target: int, depth: int = 0) -> str:
        """Summarise `text` to ~page_target words (minimum ~page_target).

        Short text (≤ one chunk) → single spaCy→BERT→BART pass.
        Long text → split into EVEN chunks, force each to fill its share of the
        page budget (tight), combine; if the combined text is still well over a
        page, condense it once more toward the page target (recurse).
        """
        words = text.split()
        n = len(words)

        if n <= CHUNK_WORDS:
            aim = max(1, min(PER_CHUNK_CAP, page_target, n))
            selected = self._extractive_select(text, aim)            # FR-12 BERT
            return self._abstractive(selected, aim, tight=True)      # FR-13 BART

        # Even chunks (no tiny leftover); each gets a share of the page budget.
        num_chunks = -(-n // CHUNK_WORDS)                 # ceil(n / CHUNK_WORDS)
        size = -(-n // num_chunks)                        # balanced chunk size
        per = max(PER_CHUNK_FLOOR, min(PER_CHUNK_CAP, -(-page_target // num_chunks)))
        chunks = [" ".join(words[i:i + size]) for i in range(0, n, size)]
        parts = [self._abstractive(c, per, tight=True) for c in chunks]
        combined = "\n\n".join(p for p in parts if p.strip())

        # Within ~1 page already, or out of recursion budget → return it.
        if len(combined.split()) <= page_target * STOP_FACTOR or depth >= MAX_DEPTH:
            return combined
        # Still much longer than a page → condense the combined text again.
        return self._summarize_to_page(combined, page_target, depth + 1)

    def answer_with_context(self, question: str, context: str,
                            target_words: int = 120) -> str:
        """FR-38: generate a grounded answer to a question from retrieved context.

        Frames the question + context for BART so the abstractive model produces a
        focused, grounded answer (80–150 words) rather than a generic summary.
        """
        context = _clean_text(context)[:4000]
        prompt = (f"Answer the following question using only the context.\n"
                  f"Question: {question}\nContext: {context}")
        return self._abstractive(prompt, target_words)

    def extract_entities(self, text: str, top_n: int = 5) -> list:
        """FR-11/15: spaCy NER for dates, amounts, regulatory references, etc.

        Returns only the `top_n` most relevant entities, ranked by how often each
        appears in the document (frequency is a simple, intuitive salience proxy).
        """
        clean = _clean_text(text)[:100_000]
        nlp = self._load_spacy()
        doc = nlp(clean)  # guard against pathological inputs
        low = clean.lower()

        seen, ents = set(), []
        for ent in doc.ents:
            if ent.label_ not in _KEEP_LABELS:
                continue
            label = _LABEL_ALIAS.get(ent.label_, ent.label_)
            txt = ent.text.strip()
            key = (txt, label)
            if key in seen or not txt:
                continue
            # Drop bare numbers/punctuation (e.g. "1", "1.", "2.2", "25") — they
            # are paragraph labels, not useful keywords. Money/percent/dates keep
            # their letters or units and survive.
            if not re.search(r"[A-Za-z]", txt):
                continue
            # Reject spaCy's false ORG tags on generic phrases: keep an ORG only
            # if it names a real body (has an org keyword) or is an abbreviation
            # (e.g. "SME", "CBSL"). Drops "Aggregate Capital".
            if label == "ORG":
                low_t = txt.lower()
                is_abbr = bool(re.fullmatch(r"[A-Z]{2,6}s?", txt))
                if not (is_abbr or any(k in low_t for k in _ORG_KEYWORDS)):
                    continue
            seen.add(key)
            ents.append({"text": txt, "label": label})
        # Regex catch for explicit circular/direction references (FR-11), including
        # numbers written as "04 of 2024" or "04/2024" (which spaCy otherwise splits
        # into "04" + "2024"). Longer matches first so the full number wins.
        for m in re.findall(_CIRCULAR_NO_RE, text):
            m = re.sub(r"\s+", " ", m).strip()
            key = (m, "REGULATION")
            if key not in seen and m:
                seen.add(key)
                ents.append({"text": m, "label": "REGULATION"})

        # Drop anything already contained in a circular-number entity, so
        # "04 of 2024" doesn't also appear as "04"/"2024", and the fuller
        # "Circular No. 04 of 2024" wins over the bare "04 of 2024".
        reg_texts = [e["text"].lower() for e in ents if e["label"] == "REGULATION"]
        ents = [e for e in ents if not any(
            e["text"].lower() != r and e["text"].lower() in r for r in reg_texts
        )]

        # Rank by frequency of mention (regulatory references get a small boost),
        # then keep the most relevant few. Ties preserve first-seen order.
        for idx, e in enumerate(ents):
            count = low.count(e["text"].lower())
            boost = 1 if e["label"] == "REGULATION" else 0
            e["_rank"] = (count + boost, -idx)
        ents.sort(key=lambda e: e["_rank"], reverse=True)
        return [{"text": e["text"], "label": e["label"]} for e in ents[:top_n]]

    # ---- keyword extraction (KeyBERT-style), FR-15 --------------------
    def extract_keywords(self, text: str, top_n: int = 5, reference: str = None) -> list:
        """Return the top_n most relevant key topics as {text, label}.

        Candidate noun phrases (spaCy) are embedded with BERT and ranked by
        similarity to the summary (or the document), then diversified with MMR so
        the tags are relevant AND non-redundant — unlike raw NER, which mislabels
        and repeats domain terms. Circular numbers are labelled REGULATION; the
        rest are TOPIC.
        """
        clean = _clean_text(text)[:100_000]
        if not clean.strip():
            return []
        nlp = self._load_spacy()
        doc = nlp(clean)

        cands, seen = [], set()
        for nc in doc.noun_chunks:
            toks = [t for t in nc if not (t.is_stop or t.is_punct or t.like_num)]
            phrase = re.sub(r"\s+", " ", " ".join(t.text for t in toks)).strip(" -–—")
            words = phrase.split()
            if not phrase or not (1 <= len(words) <= 4) or len(phrase) < 3:
                continue
            if not re.search(r"[A-Za-z]{3,}", phrase):
                continue
            low = phrase.lower()
            if low in seen:                       # case-insensitive dedupe (Bank/BANK)
                continue
            seen.add(low)
            cands.append(phrase)
            if len(cands) >= 80:                  # bound CPU (NFR-02)
                break
        if not cands:
            return []

        ref = _clean_text(reference)[:3000] if reference else clean[:3000]
        import torch
        embs = self._embed(cands)
        ref_emb = self._embed([ref], max_length=256)
        sims = (embs @ ref_emb.T).squeeze(1)
        for i, c in enumerate(cands):
            if len(c.split()) >= 2:               # prefer specific multi-word topics
                sims[i] = sims[i] + 0.03
        idx = self._mmr(embs, sims, top_n, diversity=0.6)
        return [{"text": cands[i], "label": self._kw_label(cands[i])} for i in idx]

    def _embed(self, texts, max_length: int = 64):
        """Mean-pooled, L2-normalised BERT embeddings for a list of texts."""
        import torch
        tok, model = self._load_bert()
        inputs = tok(texts, padding=True, truncation=True, max_length=max_length,
                     return_tensors="pt")
        with torch.no_grad():
            out = model(**inputs)
        mask = inputs["attention_mask"].unsqueeze(-1).float()
        emb = (out.last_hidden_state * mask).sum(1) / mask.sum(1).clamp(min=1e-9)
        return torch.nn.functional.normalize(emb, dim=1)

    @staticmethod
    def _mmr(embs, sims, k, diversity: float = 0.6):
        """Maximal Marginal Relevance selection: relevant but non-redundant."""
        n = embs.shape[0]
        selected, remaining = [], list(range(n))
        while len(selected) < min(k, n) and remaining:
            if not selected:
                best = max(remaining, key=lambda j: sims[j].item())
            else:
                best = max(remaining, key=lambda j: (
                    diversity * sims[j].item()
                    - (1 - diversity) * max((embs[j] @ embs[s]).item() for s in selected)
                ))
            selected.append(best)
            remaining.remove(best)
        return selected

    @staticmethod
    def _kw_label(phrase: str) -> str:
        if re.search(r"\d+\s*(?:of|/)\s*\d{4}", phrase):
            return "REGULATION"
        return "TOPIC"

    def classify(self, text: str) -> list:
        """Keyword heuristic for compliance category (used by Phase 4, FR-18)."""
        lowered = text.lower()
        keywords = {
            "Anti-Money Laundering": ["money laundering", "aml", "kyc", "suspicious", "due diligence"],
            "Technology Risk": ["cyber", "technology risk", "it system", "data breach", "information security"],
            "Capital Adequacy": ["capital adequacy", "basel", "liquidity", "reserve", "capital ratio"],
            "Consumer Protection": ["consumer", "customer protection", "complaint", "fair treatment"],
        }
        hits = [c for c, kws in keywords.items() if any(k in lowered for k in kws)]
        if not hits:
            hits = ["General"]
        return [{"category": c, "confidence": 0.6, "is_manual": False} for c in hits]

    # ---- stage 1+2: extractive selection via BERT (FR-12) -------------
    def _sentences(self, text: str) -> list:
        nlp = self._load_spacy()
        doc = nlp(text[:100_000])
        sents = [s.text.strip() for s in doc.sents if len(s.text.split()) >= 4]
        return sents

    def _extractive_select(self, text: str, target_words: int) -> str:
        """Embed sentences with BERT, score by centrality, keep the top-K."""
        sentences = self._sentences(text)
        if not sentences:
            return text.strip()
        if len(sentences) <= 3:
            return " ".join(sentences)

        # Cap how many sentences we embed to bound CPU time (NFR-02).
        candidates = sentences[:60]
        import torch
        tok, model = self._load_bert()
        inputs = tok(candidates, padding=True, truncation=True, max_length=128,
                     return_tensors="pt")
        with torch.no_grad():
            out = model(**inputs)
        # Mean-pool token embeddings using the attention mask.
        mask = inputs["attention_mask"].unsqueeze(-1).float()
        summed = (out.last_hidden_state * mask).sum(1)
        counts = mask.sum(1).clamp(min=1e-9)
        emb = summed / counts                       # [N, H]
        emb = torch.nn.functional.normalize(emb, dim=1)
        doc_emb = torch.nn.functional.normalize(emb.mean(0, keepdim=True), dim=1)
        scores = (emb @ doc_emb.T).squeeze(1)        # centrality to the document

        # Pick enough sentences to roughly cover the target length.
        avg_len = max(1, sum(len(s.split()) for s in candidates) // len(candidates))
        k = min(len(candidates), max(4, (target_words // avg_len) + 2))
        top_idx = sorted(torch.topk(scores, k).indices.tolist())  # keep original order
        return " ".join(candidates[i] for i in top_idx)

    # ---- stage 3: abstractive summary via BART (FR-13/14) -------------
    def _abstractive(self, text: str, target_words: int, tight: bool = False) -> str:
        """Summarise `text` to ~target_words (words; BART counts tokens ≈1.3x).

        BART tends to stop near its *minimum* length, so the page-budget map step
        uses tight=True to raise the floor (min_len ≈ target) and actually fill
        each chunk's share. Chat/short paths keep the looser bounds. The target is
        capped to the source length so a small chunk is never padded.
        """
        try:
            summarizer = self._load_bart()
        except RuntimeError as exc:
            log.warning("BART unavailable (%s); using extractive fallback.", exc)
            return self._simple_extractive_summary(text, target_words)
        src_words = max(1, len(text.split()))
        if tight:
            aim = min(target_words, max(20, int(src_words * 0.9)))  # never pad
            max_len = min(450, int(aim * 1.8))
            min_len = min(max_len - 10, int(aim * 1.3))
        else:
            max_len = min(300, max(80, int(target_words * 1.4)))
            min_len = min(max_len - 20, max(40, int(target_words * 0.6)))
        result = summarizer(
            text,
            max_length=max_len,
            min_length=max(20, min_len),
            do_sample=False,
            truncation=True,
        )
        return result[0]["summary_text"].strip()

    def _simple_extractive_summary(self, text: str, target_words: int) -> str:
        """Dependency-light fallback when no generative model is installed."""
        try:
            sentences = self._sentences(text)
        except Exception:  # noqa: BLE001
            sentences = re.split(r"(?<=[.!?])\s+", text)
        sentences = [re.sub(r"\s+", " ", s).strip() for s in sentences if s.strip()]
        if not sentences:
            return " ".join(text.split()[:target_words]).strip()

        picked, used = [], 0
        for sentence in sentences:
            words = sentence.split()
            if len(words) < 4:
                continue
            if picked and used + len(words) > target_words:
                continue
            picked.append(sentence)
            used += len(words)
            if used >= target_words:
                break

        if not picked:
            return " ".join(text.split()[:target_words]).strip()
        return " ".join(picked)

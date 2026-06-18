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

from .interface import NLPPipeline, SummaryResult

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
PAGE_WORDS = 500        # target ~1 page
CHUNK_WORDS = 700       # source chunk size (fits BART's ~1024-token input)
PER_CHUNK_CAP = 200     # max words BART produces coherently in one pass
REDUCE_SLACK = 1.3      # if combined > PAGE_WORDS * slack, summarise again

# spaCy entity labels we surface as tags (FR-15).
_KEEP_LABELS = {"DATE", "MONEY", "PERCENT", "ORG", "GPE", "LAW", "CARDINAL"}
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
        """Condense a circular to ~1 page (page_words, default PAGE_WORDS).

        spaCy NER (FR-11) runs on the whole document; the body is summarised to
        the page target via map-reduce (FR-12/13) so even long circulars are
        covered in full rather than truncated.
        """
        start = time.perf_counter()
        text = _clean_text(text)
        page_target = int(page_words or PAGE_WORDS)
        entities = self.extract_entities(text)
        summary = self._summarize_to_page(text, page_target)
        elapsed = round(time.perf_counter() - start, 2)
        return SummaryResult(
            summary_text=summary,
            entities=entities,
            word_count=len(summary.split()),
            bert_model=self.bert_model_name,
            bart_model=self._bart_used or self.bart_model_name,
            processing_seconds=elapsed,
        )

    def _summarize_to_page(self, text: str, page_target: int) -> str:
        """Recursively summarise `text` down to ~page_target words.

        Short text (≤ one chunk) → single spaCy→BERT→BART pass.
        Long text → split into chunks, give each a slice of the page budget,
        summarise (BART), combine; if still too long, reduce again.
        """
        words = text.split()
        n = len(words)

        if n <= CHUNK_WORDS:
            aim = max(1, min(PER_CHUNK_CAP, page_target, n))
            selected = self._extractive_select(text, aim)   # FR-12 BERT stage
            return self._abstractive(selected, aim)         # FR-13 BART stage

        chunks = [" ".join(words[i:i + CHUNK_WORDS]) for i in range(0, n, CHUNK_WORDS)]
        per = max(50, min(PER_CHUNK_CAP, round(page_target / len(chunks))))
        parts = [self._abstractive(c, per) for c in chunks]
        combined = "\n\n".join(p for p in parts if p.strip())

        # Converged to ~1 page? return; otherwise reduce the combined text again.
        if len(combined.split()) <= page_target * REDUCE_SLACK:
            return combined
        return self._summarize_to_page(combined, page_target)

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

    def extract_entities(self, text: str) -> list:
        """FR-11/15: spaCy NER for dates, amounts, regulatory references, etc."""
        nlp = self._load_spacy()
        doc = nlp(_clean_text(text)[:100_000])  # guard against pathological inputs
        seen, ents = set(), []
        for ent in doc.ents:
            if ent.label_ not in _KEEP_LABELS:
                continue
            label = _LABEL_ALIAS.get(ent.label_, ent.label_)
            key = (ent.text.strip(), label)
            if key in seen or not ent.text.strip():
                continue
            seen.add(key)
            ents.append({"text": ent.text.strip(), "label": label})
        # Regex catch for explicit circular/direction references (FR-11).
        for m in re.findall(r"\b(?:Circular|Direction)\s+No\.?\s*[\w/\-]+", text,
                            flags=re.IGNORECASE):
            key = (m.strip(), "REGULATION")
            if key not in seen:
                seen.add(key)
                ents.append({"text": m.strip(), "label": "REGULATION"})
        return ents[:30]

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
    def _abstractive(self, text: str, target_words: int) -> str:
        summarizer = self._load_bart()
        # token budget ~ 1.4 tokens/word; clamp to the model's comfortable range.
        max_len = min(300, max(80, int(target_words * 1.4)))
        min_len = min(max_len - 20, max(40, int(target_words * 0.6)))
        result = summarizer(
            text,
            max_length=max_len,
            min_length=min_len,
            do_sample=False,
            truncation=True,
        )
        return result[0]["summary_text"].strip()

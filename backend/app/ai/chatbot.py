"""ChatbotService — RAG query pipeline (FR-36 to FR-39).

Pipeline: encode question (SBERT) -> retrieve top-k chunks (FAISS) ->
EXTRACT the most relevant verbatim passage (with citations). All inference runs
locally (NFR-08).

Design note: regulatory answers must be faithful. A compliance officer needs the
exact wording — including enumerated document lists (a./b./c.) — not a paraphrase.
So instead of abstractive summarisation (which collapses lists), we return the
relevant source passage verbatim, located by semantic line matching.
"""
import os
import re
import logging

from .vector_index import VectorIndex

log = logging.getLogger(__name__)

_BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
_HUB_CACHE = os.path.join(_BACKEND_ROOT, "model_cache", "hub")

# Extractive QA reader: pinpoints the exact answer span in the retrieved text and
# returns a confidence score. Optional — if the model isn't in the local cache,
# the chatbot falls back to semantic passage extraction. Download with
# `python download_models.py` (added to the model list).
_QA_MODEL = "distilbert-base-cased-distilled-squad"
_QA_MIN_SCORE = 0.20     # below this the reader is treated as "not confident"

# Enumerated list markers: a.  b)  i.  iv)  1.  -  •
_ITEM_RE = re.compile(r"^\s*(?:[a-zA-Z]|[ivxlcdm]{1,5}|\d{1,2})[.)]\s+|^\s*[-•·]\s+", re.I)
# Words that mark the lead-in sentence before a list / the relevant statement.
_LEADIN_WORDS = ("following", "shall", "as applicable", "required", "must",
                 "obtained", "should", "are to", "include")
# A clause marker like "g)" at the very start of the lead-in line, to strip.
_CLAUSE_PREFIX = re.compile(r"^\s*[a-zA-Z0-9]{1,3}[.)]\s+")


class ChatbotService:
    """Encode -> retrieve -> extract verbatim passage -> cite."""

    def __init__(self, vector_index: VectorIndex, config=None):
        self.index = vector_index
        self.config = config or {}
        self._qa = None    # lazily-loaded extractive QA pipeline (or False if absent)
        self._llm = None   # lazily-loaded local LLM (or False if disabled)

    # ---- grounded LLM answer generation --------------------------------
    def _get_llm(self):
        """Return the local LLM client if enabled, else False."""
        if self._llm is None:
            if not self.config.get("USE_LLM_CHAT", False):
                self._llm = False
            else:
                from .llm_summarizer import LLMSummarizer
                self._llm = LLMSummarizer(self.config)
        return self._llm

    def _llm_answer(self, question, results):
        """Generate a grounded answer from retrieved chunks; None to fall back."""
        llm = self._get_llm()
        if not llm or not llm.available():
            return None
        context = "\n\n".join(f"[{r['circular_number']}] {r['text']}" for r in results[:7])
        try:
            ans = llm.answer(question, context)
        except Exception as exc:  # noqa: BLE001 — network/model failure
            log.warning("LLM chat failed (%s); using extractive answer.", exc)
            return None
        return ans if ans and len(ans.split()) >= 2 else None

    # ---- optional extractive QA reader ---------------------------------
    def _load_qa(self):
        """Load the extractive QA pipeline from the local cache, once.

        Returns the pipeline, or False if the model isn't downloaded (so the
        caller can fall back to semantic extraction without erroring).
        """
        if self._qa is None:
            try:
                from transformers import (AutoTokenizer,
                                          AutoModelForQuestionAnswering,
                                          pipeline as hf_pipeline)
                kw = {"cache_dir": _HUB_CACHE, "local_files_only": True}
                tok = AutoTokenizer.from_pretrained(_QA_MODEL, **kw)
                mdl = AutoModelForQuestionAnswering.from_pretrained(_QA_MODEL, **kw)
                self._qa = hf_pipeline("question-answering", model=mdl, tokenizer=tok)
                log.info("QA reader loaded: %s", _QA_MODEL)
            except Exception as exc:  # noqa: BLE001 — model not cached / load failed
                log.info("QA reader unavailable (%s); using extractive fallback.", exc)
                self._qa = False
        return self._qa

    def _qa_answer(self, question, results):
        """Run the QA reader over retrieved chunks; return (answer, result) or None."""
        qa = self._load_qa()
        if not qa:
            return None
        best = None
        for r in results[:4]:
            try:
                out = qa(question=question, context=r["text"])
            except Exception:  # noqa: BLE001
                continue
            if best is None or out.get("score", 0) > best[0]:
                best = (out.get("score", 0.0), out.get("answer", "").strip(), r)
        if not best or best[0] < _QA_MIN_SCORE or not best[1]:
            log.debug("QA low confidence (%.3f) — falling back.", best[0] if best else 0)
            return None
        score, span, result = best
        # Expand the span to the full sentence it sits in, for a readable answer.
        answer = self._sentence_around(result["text"], span) or span
        log.debug("QA answer (%.3f): %r", score, answer)
        return answer, result

    @staticmethod
    def _sentence_around(text, span):
        """Return the sentence in `text` that contains `span` (verbatim)."""
        flat = re.sub(r"\s+", " ", text)
        pos = flat.lower().find(span.lower())
        if pos < 0:
            return None
        sents = re.split(r"(?<=[.!?])\s+", flat)
        cursor = 0
        for s in sents:
            start = flat.find(s, cursor)
            cursor = start + len(s)
            if start <= pos < cursor:
                return s.strip()
        return None

    # ---- helpers -------------------------------------------------------
    @staticmethod
    def _is_item(line):
        return bool(_ITEM_RE.match(line))

    @staticmethod
    def _is_leadin(line):
        low = line.lower()
        return low.rstrip().endswith(":") or any(w in low for w in _LEADIN_WORDS)

    def _extract_block(self, lines, bi, budget=180):
        """Return a verbatim block around the best line `bi`.

        For list answers: include the lead-in sentence plus all following list
        items. For factual answers: the relevant sentence(s).
        """
        # 1) walk up to the lead-in so list answers include their intro.
        start = bi
        if self._is_item(lines[bi]) or self._is_leadin(lines[bi]):
            j = bi
            while j >= 0 and bi - j <= 6:
                if self._is_leadin(lines[j]) and not self._is_item(lines[j]):
                    start = j
                    break
                j -= 1

        # 2) expand downward, capturing the list (or completing the sentence).
        out, words, seen_item = [], 0, False
        k = start
        while k < len(lines) and words < budget:
            ln = lines[k]
            item = self._is_item(ln)
            if k > start and not item and seen_item:
                break  # the list has ended
            out.append(ln)
            words += len(ln.split())
            if item:
                seen_item = True
            elif k >= bi and ln.rstrip().endswith((".", "!", "?")):
                # factual answer: stop once a sentence completes, unless a list follows
                if not (k + 1 < len(lines) and self._is_item(lines[k + 1])):
                    break
            k += 1

        # 3) strip a leading clause marker ("g) ") from the lead-in line for cleanliness.
        # A lead-in is a full sentence, so a marker like "g)" is just a clause label.
        if out and self._is_leadin(out[0]):
            out[0] = _CLAUSE_PREFIX.sub("", out[0], count=1)
        return [l for l in out if l.strip()]

    def _extract_sentences(self, lines, question, model):
        """Concise factual answer: the most relevant sentence(s), verbatim.

        Used when the answer is prose (no list). Joins the chunk's wrapped lines
        back into sentences and returns the best-matching one (plus a follow-on if
        very short), so the answer stays faithful but not bloated.
        """
        import numpy as np

        text = re.sub(r"\s+", " ", " ".join(lines)).strip()
        sents = [s.strip() for s in re.split(r"(?<=[.!?])\s+", text)
                 if len(s.split()) >= 4]
        if not sents:
            return text[:400]
        qv = model.encode([question], normalize_embeddings=True, convert_to_numpy=True)
        sv = model.encode(sents, normalize_embeddings=True, convert_to_numpy=True)
        sims = (sv @ qv.T).ravel()
        bi = int(np.argmax(sims))
        answer = sents[bi]
        if len(answer.split()) < 12 and bi + 1 < len(sents):
            answer = f"{answer} {sents[bi + 1]}"
        return answer

    # ---- public API ----------------------------------------------------
    def answer(self, question: str, top_k: int = 5, circular_id=None) -> dict:
        # Clean the query (fix typos / split words) before retrieval so a
        # misspelling like "applicatio n" doesn't pull irrelevant chunks. The
        # original question is still used when generating the answer.
        search_q = question
        llm = self._get_llm()
        if llm and llm.available():
            try:
                search_q = llm.refine_query(question)
                if search_q != question:
                    log.debug("Query refined: %r -> %r", question, search_q)
            except Exception:  # noqa: BLE001
                search_q = question

        # circular_id scopes retrieval to a single circular (per-circular chat).
        results = self.index.search(search_q, top_k=top_k, circular_id=circular_id)   # FR-37
        if not results:
            return {
                "answer": ("I couldn't find a relevant circular for that question. "
                           "Make sure circulars have been published and try rephrasing."),
                "citations": [],
            }

        # Relevance gate (global search only): if no retrieved chunk is
        # semantically close enough, reject off-topic questions up front without
        # invoking the LLM. Scoped chat (a chosen circular) always answers.
        min_rel = float(self.config.get("RAG_MIN_RELEVANCE", 0.0) or 0.0)
        if circular_id is None and min_rel > 0:
            best = max((r.get("dense_score", 0.0) for r in results), default=0.0)
            if best < min_rel:
                log.debug("Off-topic query rejected (best dense sim %.3f < %.2f).",
                          best, min_rel)
                return {"answer": "I could not find that in the circulars.",
                        "citations": []}

        # Preferred path: the local LLM generates a fluent, grounded answer from
        # the retrieved chunks. Falls back to extractive methods if unavailable.
        llm_ans = self._llm_answer(question, results)
        if llm_ans is not None:
            return {"answer": llm_ans, "citations": self._citations(results[0], results)}

        # Next: an extractive QA reader pinpoints the answer span with a
        # confidence score. If unavailable/low-confidence, fall back to semantic
        # passage extraction below.
        qa = self._qa_answer(question, results)
        if qa is not None:
            answer, best_result = qa
            return {"answer": answer, "citations": self._citations(best_result, results)}

        # Score individual lines from the top chunks to find the most relevant one.
        model = self.index._load_model()
        candidates = []  # (line, result)
        for r in results[:4]:
            for ln in r["text"].split("\n"):
                if len(ln.split()) >= 2:
                    candidates.append((ln.strip(), r))

        if not candidates:
            answer = results[0]["text"].strip()
            best_result = results[0]
        else:
            import numpy as np
            qv = model.encode([question], normalize_embeddings=True, convert_to_numpy=True)
            lv = model.encode([c[0] for c in candidates], normalize_embeddings=True,
                              convert_to_numpy=True)
            sims = (lv @ qv.T).ravel()
            best = int(np.argmax(sims))
            best_line, best_result = candidates[best]
            lines = [ln.strip() for ln in best_result["text"].split("\n") if ln.strip()]
            try:
                bi = lines.index(best_line)
            except ValueError:
                bi = next((i for i, l in enumerate(lines) if best_line in l), 0)
            # If the relevant region is an enumerated list, return it verbatim
            # (preserve a./b./c.). Otherwise extract the concise relevant sentence.
            window = lines[max(0, bi - 1):bi + 8]
            if any(self._is_item(l) for l in window):
                answer = "\n".join(self._extract_block(lines, bi)).strip() or best_line
            else:
                answer = self._extract_sentences(lines, question, model) or best_line

        return {"answer": answer, "citations": self._citations(best_result, results)}

    @staticmethod
    def _citations(best_result, results):
        """The answer's source chunk first, then other retrieved sources (max 4)."""
        seen, citations = set(), []
        for r in [best_result] + list(results):
            key = (r["circular_number"], r["section"])
            if key not in seen:
                seen.add(key)
                citations.append({"circular_number": r["circular_number"],
                                  "section": r["section"],
                                  "superseded": r.get("superseded", False)})
            if len(citations) >= 4:
                break
        return citations

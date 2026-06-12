"""ChatbotService — RAG query pipeline (FR-36 to FR-39).

Pipeline: encode question (SBERT) -> retrieve top-k chunks (FAISS) ->
EXTRACT the most relevant verbatim passage (with citations). All inference runs
locally (NFR-08).

Design note: regulatory answers must be faithful. A compliance officer needs the
exact wording — including enumerated document lists (a./b./c.) — not a paraphrase.
So instead of abstractive summarisation (which collapses lists), we return the
relevant source passage verbatim, located by semantic line matching.
"""
import re

from .vector_index import VectorIndex

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
    def answer(self, question: str, top_k: int = 5) -> dict:
        results = self.index.search(question, top_k=top_k)   # FR-37
        if not results:
            return {
                "answer": ("I couldn't find a relevant circular for that question. "
                           "Make sure circulars have been published and try rephrasing."),
                "citations": [],
            }

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

        # Citations: the chunk the answer came from first, then other sources.
        seen, citations = set(), []
        for r in [best_result] + results:
            key = (r["circular_number"], r["section"])
            if key not in seen:
                seen.add(key)
                citations.append({"circular_number": r["circular_number"],
                                  "section": r["section"]})
            if len(citations) >= 4:
                break
        return {"answer": answer, "citations": citations}

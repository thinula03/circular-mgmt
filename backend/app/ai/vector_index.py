"""VectorIndex — FAISS index lifecycle for the RAG chatbot (FR-37, FR-40).

Chunks every published circular (200 words, 50-word overlap), embeds each chunk
with Sentence-BERT (all-MiniLM-L6-v2), and stores them in a FAISS inner-product
index (cosine similarity on normalised vectors). The index + chunk metadata are
persisted to disk so they survive restarts, and rebuilt whenever a circular is
published. All inference is local/offline (NFR-08).
"""
import os
import json

# Load Sentence-BERT from the Phase-0 offline cache.
_BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
_HUB_CACHE = os.path.join(_BACKEND_ROOT, "model_cache", "hub")
os.environ.setdefault("HF_HOME", os.path.join(_BACKEND_ROOT, "model_cache"))
os.environ.setdefault("HUGGINGFACE_HUB_CACHE", _HUB_CACHE)
os.environ.setdefault("HF_HUB_OFFLINE", "1")
os.environ.setdefault("TRANSFORMERS_OFFLINE", "1")

_INDEX_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "index_store")


class VectorIndex:
    """Manages the FAISS index: chunk, embed, build, search, persist, load."""

    USE_REAL_FAISS = True

    def __init__(self, config=None):
        self.config = config or {}
        self.embedding_model = self.config.get("SBERT_MODEL", "all-MiniLM-L6-v2")
        self.dimension = 384  # all-MiniLM-L6-v2 output dim
        self._model = None
        self._index = None
        self._chunks = []      # metadata aligned 1:1 with index rows
        os.makedirs(_INDEX_DIR, exist_ok=True)
        self._index_path = os.path.join(_INDEX_DIR, "circulars.faiss")
        self._meta_path = os.path.join(_INDEX_DIR, "chunks.json")
        self._load()

    # ---- model ---------------------------------------------------------
    def _load_model(self):
        if self._model is None:
            from sentence_transformers import SentenceTransformer
            # repo id used at download time; resolves from the offline HF cache.
            self._model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
        return self._model

    # ---- build / rebuild (FR-40) --------------------------------------
    def build(self, circulars):
        """(Re)build the index from published circulars with extracted text.

        `circulars` is an iterable of objects exposing .id, .circular_number and
        .extracted_text (the SQLAlchemy Circular models).
        """
        import faiss
        import numpy as np

        chunks, texts = [], []
        for c in circulars:
            text = (getattr(c, "extracted_text", "") or "").strip()
            if not text:
                continue
            for i, chunk in enumerate(self._chunk_text(text)):
                chunks.append({
                    "circular_id": c.id,
                    "circular_number": c.circular_number,
                    "section": f"para {i + 1}",
                    "text": chunk,
                })
                texts.append(chunk)

        if not texts:
            self._index, self._chunks = None, []
            self._persist()
            return {"total_vectors": 0, "dimension": self.dimension}

        model = self._load_model()
        emb = model.encode(texts, normalize_embeddings=True,
                           convert_to_numpy=True).astype("float32")
        index = faiss.IndexFlatIP(self.dimension)  # cosine via normalised IP
        index.add(emb)
        self._index = index
        self._chunks = chunks
        self._persist()
        return {"total_vectors": len(chunks), "dimension": self.dimension}

    # ---- search (FR-37) ------------------------------------------------
    def search(self, query, top_k=5, circular_id=None):
        """Return the top-K most relevant chunks for a query.

        When `circular_id` is given, results are restricted to that circular
        (the "ask about this circular only" mode). Because the index is flat
        (exhaustive), we over-fetch and filter — no separate index needed.
        """
        if self._index is None or not self._chunks:
            return []
        model = self._load_model()
        q = model.encode([query], normalize_embeddings=True,
                         convert_to_numpy=True).astype("float32")
        # Scoped search must scan all vectors so it can find that circular's
        # chunks even when other circulars rank higher globally.
        k = len(self._chunks) if circular_id is not None else min(top_k, len(self._chunks))
        scores, idx = self._index.search(q, k)
        results = []
        for rank, i in enumerate(idx[0]):
            if i == -1:
                continue
            chunk = dict(self._chunks[i])
            if circular_id is not None and chunk.get("circular_id") != circular_id:
                continue
            chunk["score"] = float(scores[0][rank])
            results.append(chunk)
            if len(results) >= top_k:
                break
        return results

    # ---- persistence ---------------------------------------------------
    def _persist(self):
        import faiss
        if self._index is not None:
            faiss.write_index(self._index, self._index_path)
        with open(self._meta_path, "w", encoding="utf-8") as fh:
            json.dump(self._chunks, fh)

    def _load(self):
        if not (os.path.exists(self._index_path) and os.path.exists(self._meta_path)):
            return
        try:
            import faiss
            self._index = faiss.read_index(self._index_path)
            with open(self._meta_path, "r", encoding="utf-8") as fh:
                self._chunks = json.load(fh)
        except Exception:  # noqa: BLE001 — corrupt index, rebuild on next publish
            self._index, self._chunks = None, []

    def is_empty(self):
        return self._index is None or not self._chunks

    def stats(self):
        return {
            "total_vectors": len(self._chunks),
            "embedding_model": self.embedding_model,
            "dimension": self.dimension,
        }

    # ---- chunking: 200 words / 50-word overlap (AWS guidance) ----------
    @staticmethod
    def _chunk_text(text, size=200, overlap=50):
        """Line-aware chunking that PRESERVES newlines.

        Splitting on whitespace and rejoining would flatten enumerated lists
        (a./b./c.) into prose; keeping line breaks lets the chatbot return the
        original formatting verbatim.
        """
        lines = [ln for ln in (text or "").split("\n")]
        if not any(ln.strip() for ln in lines):
            return []
        chunks, cur, count = [], [], 0
        for ln in lines:
            cur.append(ln)
            count += len(ln.split())
            if count >= size:
                chunks.append("\n".join(cur).strip())
                # keep trailing lines worth ~overlap words for context continuity
                keep, kc = [], 0
                for prev in reversed(cur):
                    keep.insert(0, prev)
                    kc += len(prev.split())
                    if kc >= overlap:
                        break
                cur = keep
                count = sum(len(p.split()) for p in cur)
        tail = "\n".join(cur).strip()
        if tail and (not chunks or tail != chunks[-1]):
            chunks.append(tail)
        return [c for c in chunks if c]

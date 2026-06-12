"""Warm the local model cache so all AI inference runs offline (NFR-08).

Downloads (into backend/model_cache/ via HF_HOME):
  - bert-base-uncased                     (FR-12 extractive embeddings)
  - facebook/bart-large-cnn               (FR-13 abstractive summary)
  - sshleifer/distilbart-cnn-12-6         (FR-16 lightweight fallback)
  - sentence-transformers/all-MiniLM-L6-v2 (FR-37 RAG embeddings)

Run once:  python download_models.py
The spaCy model (en_core_web_sm) is installed separately via `spacy download`.
"""
import os

BACKEND_ROOT = os.path.dirname(os.path.abspath(__file__))
CACHE_DIR = os.path.join(BACKEND_ROOT, "model_cache")
os.makedirs(CACHE_DIR, exist_ok=True)
# Point all Hugging Face downloads at the project-local cache.
os.environ["HF_HOME"] = CACHE_DIR
os.environ["HUGGINGFACE_HUB_CACHE"] = os.path.join(CACHE_DIR, "hub")
# Use the standard HF CDN (the Xet backend timed out) and a generous per-file
# read timeout for slower connections.
os.environ["HF_HUB_DISABLE_XET"] = "1"
os.environ["HF_HUB_DOWNLOAD_TIMEOUT"] = "60"

from huggingface_hub import snapshot_download  # noqa: E402

MODELS = [
    "bert-base-uncased",
    "facebook/bart-large-cnn",
    "sshleifer/distilbart-cnn-12-6",
    "sentence-transformers/all-MiniLM-L6-v2",
]


# Only fetch the files PyTorch inference needs. This skips CoreML (.mlmodel),
# TensorFlow (.h5), Flax (.msgpack), ONNX, and Rust weights — which both shrinks
# the download and avoids Windows long-path failures on deeply nested CoreML dirs.
ALLOW_PATTERNS = ["*.json", "*.txt", "*.safetensors", "*.bin", "*.model"]
# Exclude non-PyTorch artefacts. The CoreML .mlpackage contains a `weight.bin`
# nested so deeply it exceeds Windows' 260-char path limit — must be ignored.
IGNORE_PATTERNS = [
    "*coreml*", "*.mlpackage*", "*.mlmodel",
    "*onnx*", "*openvino*", "*.tflite", "*.h5", "*.msgpack",
    "*rust_model*", "*.ot", "*flax*",
]


def main():
    for repo in MODELS:
        print(f"\n=== Downloading {repo} ===", flush=True)
        snapshot_download(
            repo_id=repo,
            cache_dir=os.environ["HUGGINGFACE_HUB_CACHE"],
            allow_patterns=ALLOW_PATTERNS,
            ignore_patterns=IGNORE_PATTERNS,
            max_workers=4,
        )
        print(f"=== Done {repo} ===", flush=True)
    print("\nAll Hugging Face models cached at:", os.environ["HUGGINGFACE_HUB_CACHE"])


if __name__ == "__main__":
    main()

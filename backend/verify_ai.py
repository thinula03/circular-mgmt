"""Verify every AI model loads OFFLINE from the local cache (NFR-08).

Sets HF_HUB_OFFLINE so any accidental network call fails loudly, then loads
spaCy, BERT, BART, and Sentence-BERT and runs a tiny end-to-end check.
"""
import os

BACKEND_ROOT = os.path.dirname(os.path.abspath(__file__))
CACHE_DIR = os.path.join(BACKEND_ROOT, "model_cache")
os.environ["HF_HOME"] = CACHE_DIR
os.environ["HUGGINGFACE_HUB_CACHE"] = os.path.join(CACHE_DIR, "hub")
os.environ["HF_HUB_OFFLINE"] = "1"          # force offline — no network allowed
os.environ["TRANSFORMERS_OFFLINE"] = "1"

SAMPLE = (
    "The Central Bank of Sri Lanka directs all licensed commercial banks to "
    "strengthen anti-money laundering controls. Enhanced customer due diligence "
    "must be completed for all accounts exceeding five million rupees. Suspicious "
    "transaction reports must be filed within twenty-four hours. Each bank shall "
    "designate a compliance officer responsible for monitoring KYC adherence."
)

print("1/4 spaCy (en_core_web_sm)...")
import spacy
nlp = spacy.load("en_core_web_sm")
doc = nlp(SAMPLE)
ents = [(e.text, e.label_) for e in doc.ents]
print("    NER:", ents[:5])

print("2/4 BERT (bert-base-uncased) tokenizer + model...")
from transformers import AutoTokenizer, AutoModel
tok = AutoTokenizer.from_pretrained("bert-base-uncased")
AutoModel.from_pretrained("bert-base-uncased")
print("    tokens:", len(tok(SAMPLE)["input_ids"]))

print("3/4 BART (facebook/bart-large-cnn) summarization...")
from transformers import pipeline
summarizer = pipeline("summarization", model="facebook/bart-large-cnn")
out = summarizer(SAMPLE, max_length=60, min_length=20, do_sample=False)
print("    SUMMARY:", out[0]["summary_text"])

print("4/4 Sentence-BERT (all-MiniLM-L6-v2) embedding...")
from sentence_transformers import SentenceTransformer
sbert = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
emb = sbert.encode(["What is the deadline for due diligence?"])
print("    embedding dim:", emb.shape)

print("\nAll AI models loaded OFFLINE from local cache. Phase 0 AI stack ready.")

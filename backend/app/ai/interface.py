"""NLPPipeline interface (thesis class diagram, NFR-19 model swappability).

Any summarization engine must fulfil this contract. Decoupling callers from the
concrete engine lets us run a lightweight stub during early development and drop
in the real spaCy->BERT->BART engine later without touching the blueprints.
"""
from abc import ABC, abstractmethod
from dataclasses import dataclass, field


@dataclass
class SummaryResult:
    """Return type of the summarization pipeline."""
    summary_text: str
    entities: list = field(default_factory=list)   # [{text, label}]
    word_count: int = 0
    bert_model: str = ""
    bart_model: str = ""
    processing_seconds: float = 0.0


class NLPPipeline(ABC):
    """Contract for the spaCy -> BERT -> BART summarization pipeline."""

    @abstractmethod
    def summarize(self, text: str, target_words: int = 200) -> SummaryResult:
        """Run preprocess (spaCy) -> extract (BERT) -> abstract (BART)."""

    @abstractmethod
    def extract_entities(self, text: str) -> list:
        """spaCy NER: dates, monetary amounts, regulatory references (FR-11/15)."""

    @abstractmethod
    def classify(self, text: str) -> list:
        """Auto-classify into compliance categories (FR-18)."""

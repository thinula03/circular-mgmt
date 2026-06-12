"""AI layer: summarization pipeline + RAG chatbot.

Singletons are created lazily and shared across requests so models (Phase 3/6)
load once. In Phase 0 these are lightweight stubs.
"""
from .interface import NLPPipeline, SummaryResult
from .pipeline import AIEngine
from .vector_index import VectorIndex
from .chatbot import ChatbotService

_engine = None
_index = None
_chatbot = None


def get_engine(config=None) -> AIEngine:
    global _engine
    if _engine is None:
        _engine = AIEngine(config)
    return _engine


def get_index(config=None) -> VectorIndex:
    global _index
    if _index is None:
        _index = VectorIndex(config)
    return _index


def get_chatbot(config=None) -> ChatbotService:
    global _chatbot
    if _chatbot is None:
        _chatbot = ChatbotService(get_index(config), config)
    return _chatbot


__all__ = ["NLPPipeline", "SummaryResult", "AIEngine", "VectorIndex",
           "ChatbotService", "get_engine", "get_index", "get_chatbot"]

"""Local LLM summariser via Ollama (offline instruction-tuned model, NFR-08).

Produces a faithful, structured summary (Overview + Key Points) from a circular
using a locally-hosted model (default llama3.2:3b). All inference stays on the
machine — Ollama exposes an HTTP API at localhost:11434. If Ollama is not
running, the caller falls back to the BART pipeline.
"""
import re
import json
import logging
import urllib.request

log = logging.getLogger(__name__)


class LLMSummarizer:
    def __init__(self, config=None):
        config = config or {}
        self.url = config.get("OLLAMA_URL", "http://localhost:11434").rstrip("/")
        self.model = config.get("OLLAMA_MODEL", "llama3.2:3b")
        self.timeout = int(config.get("OLLAMA_TIMEOUT", 300))

    # ---- availability -------------------------------------------------
    def available(self) -> bool:
        """True if the Ollama service is reachable (quick check)."""
        try:
            with urllib.request.urlopen(f"{self.url}/api/tags", timeout=3) as r:
                return r.status == 200
        except Exception:  # noqa: BLE001 — service down / not installed
            return False

    # ---- summarisation ------------------------------------------------
    def summarize(self, text: str, target_words: int) -> str:
        """Return a structured summary string (Overview + Key Points)."""
        # Keep input within the model's context window (~8k tokens ≈ 5k words).
        words = text.split()
        if len(words) > 5000:
            text = " ".join(words[:5000])

        payload = {
            "model": self.model,
            "prompt": self._build_prompt(text, target_words),
            "stream": False,
            "options": {"temperature": 0.2, "top_p": 0.9, "num_ctx": 8192},
        }
        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            f"{self.url}/api/generate", data=data,
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=self.timeout) as resp:
            out = json.loads(resp.read().decode("utf-8"))
        return self._normalise(out.get("response", "").strip())

    @staticmethod
    def _build_prompt(text: str, target_words: int) -> str:
        return (
            "You are a banking compliance analyst. Read the regulatory circular "
            "below and write a concise summary for busy bank staff.\n\n"
            'CIRCULAR TEXT:\n"""' + text + '"""\n\n'
            "Rules:\n"
            "- Use ONLY information stated in the circular. Do not add, assume, or invent anything.\n"
            "- Preserve exact figures, dates, deadlines, amounts and defined terms.\n"
            "- Do NOT repeat, quote, or paste the circular text back.\n"
            "- Be clear, concise and grammatical.\n"
            f"- Keep the whole summary to about {target_words} words.\n\n"
            "Write ONLY the following two sections, and nothing after them:\n\n"
            "Overview:\n"
            "<2-4 sentence plain-English overview of what the circular is about>\n\n"
            "Key Points:\n"
            "- <a key requirement, action, eligibility rule or deadline>\n"
            "- <next point>"
        )

    @staticmethod
    def _normalise(resp: str) -> str:
        """Tidy output: strip fences and cut any echoed circular text after the summary."""
        resp = resp.strip()
        if resp.startswith("```"):
            resp = resp.strip("`").strip()
        # Drop any preamble before the Overview section (e.g. "Here is the summary:").
        m = re.search(r"Overview\s*:", resp, re.IGNORECASE)
        if m:
            resp = resp[m.start():].strip()
        # Cut anything the model appended after the summary (echoed source text).
        for marker in ("\nCircular:", "\nCIRCULAR", "\nCircular Text", '\n"""', "\nCircular text"):
            i = resp.find(marker)
            if i != -1:
                resp = resp[:i].strip()
        return resp

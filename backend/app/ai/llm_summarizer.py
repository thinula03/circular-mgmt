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
        # Keep input within the model's context window (~16k tokens ≈ 12k words).
        words = text.split()
        if len(words) > 12000:
            words = words[:12000]
            text = " ".join(words)

        # Size the context to the document (+room for output) so small circulars
        # stay fast and large ones are still read in full.
        need = int(len(words) * 1.4) + 1800
        num_ctx = min(16384, max(4096, need))

        payload = {
            "model": self.model,
            "prompt": self._build_prompt(text, target_words),
            "stream": False,
            "options": {
                "temperature": 0.2,
                "top_p": 0.9,
                "num_ctx": num_ctx,    # read the whole circular
                "num_predict": 1500,   # allow a longer, complete summary
            },
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
            "below and write a thorough summary for bank staff.\n\n"
            'CIRCULAR TEXT:\n"""' + text + '"""\n\n'
            "Rules:\n"
            "- Use ONLY information stated in the circular. Do not add, assume, or invent anything.\n"
            "- Preserve exact figures, dates, deadlines, amounts and defined terms.\n"
            "- Focus on what people must DO: application and approval procedures, "
            "obligations, responsibilities, eligibility conditions, entitlements and "
            "deadlines. Do NOT list definitions or glossary terms.\n"
            "- Be COMPREHENSIVE: capture EVERY such key point across the WHOLE circular "
            "(including sections near the end). It is better to include a point than to "
            "omit it — do not skip important points.\n"
            "- Do NOT repeat, quote, or paste the circular text back.\n"
            "- Be clear and grammatical.\n"
            f"- Aim for roughly {target_words}-{target_words * 2} words; use as many "
            "key-point bullets as the circular needs (do not limit to a few).\n\n"
            "Write ONLY the following two sections, and nothing after them:\n\n"
            "Overview:\n"
            "<3-5 sentence plain-English overview of what the circular is about>\n\n"
            "Key Points:\n"
            "- <a key requirement, action, eligibility rule, procedure or deadline>\n"
            "- <next point>\n"
            "- <continue with one bullet for every important point in the circular>"
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
        # Normalise bullet markers (*, •) to "-" so the UI renders them as a list.
        resp = re.sub(r"(?m)^\s*[*•]\s+", "- ", resp)
        return resp

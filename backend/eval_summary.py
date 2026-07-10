"""Summarization accuracy evaluation — ROUGE + BERTScore (thesis evaluation).

Compares the system's generated summaries against human-written reference
("gold") summaries and reports ROUGE-1/2/L and BERTScore. Use it to quantify
summary quality and to compare methods (e.g. LLM vs BART) objectively.

Setup:
  1. pip install rouge-score bert-score
  2. Edit eval_references.json (a template is created on first run): for each
     circular, write the ideal summary a human would produce.
  3. python eval_summary.py

Notes:
  * It scores the circular's STORED summary (what was published). To evaluate a
    specific method, generate summaries with that method first (e.g. toggle
    USE_LLM_SUMMARY), then run this.
  * BERTScore downloads a model on first use (needs internet once).
"""
import json
import os

from app import create_app
from app.models.circular import Circular
from app.ai import get_engine

REF_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "eval_references.json")

_TEMPLATE = [
    {
        "circular_number": "04 of 2024",
        "reference": "<write the ideal human summary for this circular here>",
    }
]


def load_refs():
    if not os.path.exists(REF_FILE):
        with open(REF_FILE, "w", encoding="utf-8") as fh:
            json.dump(_TEMPLATE, fh, indent=2)
        print(f"Created a template at {REF_FILE}. Fill in reference summaries and re-run.")
        return []
    with open(REF_FILE, "r", encoding="utf-8") as fh:
        return json.load(fh)


def main():
    try:
        from rouge_score import rouge_scorer
    except ImportError:
        print("Missing dependency. Run:  pip install rouge-score bert-score")
        return

    app = create_app()
    with app.app_context():
        refs = load_refs()
        refs = [r for r in refs if r.get("reference") and not r["reference"].startswith("<")]
        if not refs:
            print("No usable references. Fill in eval_references.json.")
            return

        scorer = rouge_scorer.RougeScorer(["rouge1", "rouge2", "rougeL"],
                                          use_stemmer=True)
        gens, golds, rows = [], [], []
        engine = get_engine(app.config)

        for r in refs:
            circ = Circular.query.filter_by(circular_number=r["circular_number"]).first()
            if not circ:
                print(f"[skip] circular '{r['circular_number']}' not found.")
                continue
            if circ.summary and circ.summary.summary_text:
                gen = circ.summary.summary_text
            elif (circ.extracted_text or "").strip():
                gen = engine.summarize(circ.extracted_text).summary_text
            else:
                print(f"[skip] '{r['circular_number']}' has no summary/text.")
                continue
            gens.append(gen)
            golds.append(r["reference"])
            s = scorer.score(r["reference"], gen)
            rows.append((r["circular_number"],
                         s["rouge1"].fmeasure, s["rouge2"].fmeasure, s["rougeL"].fmeasure))

        if not rows:
            print("Nothing to score.")
            return

        # ---- ROUGE table ----
        print("\n" + "=" * 68)
        print(f"{'Circular':<20}{'ROUGE-1':>12}{'ROUGE-2':>12}{'ROUGE-L':>12}")
        print("-" * 68)
        for num, r1, r2, rl in rows:
            print(f"{num[:20]:<20}{r1:>12.3f}{r2:>12.3f}{rl:>12.3f}")
        n = len(rows)
        print("-" * 68)
        print(f"{'AVERAGE':<20}{sum(r[1] for r in rows)/n:>12.3f}"
              f"{sum(r[2] for r in rows)/n:>12.3f}{sum(r[3] for r in rows)/n:>12.3f}")

        # ---- BERTScore (semantic) ----
        try:
            from bert_score import score as bert_score
            _, _, f1 = bert_score(gens, golds, lang="en", verbose=False)
            print(f"\nBERTScore F1 (semantic): {f1.mean().item():.3f}")
        except ImportError:
            print("\n(Install bert-score for the semantic metric: pip install bert-score)")
        print("=" * 68)


if __name__ == "__main__":
    main()

# D:\parental-control-main\backend\toxic_checker.py

from sentence_transformers import SentenceTransformer, util
from transformers import pipeline
import torch
import logging

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("ToxicChecker")


class ToxicChecker:
    def __init__(self):
        log.info("🚀 Loading models once at startup...")

        # ✅ Load sentence embedding model (small + fast)
        self.embed_model = SentenceTransformer('all-MiniLM-L6-v2')

        # ✅ Load lightweight toxic classifier
        device = 0 if torch.cuda.is_available() else -1
        self.tox_model = pipeline(
            "text-classification",
            model="martin-ha/toxic-comment-model",  # lighter than unitary/toxic-bert
            device=device
        )

        # ✅ Prepare offensive reference sentences for similarity detection
        self.offensive_examples = [
            "I will kill you",
            "You are an idiot",
            "You are useless",
            "I will hurt you",
            "Die",
            "Shut up, loser",
            "You stupid",
            "I hate you",
            "Go to hell"
        ]

        self.offensive_embeddings = self.embed_model.encode(
            self.offensive_examples, convert_to_tensor=True
        )

        log.info("✅ All models loaded successfully and ready for use.\n")

    def clean(self, text: str) -> str:
        """Normalize text before embedding."""
        return text.strip().lower()

    def detect_offense(self, text: str, threshold: float = 0.78):
        """Compute similarity between message and offensive reference samples."""
        try:
            emb = self.embed_model.encode(self.clean(text), convert_to_tensor=True)
            sims = util.cos_sim(emb, self.offensive_embeddings)
            max_score = float(sims.max())
            log.info(f"🧩 Similarity score: {max_score:.3f}")
            return (max_score >= threshold, max_score)
        except Exception as e:
            log.exception("❌ Error in detect_offense:")
            return False, 0.0

    def check_toxic(self, text: str):
        """Use pretrained toxic comment classifier."""
        try:
            if len(text) > 512:
                text = text[:512]

            result = self.tox_model(text)[0]
            label = result.get("label", "neutral")
            score = round(result.get("score", 0.0), 3)
            log.info(f"🧠 Toxicity model result: Label={label}, Score={score}")
            return label, score
        except Exception as e:
            log.exception("❌ Error in check_toxic:")
            return "error", 0.0

    def analyze(self, text: str):
        """Main function — combines both similarity + toxic classification."""
        try:
            log.info(f"📩 Analyzing message: '{text}'")
            is_similar, sim_score = self.detect_offense(text)
            label, tox_score = self.check_toxic(text)

            # Mark toxic if either classifier or semantic similarity is strong
            is_toxic = label.lower() in ("toxic", "insult", "threat") and tox_score > 0.75
            flag = 1 if (is_similar or is_toxic) else 0

            result = {
                "flag": flag,
                "similarity_score": sim_score,
                "tox_label": label,
                "tox_score": tox_score,
            }

            log.info(f"✅ Final Analysis → {result}\n")
            return result
        except Exception as e:
            log.exception("❌ Error during full analysis:")
            return {"flag": 0, "similarity_score": 0.0, "tox_label": "error", "tox_score": 0.0}

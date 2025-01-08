from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import spacy

# Load the trained spaCy model
MODEL_PATH = "textcat_goemotions/training/cnn/model-best"  # Path to your trained model
try:
    nlp = spacy.load(MODEL_PATH)
except Exception as e:
    raise RuntimeError(f"Failed to load spaCy model: {e}")

app = FastAPI()

class InputText(BaseModel):
    text: str

@app.post("/predict")
async def predict(input: InputText):
    doc = nlp(input.text)
    return {"text": input.text, "labels": doc.cats}

@app.get("/health")
async def health_check():
    return {"status": "ok"}
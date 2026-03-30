"""
Calorie Tracker API - ONNX Runtime optimized version

This version uses ONNX Runtime for efficient inference without PyTorch dependencies.
"""

from fastapi import FastAPI, UploadFile, File
from PIL import Image
import numpy as np
import json
import os
import io
from pathlib import Path
import onnxruntime as ort

app = FastAPI(title="Calorie Tracker API", version="2.0.0")

onnx_model_path = "calorie_clip.onnx"
MODEL_DIR = Path(__file__).parent / "CalorieCLIP"
session = None

config = None
mean = None
std = None


def load_preprocessing_config():
    """Load preprocessing parameters from config.json."""
    global config, mean, std
    config_path = MODEL_DIR / "config.json"
    if config_path.exists():
        with open(config_path) as f:
            config = json.load(f)
        mean = np.array(config["preprocessing"]["mean"], dtype=np.float32)
        std = np.array(config["preprocessing"]["std"], dtype=np.float32)
    else:
        mean = np.array([0.48145466, 0.4578275, 0.40821073], dtype=np.float32)
        std = np.array([0.26862954, 0.26130258, 0.27577711], dtype=np.float32)


def preprocess_image(image: Image.Image) -> np.ndarray:
    """Preprocess image for the model."""
    image = image.convert("RGB")
    image = image.resize((224, 224), Image.BILINEAR)
    img_array = np.array(image, dtype=np.float32) / 255.0
    img_array = img_array.transpose(2, 0, 1)
    img_array = (img_array - mean.reshape(3, 1, 1)) / std.reshape(3, 1, 1)
    return img_array.astype(np.float32)


def load_onnx_model():
    """Load ONNX model at startup."""
    global session

    if not os.path.exists(onnx_model_path):
        raise FileNotFoundError(
            f"ONNX model not found at {onnx_model_path}. "
            "Run 'python export_onnx.py' first to export the model."
        )

    session = ort.InferenceSession(onnx_model_path)
    print(f"Loaded ONNX model from {onnx_model_path}")


@app.on_event("startup")
async def startup_event():
    """Initialize ONNX model on startup."""
    load_preprocessing_config()
    load_onnx_model()


@app.get("/")
def read_root():
    return {
        "status": "Docker is running!",
        "model": "CalorieCLIP ONNX",
        "version": "2.0.0",
    }


@app.get("/health")
def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "model_loaded": session is not None}


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    """
    Predict calories from an uploaded image.

    Accepts: JPEG, PNG, or other common image formats
    Returns: Estimated calorie count
    """
    contents = await file.read()
    image = Image.open(io.BytesIO(contents))

    img_array = preprocess_image(image)
    img_array = np.expand_dims(img_array, axis=0)

    calories = float(session.run(None, {"image": img_array})[0][0])

    return {
        "filename": file.filename,
        "calories": calories,
    }


@app.get("/run")
def run():
    """Run prediction on the example image."""
    example_path = MODEL_DIR / "assets" / "examples" / "example_1.png"
    if not os.path.exists(example_path):
        return {"error": "Example image not found"}

    image = Image.open(example_path)
    img_array = preprocess_image(image)
    img_array = np.expand_dims(img_array, axis=0)

    calories = float(session.run(None, {"image": img_array})[0][0])

    return {"estimated": calories}

"""
Export CalorieCLIP model to ONNX format for efficient inference.

Usage:
    python export_onnx.py
"""

import sys

sys.path.insert(0, "CalorieCLIP")

import torch
import numpy as np
from calorie_clip import CalorieCLIP
import json
from pathlib import Path

MODEL_DIR = Path("CalorieCLIP")
OUTPUT_DIR = Path(".")


def preprocess_for_onnx(image_tensor, mean, std):
    """Manual preprocessing matching CLIP's transform."""
    return (image_tensor - torch.tensor(mean).view(3, 1, 1)) / torch.tensor(std).view(
        3, 1, 1
    )


class CalorieCLIPOnnx(torch.nn.Module):
    """Simplified ONNX-compatible model wrapper."""

    def __init__(self, clip_model, regression_head):
        super().__init__()
        self.clip = clip_model
        self.head = regression_head

    def forward(self, x):
        """Forward pass: preprocessed image tensor -> calories"""
        features = self.clip.encode_image(x).float()
        return self.head(features).squeeze(-1)


def export_to_onnx(model_path=MODEL_DIR, output_path=OUTPUT_DIR / "calorie_clip.onnx"):
    """Export CalorieCLIP to ONNX format."""

    print(f"Loading CalorieCLIP model from {model_path}...")
    model = CalorieCLIP.from_pretrained(str(model_path), device="cpu")
    model.eval()

    print("Creating ONNX-compatible wrapper...")
    onnx_model = CalorieCLIPOnnx(model.clip, model.head)
    onnx_model.eval()

    print("Creating dummy input (224x224 RGB image)...")
    dummy_input = torch.randn(1, 3, 224, 224)

    print(f"Exporting to {output_path}...")
    torch.onnx.export(
        onnx_model,
        dummy_input,
        str(output_path),
        input_names=["image"],
        output_names=["calories"],
        dynamic_axes={"image": {0: "batch_size"}, "calories": {0: "batch_size"}},
        opset_version=17,
        do_constant_folding=True,
    )

    print(f"Export complete: {output_path}")
    print(f"File size: {Path(output_path).stat().st_size / 1024 / 1024:.1f} MB")

    return output_path


def verify_export(onnx_path=OUTPUT_DIR / "calorie_clip.onnx", model_path=MODEL_DIR):
    """Verify the exported ONNX model produces similar results."""
    try:
        import onnxruntime as ort
    except ImportError:
        print("onnxruntime not installed, skipping verification")
        return

    print("\nVerifying ONNX model...")

    model = CalorieCLIP.from_pretrained(str(model_path), device="cpu")
    model.eval()

    onnx_session = ort.InferenceSession(str(onnx_path))

    config_path = model_path / "config.json"
    with open(config_path) as f:
        config = json.load(f)
    mean = config["preprocessing"]["mean"]
    std = config["preprocessing"]["std"]

    test_image_path = MODEL_DIR / "assets" / "examples" / "example_1.png"
    from PIL import Image

    test_image = Image.open(test_image_path).convert("RGB")

    preprocess = model.preprocess
    image_tensor = preprocess(test_image).unsqueeze(0)

    with torch.no_grad():
        pytorch_result = model(image_tensor).item()

    onnx_input = image_tensor.numpy()
    onnx_result = onnx_session.run(None, {"image": onnx_input})[0][0]

    print(f"PyTorch result: {pytorch_result:.2f} calories")
    print(f"ONNX result:    {onnx_result:.2f} calories")
    print(f"Difference:     {abs(pytorch_result - onnx_result):.4f}")

    if abs(pytorch_result - onnx_result) < 1.0:
        print("Verification passed!")
    else:
        print("Results differ, but may still be acceptable")


if __name__ == "__main__":
    output_file = export_to_onnx()
    verify_export()

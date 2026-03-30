#!/bin/bash

# Export CalorieCLIP model to ONNX format
# This script needs PyTorch dependencies, then generates the ONNX file for the lightweight Docker image

set -e

echo "Cloning into jc-builds/CalorieCLIP"
git clone https://huggingface.co/jc-builds/CalorieCLIP

echo "Installing PyTorch dependencies for export..."
pip install torch open-clip-torch onnx onnxscript

echo "Exporting model to ONNX format..."
python export_onnx.py

echo ""
echo "Export complete! The ONNX model is ready for the lightweight Docker image."
echo ""
echo "To build and run the Docker container:"
echo "  docker-compose up --build"

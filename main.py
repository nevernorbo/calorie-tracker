from fastapi import FastAPI, UploadFile, File
# import torch

# We'll keep it simple for the first test
app = FastAPI()

@app.get("/")
def read_root():
    return {"status": "Docker is running!"}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    # This is where you'll eventually add the model inference code
    return {"filename": file.filename, "message": "Image received by Docker"}

# Clone or download this repo first, then:
from calorie_clip import CalorieCLIP

# Load model from local directory
model = CalorieCLIP.from_pretrained(".")

# Predict calories
@app.get("/run")
def run():
    calories = model.predict("./examples/example_1.png")
    return {"estimated": calories}

# Batch prediction
# images = ["breakfast.jpg", "lunch.jpg", "dinner.jpg"]
# results = model.predict_batch(images)


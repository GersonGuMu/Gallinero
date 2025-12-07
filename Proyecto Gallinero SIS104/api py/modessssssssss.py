from ultralytics import YOLO
import cv2
import uvicorn
from fastapi import FastAPI, WebSocket
import json

app = FastAPI()
model = YOLO("best.pt")

# USAMOS LA CÁMARA DE LA PC
VIDEO_SOURCE = 0   # Luego lo cambiaremos a "http://IP_CAM/stream"

@app.websocket("/ws")
async def inference_ws(ws: WebSocket):
    await ws.accept()

    cap = cv2.VideoCapture(VIDEO_SOURCE)

    while True:
        ret, frame = cap.read()
        if not ret:
            continue

        results = model(frame)
        detections = results[0]

        boxes = detections.boxes.xyxy.tolist()
        conf  = detections.boxes.conf.tolist()
        cls   = detections.boxes.cls.tolist()

        payload = {
            "boxes": boxes,
            "conf": conf,
            "cls": cls
        }

        await ws.send_text(json.dumps(payload))

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)

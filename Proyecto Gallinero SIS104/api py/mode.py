from ultralytics import YOLO
import cv2
import uvicorn
from fastapi import FastAPI, WebSocket
from fastapi.responses import StreamingResponse
import json
import base64

app = FastAPI()
model = YOLO("best.pt")

VIDEO_SOURCE = 0   # cámara PC
class_names = model.names 
# =======================================================
# STREAM DE VIDEO EN JPEG (rápido y compatible)
# =======================================================
def generate_frames():
    cap = cv2.VideoCapture(VIDEO_SOURCE)

    while True:
        ret, frame = cap.read()
        if not ret:
            continue

        _, buffer = cv2.imencode('.jpg', frame)
        frame_bytes = buffer.tobytes()

        yield (
            b"--frame\r\n"
            b"Content-Type: image/jpeg\r\n\r\n" + frame_bytes + b"\r\n"
        )

@app.get("/video")
def video_feed():
    return StreamingResponse(
        generate_frames(),
        media_type="multipart/x-mixed-replace; boundary=frame"
    )


# =======================================================
# ===  WEBSOCKET PARA ENVIAR DETECCIONES YOLO  ==========
# =======================================================
@app.websocket("/ws")
async def inference_ws(ws: WebSocket):
    await ws.accept()

    cap = cv2.VideoCapture(VIDEO_SOURCE)

    while True:
        ret, frame = cap.read()
        if not ret:
            continue

        # YOLO
        results = model(frame)[0]
        boxes = results.boxes.xyxy.tolist()
        conf  = results.boxes.conf.tolist()
        cls   = results.boxes.cls.tolist()
        labels = [class_names[int(c)] for c in cls]

        # FRAME BASE64
        _, buffer = cv2.imencode('.jpg', frame)
        b64_frame = base64.b64encode(buffer).decode("utf-8")

        payload = {
            "frame": b64_frame,
            "boxes": boxes,
            "conf": conf,
            "cls": cls,
            "names": {int(i): name for i, name in model.names.items()}
        }

        await ws.send_text(json.dumps(payload))


# =======================================================
# ===============  EJECUCIÓN CON UVICORN  ===============
# =======================================================
if __name__ == "__main__":
    uvicorn.run(app, host="192.168.5.104", port=8000)

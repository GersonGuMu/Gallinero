from ultralytics import YOLO
import cv2
import uvicorn
from fastapi import FastAPI, WebSocket
from fastapi.responses import StreamingResponse
import json
import base64
import requests

app = FastAPI()

model = YOLO("best.pt")
class_names = model.names 

VIDEO_SOURCE = 0

# =============================================
# 🔥 CLASES QUE SÍ GUARDAN CAPTURA
# =============================================
TARGET_CLASSES = ["Zorro", "Gato", "Buho", "Raton"]


# STREAM DE VIDEO (no se toca)
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
# 🔥  WEBSOCKET ACTUALIZADO
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

        detected_classes = [class_names[int(c)] for c in cls]

        # Convertir frame a base64
        _, buffer = cv2.imencode('.jpg', frame)
        b64_frame = base64.b64encode(buffer).decode("utf-8")

        saved_file = ""

        # ============================================
        # 🔥 SOLO SUBIR CAPTURA SI DETECTA CLASES OBJETIVO
        # ============================================
        if any(dc in TARGET_CLASSES for dc in detected_classes):

            data = {"image": "data:image/jpeg;base64," + b64_frame}

            try:
                r = requests.post("http://localhost/thermal_api/saved_images.php", data=data)
                server_response = r.json()
                saved_file = server_response.get("file", "")
                print("✔ Imagen subida:", saved_file)
            except Exception as e:
                print("❌ Error subiendo la imagen:", e)

        # ============================================

        payload = {
            "frame": b64_frame,
            "boxes": boxes,
            "conf": conf,
            "cls": cls,
            "names": {int(i): name for i, name in model.names.items()},
            "saved_image": saved_file  # nombre de la imagen si se subió
        }

        await ws.send_text(json.dumps(payload))


if __name__ == "__main__":
    uvicorn.run(app, host="192.168.43.127", port=8000)

import serial
import requests
import json
import time

# AJUSTA TU PUERTO COM AQUÍ
SERIAL_PORT = 'COM4' 
BAUD_RATE = 9600
URL_API = "http://localhost/thermal_api/nuevo_api.php" 

try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
    time.sleep(2) # Espera reset Arduino
    print(f"Conectado a {SERIAL_PORT}")
except:
    print(f"No se pudo conectar a {SERIAL_PORT}")
    exit()


ultimo_cambio = ""

while True:
    try:
        # ============================================================
        # 1) LECTURA DEL ARDUINO → POST A PHP
        # ============================================================
        if ser.in_waiting > 0:
            line = ser.readline().decode('utf-8').strip()

            if line:
                print(f"JSON recibido: {line}")

                try:
                    data_dict = json.loads(line)
                    response = requests.post(URL_API, data=data_dict)
                    print(f"Respuesta API: {response.text}")

                except json.JSONDecodeError:
                    print("Error: Lo que llegó no era un JSON válido.")
                except requests.exceptions.RequestException as e:
                    print(f"Error de conexión con PHP: {e}")

        # ============================================================
        # 2) LONG POLLING → detectar cambios en luces
        # ============================================================
        r = requests.get(URL_API)  # puede lanzar excepción, pero ya estamos en UN solo try
        if r.status_code == 200:
            datos = r.json()

            if "luces_estado" in datos and "fecha" in datos:

                estado = int(datos["luces_estado"])
                cambio = datos["fecha"]

                # Si la fecha cambió → hubo actualización de luz
                if cambio != ultimo_cambio:
                    ultimo_cambio = cambio

                    if estado == 1:
                        ser.write(b"LUCES=1\n")
                        #print("→ LUCES=1 enviado")
                    else:
                        ser.write(b"LUCES=0\n")
                        #print("→ LUCES=0 enviado")

        time.sleep(2)

    # ============================================================
    # SOLO UN EXCEPT PARA TODO EL BLOQUE
    # ============================================================
    except Exception as e:
        print(f"Error general en el ciclo: {e}")
        time.sleep(1)

    except KeyboardInterrupt:
        print("Saliendo...")
        ser.close()
        break
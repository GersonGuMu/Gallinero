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

while True:
    try:
        if ser.in_waiting > 0:
            # Leemos la línea JSON del Arduino
            line = ser.readline().decode('utf-8').strip()
            
            if line:
                print(f"JSON recibido: {line}")
                
                try:
                    # Convertimos el texto JSON a un Diccionario de Python
                    # Python acepta 'nan' en el JSON por defecto
                    data_dict = json.loads(line)
                    
                    # Enviamos este diccionario a tu PHP (automáticamente se convierte a POST)
                    response = requests.post(URL_API, data=data_dict)
                    
                    print(f"Respuesta API: {response.text}")
                    
                except json.JSONDecodeError:
                    print("Error: Lo que llegó no era un JSON válido.")
                except requests.exceptions.RequestException as e:
                    print(f"Error de conexión con PHP: {e}")
        # =====================================================
        # 2. GET A LA API → LEER ESTADO DE LUCES
        # =====================================================
        try:
            r = requests.get(URL_API)
            if r.status_code == 200:
                ultimo = r.json()

                if "luces_estado" in ultimo:
                    estado = int(ultimo["luces_estado"])

                    if estado == 1:
                        #print("→ LUCES=1 (encender)")
                        ser.write(b"LUCES=1\n")
                    else:
                        #print("→ LUCES=0 (apagar)")
                        ser.write(b"LUCES=0\n")

        except Exception as e:
            print(f"Error leyendo luces desde BD: {e}")


    except KeyboardInterrupt:
        print("Saliendo...")
        ser.close()
        break
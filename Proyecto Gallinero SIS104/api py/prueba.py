import serial
import time
import sys

# ASEGÚRATE QUE AQUÍ DIGA COM4
SERIAL_PORT = 'COM4'  
BAUD_RATE = 9600

print(f"Intentando abrir {SERIAL_PORT}...")

try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
    time.sleep(2) 
    print(f"¡ÉXITO! Conectado a {SERIAL_PORT}")
except Exception as e:
    print(f"\n--- ERROR DETALLADO ---")
    print(f"No se pudo conectar a {SERIAL_PORT}")
    print(f"Causa: {e}") 
    print(f"-----------------------\n")
    sys.exit() # Detiene el programa aquí
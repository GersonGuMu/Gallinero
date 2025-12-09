import serial.tools.list_ports

print("Buscando puertos disponibles...")
ports = serial.tools.list_ports.comports()

for port in ports:
    print(f"Encontrado: {port.device} - {port.description}")

if not ports:
    print("No se detectó ningún puerto COM.")
#include "DHT.h"
#include <Servo.h>  // <--- 1. Librería agregada

// ---------- SERVO ----------
Servo servoComida;  // <--- 2. Objeto servo
#define SERVO_PIN 6 // <--- 3. Pin del servo (Cable naranja/amarillo)

//---------- Luces -------
#define LIGHT_PIN 4
// ---------- DHT11 ----------
#define DHTPIN 2
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// ---------- SENSOR DE AGUA ----------
#define AGUA_PIN A0

// ---------- BOMBA / TRANSISTOR ----------
#define PUMP_PIN 8        //ex 8 Pin que activa el transistor 2N2222

// UMBRALES del sensor de agua
const int TH_LOW = 500;   // < 300 = nivel bajo -> ENCENDER bomba
const int TH_HIGH = 600;  // >= 700 = nivel alto -> APAGAR bomba

#define FAN_PIN 5
const float TEMP_ON = 25.0;
#define TRIG 12
#define ECHO 7

// Estados
bool bombaEncendida = false;
bool ventiladorEncendido = false;
bool luzEncendida = false;
int valorComida = 35;
int duracion;

// Variable para saber si el servo está activo (opcional, para debug)
bool servoAbierto = false; 

void setup() {
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);
  Serial.begin(9600);
  dht.begin();

  pinMode(PUMP_PIN, OUTPUT);
  digitalWrite(PUMP_PIN, LOW); // bomba apagada por seguridad
  
  pinMode(FAN_PIN, OUTPUT);    // Faltaba definir el pin del ventilador como salida
  digitalWrite(FAN_PIN, LOW); 

  // --- CONFIGURACIÓN SERVO ---
  servoComida.attach(SERVO_PIN);
  servoComida.write(95); // Iniciar cerrado (95 grados)

  Serial.println("Sistema iniciado (DHT11 + agua + bomba + servo)");
}

void loop() {

  leerLuces();
  // -------- Lectura DHT11 --------
  delay(2000);  // DHT11 necesita 2 segundos

  float humedad = dht.readHumidity();
  float temperatura = dht.readTemperature();

  if (isnan(humedad) || isnan(temperatura)) {
    Serial.println("Error en lectura DHT11");
  }

  // Solo actuamos si la lectura es válida
  if (!isnan(temperatura)) {
      // Si temperatura es mayor a 21 y el ventilador no está prendido -> ENCENDER
      if (temperatura > TEMP_ON && !ventiladorEncendido) {
          encenderVentilador();
      }
      // Si temperatura es menor o igual a 21 y el ventilador está prendido -> APAGAR
      else if (temperatura <= TEMP_ON && ventiladorEncendido) {
          apagarVentilador();
      }
  }
  
  // -------- SENSOR DE COMIDA (Ultrasonico) --------

  // 1. Limpiamos el pin TRIG
  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);
  
  // 2. Enviamos un pulso de 10 microsegundos
  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10); // IMPORTANTE: Usar delayMicroseconds
  digitalWrite(TRIG, LOW);
  
  duracion = pulseIn(ECHO, HIGH, 30000);
  
  // Evitar división por cero o lecturas erróneas si duracion es 0
  if (duracion == 0) {
    valorComida = 0; 
  } else {
    valorComida = duracion / 58.2;
  }

  // -------- LÓGICA DEL SERVO (NUEVO) --------
  // Histéresis: Abre en 140, cierra en 130
  if (valorComida >= 18) {
     servoComida.write(150); // Girar 140 grados
     servoAbierto = true;
  } 
  else if (valorComida <= 13) {
     servoComida.write(95);  // Volver a 95 grados
     servoAbierto = false;
  }

  // -------- Sensor de agua --------
  int valorAgua = analogRead(AGUA_PIN);

  // Lógica para encender y apagar bomba
  if (!bombaEncendida && valorAgua < TH_LOW) {
    encenderBomba();
  } 
  else if (bombaEncendida && valorAgua >= TH_HIGH) {
    apagarBomba();
  }
  
  //int valorAguaTrue=valorAgua*4/7; // (Comentado ya que no se usa)
  int valorComidaTrue;
  if (valorComida>19){
    valorComidaTrue=100;
  }else if(valorComida<=12){
    valorComidaTrue=0;
  }else{
    valorComidaTrue=(18-valorComida)*100/6;
  }
  
  // --- ENVÍO DE JSON POR SERIAL ---
  Serial.print("{\"temperatura\":");
  Serial.print(temperatura); 
  Serial.print(",\"humedad\":");
  Serial.print(humedad);
  Serial.print(",\"nivel_agua\":");
  Serial.print(valorAgua);
  Serial.print(",\"bomba_estado\":");
  Serial.print(bombaEncendida);
  Serial.print(",\"ventilador_estado\":");
  Serial.print(ventiladorEncendido);
  Serial.print(",\"nivel_comida\":");
  Serial.print(valorComidaTrue);
  Serial.print(",\"servo_estado\":"); // Agregué el estado del servo al JSON
  Serial.print(servoAbierto);
  Serial.print(",\"luces_estado\":");
  Serial.print(luzEncendida);
  Serial.println("}"); // Cerramos llave y salto de línea
}


void encenderBomba() {
  digitalWrite(PUMP_PIN, HIGH);  // activa 2N2222
  bombaEncendida = true;
  Serial.println("Bomba ENCENDIDA (nivel BAJO)");
}

void apagarBomba() {
  digitalWrite(PUMP_PIN, LOW);
  bombaEncendida = false;
  Serial.println("Bomba APAGADA (nivel ALTO)");
}


void encenderVentilador() {
  digitalWrite(FAN_PIN, HIGH);
  ventiladorEncendido = true;
  Serial.println("Ventilador ENCENDIDO");
}
void apagarVentilador() {
  digitalWrite(FAN_PIN, LOW);
  ventiladorEncendido = false;
  Serial.println("Ventilador APAGADO");
}
void leerLuces() {
    if (Serial.available()) {
        String cmd = Serial.readStringUntil('\n');

        if (cmd == "LUCES=1") {
            digitalWrite(LIGHT_PIN, HIGH);
            luzEncendida = true;
            Serial.println("LUZ ENCENDIDA");
        }

        if (cmd == "LUCES=0") {
            digitalWrite(LIGHT_PIN, LOW);
            luzEncendida = false;
            Serial.println("LUZ APAGADA");
        }
    }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart'; // Para la hora actual

class DetectionMessagesScreen extends StatefulWidget {
  @override
  _DetectionMessagesScreenState createState() => _DetectionMessagesScreenState();
}

class _DetectionMessagesScreenState extends State<DetectionMessagesScreen> {
  // Conexión al WebSocket (Usa la misma IP que pusiste en Python: 192.168.108.1)
  final _channel = WebSocketChannel.connect(
    Uri.parse('ws://192.168.43.127:8000/ws'),
  );

  // Lista de mensajes (estado mutable)
  final List<_Msg> messages = [];

  // Control para no saturar la lista (Anti-spam)
  DateTime? _lastNotificationTime;
  final int _cooldownSeconds = 5; // Solo permitir una notificación cada 5 segundos

  // Clases que consideramos peligrosas/alertas (Deben coincidir con tu Python)
  final List<String> targetClasses = ["Zorro", "Gato", "Buho", "Raton"];

  @override
  void initState() {
    super.initState();
    _listenToWebSocket();
  }

  void _listenToWebSocket() {
    _channel.stream.listen((message) {
      try {
        final data = jsonDecode(message);

        // 1. Obtener detecciones
        List<dynamic> clsIndices = data['cls'] ?? [];
        Map<String, dynamic> namesMap = data['names'] ?? {};

        if (clsIndices.isEmpty) return; // Si no hay nada, ignoramos

        // 2. Verificar Cooldown (para no llenar la pantalla de mensajes repetidos)
        final now = DateTime.now();
        if (_lastNotificationTime != null &&
            now.difference(_lastNotificationTime!).inSeconds < _cooldownSeconds) {
          return;
        }

        // 3. Procesar qué se detectó
        List<String> detectedNames = [];
        bool isAlert = false;

        for (var c in clsIndices) {
          // YOLO a veces manda floats, aseguramos int
          int index = (c as num).toInt();
          // Python manda el mapa con keys string "0", "1", etc.
          String name = namesMap[index.toString()] ?? 'Desconocido';
          detectedNames.add(name);

          // Si el nombre está en tu lista de TARGET_CLASSES es Alerta Roja
          if (targetClasses.contains(name)) {
            isAlert = true;
          }
        }

        // 4. Crear el mensaje
        if (detectedNames.isNotEmpty) {
          // Unir nombres (ej: "Gato, Raton")
          String textMsg = "Se detectó: ${detectedNames.toSet().join(', ')}";

          final newMsg = _Msg(
            text: textMsg,
            time: DateFormat('HH:mm:ss').format(now),
            isAlert: isAlert,
          );

          // 5. Actualizar la UI
          if (mounted) {
            setState(() {
              // Insertamos al principio para que salga arriba
              messages.insert(0, newMsg);
              _lastNotificationTime = now;
            });
          }
        }

      } catch (e) {
        print("Error parseando datos del WS: $e");
      }
    }, onError: (error) {
      print("Error de WebSocket: $error");
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Monitor de Detecciones')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            // Indicador de estado (Opcional, para saber que está escuchando)
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.black12,
              width: double.infinity,
              child: Text("Escuchando cámara en vivo...",
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: messages.isEmpty
                  ? Center(child: Text("Esperando detecciones..."))
                  : ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];

                  final container = Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      // Rojo si es alerta (animal objetivo), Gris si es otra cosa
                      color: m.isAlert ? Colors.red.shade200 : Colors.deepOrange.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(m.isAlert ? Icons.warning : Icons.info,
                                  color: m.isAlert ? Colors.red : Colors.black54),
                              SizedBox(width: 8),
                              Text(m.text, style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Text(m.time, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  );

                  return Align(
                    alignment: Alignment.centerRight,
                    child: m.isAlert
                        ? GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/detections'),
                        child: container)
                        : container,
                  );
                },
              ),
            ),
            ElevatedButton(
                onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')),
                child: Text('Inicio')
            ),
          ],
        ),
      ),
    );
  }
}

class _Msg {
  final String text;
  final String time;
  final bool isAlert;
  _Msg({required this.text, required this.time, this.isAlert = false});
}
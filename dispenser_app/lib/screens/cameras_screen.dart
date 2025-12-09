import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class CamerasScreen extends StatefulWidget {
  @override
  _CamerasScreenState createState() => _CamerasScreenState();
}

class _CamerasScreenState extends State<CamerasScreen> {
  late WebSocketChannel channel;

  Uint8List? frameBytes;
  List<dynamic> boxes = [];
  List<dynamic> conf = [];
  List<dynamic> cls = [];

  Map<int, String> names = {};
  double videoW = 640;
  double videoH = 480;
  List<String> savedImages = [];
  @override
  void initState() {
    super.initState();

    channel = WebSocketChannel.connect(
      Uri.parse("ws://192.168.43.127:8000/ws"),
    );

    channel.stream.listen((data) {
      final jsonData = jsonDecode(data);

      // Convertir names correctamente (puede venir como Map<String,String>)
      Map<String, dynamic> rawNames = Map<String, dynamic>.from(jsonData["names"]);

      setState(() {
        frameBytes = base64Decode(jsonData["frame"]);
        boxes = List.from(jsonData["boxes"]);
        conf = List.from(jsonData["conf"]);
        cls = List.from(jsonData["cls"]);

        names = {
          for (var entry in rawNames.entries)
            int.parse(entry.key): entry.value.toString()
        };

        if (jsonData["saved_image"] != null &&
            jsonData["saved_image"] != "") {
          savedImages.add(jsonData["saved_image"]);
        }
      });
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cámara YOLO WebSocket")),
      body: Center(
        child: frameBytes == null
            ? CircularProgressIndicator()
            : AspectRatio(
          aspectRatio: videoW / videoH,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scaleX = constraints.maxWidth / videoW;
              final scaleY = constraints.maxHeight / videoH;

              return Stack(
                children: [
                  Image.memory(
                    frameBytes!,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    fit: BoxFit.cover,
                  ),

                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: BoxesPainter(
                      boxes,
                      cls,
                      conf,
                      scaleX,
                      scaleY,
                      names,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class BoxesPainter extends CustomPainter {
  final List<dynamic> boxes;
  final List<dynamic> cls;
  final List<dynamic> conf;
  final double scaleX;
  final double scaleY;
  final Map<int, String> names;

  BoxesPainter(this.boxes, this.cls, this.conf, this.scaleX, this.scaleY, this.names);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final textStyle = TextStyle(
      color: Colors.white,
      backgroundColor: Colors.green,
      fontSize: 12,
    );

    for (int i = 0; i < boxes.length; i++) {
      var b = boxes[i];

      double x1 = b[0] * scaleX;
      double y1 = b[1] * scaleY;
      double x2 = b[2] * scaleX;
      double y2 = b[3] * scaleY;

      Rect rect = Rect.fromLTRB(x1, y1, x2, y2);
      canvas.drawRect(rect, paint);

      int classId = cls[i] is int ? cls[i] : (cls[i] as num).toInt();
      String className = names[classId] ?? "unknown";

      String label = "$className ${(conf[i] * 100).toStringAsFixed(1)}%";

      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      );

      tp.layout();
      tp.paint(canvas, Offset(x1, y1 - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

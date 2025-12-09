import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Thermal2Screen extends StatefulWidget {
  @override
  _Thermal2Screen createState() => _Thermal2Screen();
}

class _Thermal2Screen extends State<Thermal2Screen> {
  final String serverUrl = "http://localhost/thermal_api/api.php";

  // ESTADOS
  double _temperature = 0.0;
  double _humidity = 0.0;
  bool _fanOn = false;
  bool isLoading = true;
  String errorMessage = "";

  // Cargar datos desde PHP
  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.get(Uri.parse(serverUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _temperature = (data['temperatura'] ?? 0).toDouble();
          _humidity = (data['humedad'] ?? 0).toDouble();
          _fanOn = data['ventilador_estado'] ?? false;
          isLoading = false;
        });
      } else {
        throw Exception("Error código: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error al conectar con el servidor: $e";
      });
    }
  }

  // Guardar datos (solo el ventilador)
  Future<void> _saveData() async {
    try {
      final Map<String, dynamic> newData = {
        "ventilador_estado": _fanOn
      };

      await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(newData),
      );
    } catch (e) {
      print("Error guardando datos: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _toggleFan() {
    setState(() {
      _fanOn = !_fanOn;
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/fondop.jpg"), // <-- tu imagen
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Opacidad blanca
          Container(color: Colors.white.withOpacity(0.9)),

          SafeArea(
            child: Center(
              child: isLoading
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Cargando datos..."),
                ],
              )
                  : errorMessage.isNotEmpty
                  ? Text(errorMessage,
                  style: const TextStyle(color: Colors.red))
                  : _buildMainUI(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainUI() {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.purple, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'TEMPERATURA',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildGaugeCard(
            title: "TEMPERATURA",
            currentValue: _temperature,
            unit: "°C",
            color: Colors.red,
            maxValue: 100,
          ),

          const SizedBox(height: 20),

          _buildGaugeCard(
            title: "HUMEDAD",
            currentValue: _humidity,
            unit: "%",
            color: Colors.blue,
            maxValue: 100,
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: _toggleFan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple, width: 1),
                borderRadius: BorderRadius.circular(5),
                color: _fanOn
                    ? Colors.purple.withOpacity(0.2)
                    : Colors.transparent,
              ),
              child: Text(
                _fanOn ? "VENTILADOR ENCENDIDO" : "VENTILADOR APAGADO",
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TARJETA DEL SLIDER
  Widget _buildGaugeCard({
    required String title,
    required double currentValue,
    required String unit,
    required Color color,
    required double maxValue,
  }) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 14)),

          const SizedBox(height: 10),

          SleekCircularSlider(
            min: 0,
            max: maxValue,
            initialValue: currentValue,
            appearance: CircularSliderAppearance(
              size: 120,
              startAngle: 180,
              angleRange: 180,
              customWidths: CustomSliderWidths(
                trackWidth: 8,
                progressBarWidth: 8,
              ),
              customColors: CustomSliderColors(
                trackColor: Colors.grey.shade700,
                progressBarColor: color,
              ),
            ),
            innerWidget: (value) => Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                        color: color,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    unit,
                    style: TextStyle(color: color, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

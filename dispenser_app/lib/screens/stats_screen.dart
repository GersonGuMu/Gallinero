import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? data;
  String? endpoint;
  bool isLoading = true;
  String errorMessage = '';
  String? tipo; // 'agua' o 'comida'

  final String serverUrl = 'http://localhost/thermal_api';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args != null && endpoint == null) {
      endpoint = args as String;
      // Detectar si es agua o comida basado en el endpoint
      _detectarTipo();
      _cargarDatosServidor();
    }
  }

  void _detectarTipo() {
    if (endpoint!.startsWith('vaso')) {
      tipo = 'agua';
    } else if (endpoint!.startsWith('comida')) {
      tipo = 'comida';
    } else {
      tipo = 'general';
    }
  }

  String _getApiUrl() {
    if (tipo == 'agua') {
      return '$serverUrl/agua_api.php?vaso=$endpoint';
    } else {
      return '$serverUrl/comida_api.php?plato=$endpoint';
    }
  }

  Future<void> _cargarDatosServidor() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final apiUrl = _getApiUrl();
      print('🔄 Cargando datos desde: $apiUrl');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        print('✅ Datos recibidos: $jsonData');

        setState(() {
          data = jsonData;
          isLoading = false;
        });

      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }

    } catch (e) {
      print('❌ Error cargando datos: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error cargando datos: $e';

        // Datos de ejemplo según el tipo
        if (tipo == 'agua') {
          data = {"vacio": 30, "agua": 70};
        } else {
          data = {"vacio": 10, "comida": 90};
        }
      });
    }
  }

  Color _getAppBarColor() {
    switch (tipo) {
      case 'agua':
        return Colors.blueAccent;
      case 'comida':
        return Colors.orangeAccent;
      default:
        return Colors.greenAccent;
    }
  }

  String _getTitulo() {
    switch (tipo) {
      case 'agua':
        return 'Nivel de Agua - ${endpoint?.toUpperCase() ?? "Vaso"}';
      case 'comida':
        return 'Estadísticas - ${endpoint?.toUpperCase() ?? "Comida"}';
      default:
        return 'Estadísticas - ${endpoint ?? "General"}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cargando...'),
          backgroundColor: _getAppBarColor(),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando datos del servidor...'),
              if (endpoint != null) ...[
                SizedBox(height: 8),
                Text('$endpoint', style: TextStyle(color: Colors.grey)),
                if (tipo != null) Text('Tipo: $tipo', style: TextStyle(color: Colors.grey)),
              ],
            ],
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty && data == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
          backgroundColor: Colors.redAccent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 50),
              SizedBox(height: 16),
              Text('Error cargando datos', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text(errorMessage, textAlign: TextAlign.center),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _cargarDatosServidor,
                child: Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Calcular datos para el gráfico
    final total = data!.values.fold<double>(0, (sum, val) => sum + (val is num ? val.toDouble() : 0));
    final sections = data!.entries.map((entry) {
      final value = entry.value is num ? entry.value.toDouble() : 0.0;
      final percentage = total > 0 ? (value / total) * 100 : 0;
      return PieChartSectionData(
        value: value,
        title: total > 0 ? '${entry.key}\n${percentage.toStringAsFixed(1)}%' : '${entry.key}\n0%',
        color: _getColor(entry.key),
        radius: 100,
        titleStyle: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitulo()),
        backgroundColor: _getAppBarColor(),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Datos desde servidor: $serverUrl',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: 10),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 3,
                ),
              ),
            ),
            SizedBox(height: 20),
            if (data != null) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'Resumen:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ...data!.entries.map((entry) =>
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${entry.key}:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('${entry.value}'),
                            ],
                          ),
                        )
                    ).toList(),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getAppBarColor(),
                foregroundColor: Colors.white,
              ),
              child: Text('Inicio'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(String key) {
    switch (key.toLowerCase()) {
      case 'vacio':
        return Colors.grey;
      case 'agua':
        return Colors.blueAccent;
      case 'comida':
        return Colors.orangeAccent;
      case 'proteina':
        return Colors.redAccent;
      case 'carbohidratos':
        return Colors.greenAccent;
      default:
        return Colors.purpleAccent;
    }
  }
}
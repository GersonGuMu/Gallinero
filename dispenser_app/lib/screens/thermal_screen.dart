import 'package:flutter/material.dart';
import 'home_button.dart';
import 'info_box.dart';
import 'regulador_button.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
//import 'package:http/http.dart' as http;

class ThermalScreen extends StatefulWidget {
  @override
  _ThermalScreen createState() => _ThermalScreen();
}

class _ThermalScreen extends State<ThermalScreen> {
  Map<String, dynamic>? data;
  String? jsonFile;
  bool isLoading = true;
  String errorMessage = '';

  // Variables de estado
  bool _ventiladorEstado = false;
  double _velocidadVentilador = 0;
  double _temperaturaDeseada = 22;
  double _humedadDeseada = 50;

  final String serverUrl = 'http://localhost/thermal_api'; // Usa tu IP

  @override
  void initState() {
    super.initState();
    _cargarDatosServidor();
  }

  Future<void> _cargarDatosServidor() async {
    try {
      setState(() { isLoading = true; errorMessage = ''; });

      final response = await http.get(
        Uri.parse('$serverUrl/api.php'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        setState(() {
          data = jsonData;
          _ventiladorEstado = data?['ventilador_estado'] ?? false;
          _velocidadVentilador = (data?['velocidad'] ?? 0).toDouble();
          _temperaturaDeseada = (data?['temperatura_deseada'] ?? 22).toDouble();
          _humedadDeseada = (data?['humedad_deseada'] ?? 50).toDouble();
          isLoading = false;
        });

        print('✅ Datos cargados desde servidor PHP');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }

    } catch (e) {
      print('❌ Error cargando datos: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error conectando al servidor: $e';
      });
    }
  }

  // Guardar datos en el servidor PHP
  Future<void> _guardarCambiosServidor() async {
    try {
      // Preparar datos para enviar
      final Map<String, dynamic> nuevosDatos = {
        'ventilador_estado': _ventiladorEstado,
        'velocidad': _velocidadVentilador,
        'temperatura_deseada': _temperaturaDeseada,
        'humedad_deseada': _humedadDeseada,
        'ultima_actualizacion': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$serverUrl/api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(nuevosDatos),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        setState(() {
          data = nuevosDatos;
        });

        print('💾 Datos guardados en servidor PHP: $nuevosDatos');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configuración guardada en servidor'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }

    } catch (e) {
      print('❌ Error guardando datos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error conectando al servidor'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }



  // Métodos de cambio (actualizados para usar servidor PHP)
  void _cambiarEstadoVentilador(bool nuevoEstado) {
    setState(() {
      _ventiladorEstado = nuevoEstado;
      if (!nuevoEstado) {
        _velocidadVentilador = 0;
      }
    });
    _guardarCambiosServidor();
  }

  void _cambiarVelocidad(double nuevaVelocidad) {
    setState(() {
      _velocidadVentilador = nuevaVelocidad;
      if (nuevaVelocidad > 0 && !_ventiladorEstado) {
        _ventiladorEstado = true;
      }
      if (nuevaVelocidad == 0 && _ventiladorEstado) {
        _ventiladorEstado = false;
      }
    });
    _guardarCambiosServidor();
  }

  void _cambiarTemperatura(double nuevaTemperatura) {
    setState(() {
      _temperaturaDeseada = nuevaTemperatura;
    });
    _guardarCambiosServidor();
  }

  void _cambiarHumedad(double nuevaHumedad) {
    setState(() {
      _humedadDeseada = nuevaHumedad;
    });
    _guardarCambiosServidor();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ambientes'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarDatosServidor,
            tooltip: 'Actualizar datos',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _guardarCambiosServidor,
            tooltip: 'Guardar en servidor',
          ),
        ],
      ),
      body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/fondop.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(color: Colors.black.withOpacity(0.6)),

            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Panel de Control server",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Servidor: $serverUrl',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      'Última actualización: ${data?['ultima_actualizacion'] != null ?
                      DateTime.parse(data!['ultima_actualizacion']).toString().substring(0, 16) :
                      '--'}',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 20),

                    if (isLoading)
                      Column(
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text('Cargando datos...', style: TextStyle(color: Colors.white)),
                        ],
                      ),

                    if (errorMessage.isNotEmpty)
                      Column(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 50),
                          SizedBox(height: 16),
                          Text(errorMessage, style: TextStyle(color: Colors.white)),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _cargarDatosServidor,
                            child: Text('Reintentar'),
                          ),
                        ],
                      ),

                    if (!isLoading && errorMessage.isEmpty)
                      Expanded(
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: [
                            // VENTILADOR - Switch
                            InfoBox(
                              title: 'Ventilador',
                              value: _ventiladorEstado ? 'ON' : 'OFF',
                              unit: '',
                              color: _ventiladorEstado ? Colors.greenAccent : Colors.redAccent,
                              height: 100,
                              width: 250,
                              child: Switch(
                                value: _ventiladorEstado,
                                onChanged: _cambiarEstadoVentilador,
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.red,
                              ),
                            ),

                            // VELOCIDAD - Regulador
                            InfoBox(
                              title: 'Velocidad',
                              value: _velocidadVentilador.toStringAsFixed(0),
                              unit: '%',
                              color: _ventiladorEstado ? Colors.blueAccent : Colors.grey,
                              height: 100,
                              width: 250,
                              child: ReguladorButton(
                                min: 0,
                                max: 100,
                                step: 10,
                                initialValue: _velocidadVentilador,
                                onChanged: _cambiarVelocidad,
                              ),
                            ),

                            // TEMPERATURA - Regulador
                            InfoBox(
                              title: 'Temperatura',
                              value: _temperaturaDeseada.toStringAsFixed(1),
                              unit: '°C',
                              color: Colors.orangeAccent,
                              height: 100,
                              width: 250,
                              child: ReguladorButton(
                                min: 16,
                                max: 30,
                                step: 0.5,
                                initialValue: _temperaturaDeseada,
                                onChanged: _cambiarTemperatura,
                              ),
                            ),

                            // HUMEDAD - Regulador
                            InfoBox(
                              title: 'Humedad',
                              value: _humedadDeseada.toStringAsFixed(0),
                              unit: '%',
                              color: Colors.greenAccent,
                              height: 100,
                              width: 250,
                              child: ReguladorButton(
                                min: 30,
                                max: 80,
                                step: 5,
                                initialValue: _humedadDeseada,
                                onChanged: _cambiarHumedad,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),
                    const Text(
                      'Sistema de monitoreo inteligente',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ]
      ),
    );
  }
}
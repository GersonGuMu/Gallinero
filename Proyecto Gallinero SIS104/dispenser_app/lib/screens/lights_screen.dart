import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LightsScreen extends StatefulWidget {
  @override
  _LightsScreen createState() => _LightsScreen();
}

class _LightsScreen extends State<LightsScreen> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  String errorMessage = '';

  bool _luz1Estado = false;

  final String _fOff = 'assets/images/foff.png';
  final String _fOn = 'assets/images/fonn.png';

  final String serverUrl = 'http://localhost/thermal_api/luces_api.php';

  @override
  void initState() {
    super.initState();
    _cargarDatosServidor();
  }

  Future<void> _cargarDatosServidor() async {
    try {
      setState(() => {isLoading = true, errorMessage = ''});

      final response = await http.get(
        Uri.parse(serverUrl),

      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData["error"] != null) {
          throw Exception(jsonData["error"]);
        }

        setState(() {
          //data = jsonData;
          _luz1Estado = jsonData['luces_estado'] == "1" || jsonData['luces_estado'] == 1;
          isLoading = false;
        });
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error conectando al servidor: $e';
      });
    }
  }

  Future<void> _guardarCambiosServidor() async {
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'luces_estado': _luz1Estado ? 1 : 0}),
      );

      final jsonData = json.decode(response.body);

      if (jsonData["success"] != true) {
        throw Exception("No se pudo guardar");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Luz actualizada en servidor'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando en el servidor'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cambiarEstadoLuz(bool value) {
    setState(() => _luz1Estado = value);
    _guardarCambiosServidor();
  }

  String _img(bool estado) => estado ? _fOn : _fOff;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Control de Luces'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarDatosServidor,
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
          Container(color: Colors.white.withOpacity(0.9)),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Text("Panel de Luz",
                      style: TextStyle(color: Colors.white, fontSize: 22)),

                  SizedBox(height: 10),

                  if (isLoading)
                    Column(children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 10),
                      Text("Cargando...", style: TextStyle(color: Colors.white)),
                    ]),

                  if (errorMessage.isNotEmpty)
                    Column(children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(height: 10),
                      Text(errorMessage, style: TextStyle(color: Colors.white)),
                    ]),

                  if (!isLoading && errorMessage.isEmpty)
                    Expanded(
                      child: Column(
                        children: [
                          // SWITCH DE LUZ 1
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.purple),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SwitchListTile(
                              title: Text("Luz Principal",
                                  style: TextStyle(color: Colors.white)),
                              value: _luz1Estado,
                              onChanged: _cambiarEstadoLuz,
                              activeColor: Colors.green,
                            ),
                          ),

                          SizedBox(height: 20),

                          // IMAGEN
                          SizedBox(
                            width: 220,
                            height: 380,
                            child: Image.asset(_img(_luz1Estado)),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 10),
                  Text("Sistema de monitoreo inteligente",
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

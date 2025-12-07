import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WaterListScreen extends StatefulWidget {
  @override
  State<WaterListScreen> createState() => _WaterListScreenState();
}

class _WaterListScreenState extends State<WaterListScreen> {
  double waterHeight = 0;
  final double maxWaterHeight = 400;

  bool isReloading = false;
  bool isLoading = true;
  String errorMessage = "";

  /// URL DE TU API
  final String serverUrl = "http://localhost/thermal_api/agua_api.php";

  @override
  void initState() {
    super.initState();
    _cargarNivelAgua();
  }

  // ============================
  //     CARGAR DE SERVIDOR
  // ============================
  Future<void> _cargarNivelAgua() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = "";
      });

      final response = await http.get(Uri.parse(serverUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData["error"] == null) {
          setState(() {
            waterHeight = (jsonData["nivel_agua"] ?? 0).toDouble();

            if (waterHeight > maxWaterHeight) {
              waterHeight = maxWaterHeight;
            }

            isLoading = false;
          });
        } else {
          throw Exception(jsonData["error"] ?? "Error desconocido");
        }
      } else {
        throw Exception("Error servidor: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error conectando al servidor: $e";
      });
    }
  }

  // ============================
  //     GUARDAR EN SERVIDOR
  // ============================
  Future<void> _guardarNivelAgua(double nivel) async {
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"nivel_agua": nivel}),
      );

      final jsonData = json.decode(response.body);

      if (jsonData["success"] != true) {
        throw Exception("No se pudo guardar");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error guardando en servidor"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===========================================
  //         FUNCIÓN RECARGAR AGUA
  // ===========================================
  void _recargarAgua() {
    if (isReloading) return;

    setState(() {
      isReloading = true;
      waterHeight = 0;
    });

    Timer.periodic(Duration(milliseconds: 15), (timer) {
      setState(() {
        if (waterHeight < maxWaterHeight) {
          waterHeight += 6;
        } else {
          waterHeight = maxWaterHeight;
          isReloading = false;
          timer.cancel();

          /// Guardar en BD
          _guardarNivelAgua(waterHeight);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double percentage = (waterHeight / maxWaterHeight) * 100;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Agua Chicken"),
        centerTitle: true,
        backgroundColor: Color(0xFF1F1F1F),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarNivelAgua,
          )
        ],
      ),
      body: SafeArea(
        child:Container(

          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            image: DecorationImage(
              image: AssetImage('images/fondop.jpg'),
              fit: BoxFit.cover,

            ),
          ),


          child: Center(
            child: Column(
              children: [
                SizedBox(height: 20),
                Text(
                  "NIVEL DE AGUA",
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 10),

                Text(
                  "Nivel actual: ${percentage.toStringAsFixed(1)}%",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),

                SizedBox(height: 20),

                if (isLoading)
                  Column(
                    children: [
                      CircularProgressIndicator(color: Colors.tealAccent),
                      SizedBox(height: 10),
                      Text("Cargando...", style: TextStyle(color: Colors.white)),
                    ],
                  ),

                if (errorMessage.isNotEmpty)
                  Column(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(height: 10),
                      Text(errorMessage, style: TextStyle(color: Colors.white)),
                    ],
                  ),

                if (!isLoading && errorMessage.isEmpty)
                  _vasoAgua(),

                SizedBox(height: 35),

                ElevatedButton(
                  onPressed: _recargarAgua,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    isReloading ? "RECARGANDO..." : "RECARGAR",
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// WIDGET DEL VASO CON NIVELES
  Widget _vasoAgua() {
    return Container(
      width: 320,
      height: 420,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          /// Vaso
          Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyanAccent, width: 6),
              borderRadius: BorderRadius.circular(55),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// Agua
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 280,
            height: waterHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withOpacity(0.7),
                  Colors.blueAccent.withOpacity(0.8),
                  Colors.blue.shade900.withOpacity(0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
          ),

          /// Brillo
          Positioned(
            top: 45,
            child: Container(
              width: 200,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          /// TEXTOS DE NIVELES
          Positioned(bottom: 300, child: _nivel("ALTO", Colors.greenAccent)),
          Positioned(bottom: 220, child: _nivel("MEDIO", Colors.lightBlueAccent)),
          Positioned(bottom: 140, child: _nivel("BAJO", Colors.orangeAccent)),
          Positioned(bottom: 60, child: _nivel("MÍNIMO", Colors.redAccent)),
        ],
      ),
    );
  }

  /// FUNCIÓN PARA TEXTO DE NIVELES
  Widget _nivel(String texto, Color color) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
        shadows: [
          Shadow(
            color: color.withOpacity(0.7),
            blurRadius: 12,
          )
        ],
      ),
    );
  }
}

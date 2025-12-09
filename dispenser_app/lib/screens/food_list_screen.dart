import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodListScreen extends StatefulWidget {
  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  final double vaseWidth = 180.0;
  final double vaseHeight = 320.0;

  bool isReloading = false;
  List<Grano> granos = [];
  List<double> columnasAltura = [];
  final int totalGranos = 600;
  Random random = Random();

  double foodLevel = 0.0; // de 0 a vaseHeight

  late Timer timer;

  final String apiBase = "http://localhost/thermal_api/comida_api.php"; // <-- CAMBIAR AQUÍ

  @override
  void initState() {
    super.initState();
    fetchFoodLevel(); // carga nivel inicial desde servidor
  }

  @override
  void dispose() {
    if (timer.isActive) timer.cancel();
    super.dispose();
  }

  // ----------------------------------------------------------
  //              API: obtener nivel desde servidor
  // ----------------------------------------------------------
  Future<void> fetchFoodLevel() async {
    try {
      final res = await http.get(Uri.parse(apiBase));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        double porcentaje = ((data["nivel_comida"] ?? 0.0).toDouble())/100;

        setState(() {
          foodLevel = porcentaje * vaseHeight;
        });
      }
    } catch (e) {
      print("ERROR FETCH FOOD: $e");
    }
  }

  // ----------------------------------------------------------
  //              API: enviar recarga al servidor
  // ----------------------------------------------------------
  Future<void> sendRefillRequest() async {
    try {
      await http.post(Uri.parse("$apiBase/api/refill-food"));
    } catch (e) {
      print("ERROR POST REFILL: $e");
    }
  }

  // ----------------------------------------------------------
  //                Animar recarga visual
  // ----------------------------------------------------------
  void _recargarComida() async {
    if (isReloading) return;

    // --- CONFIGURACIÓN DE DENSIDAD ---
    double anchoColumna = 2.5;     // Resolución horizontal (más bajo = más fino)
    int granosFisicos = 1000;       // Cantidad de granos
    double incrementoAltura = 0.4; // Cuánto sube la pila por cada grano
    // ---------------------------------

    setState(() {
      isReloading = true;
      granos.clear();
      foodLevel = 0.0;

      // CORRECCIÓN: Usamos 'anchoColumna' (5.0) en lugar de 15 fijos.
      // Esto crea un array más grande (aprox 34 columnas) para mayor precisión.
      int numColumnas = (vaseWidth / anchoColumna).ceil();
      columnasAltura = List.filled(numColumnas, 0.0);
    });

    await sendRefillRequest();

    timer = Timer.periodic(Duration(milliseconds: 15), (t) {
      setState(() {
        if (foodLevel < vaseHeight) {
          foodLevel += 2.0;
          if (foodLevel > vaseHeight) foodLevel = vaseHeight;

          // 1. Generar nuevos granos
          int target = (foodLevel / vaseHeight * granosFisicos).toInt();
          while (granos.length < target) {
            double x = random.nextDouble() * (vaseWidth - 30.0);
            granos.add(Grano(
              x: x,
              y: vaseHeight,
              velocidad: random.nextDouble() * 10 + 10, // Velocidad rápida
            ));
          }

          // 2. Mover granos
          for (var grano in granos) {
            // Si ya aterrizó, lo ignoramos (se queda estático donde cayó)
            if (grano.aterrizado) continue;

            // Caída
            grano.y -= grano.velocidad;

            // CORRECCIÓN: Calcular índice usando 'anchoColumna' (5.0), no 15.
            int columnaIndex = (grano.x / anchoColumna).floor();

            // Protección contra índices fuera de rango
            if (columnaIndex >= columnasAltura.length) columnaIndex = columnasAltura.length - 1;
            if (columnaIndex < 0) columnaIndex = 0;

            // Calcular el piso
            double alturaColumna = columnasAltura[columnaIndex];
            double piso = max(foodLevel, alturaColumna);

            // DETECCIÓN DE ATERRIZAJE
            if (grano.y <= piso) {
              grano.y = piso;
              grano.aterrizado = true;

              // Actualizar altura de la columna actual
              columnasAltura[columnaIndex] = piso + incrementoAltura;

              // SUAVIZADO DE VECINOS (Smoothing)
              // Evita "agujas" solitarias subiendo un poco las columnas de los lados.
              // Usamos 'incrementoAltura * 0.5' para hacer una pendiente suave.
              if (columnaIndex > 0) {
                columnasAltura[columnaIndex - 1] = max(
                    columnasAltura[columnaIndex - 1],
                    piso + (incrementoAltura * 0.5)
                );
              }
              if (columnaIndex < columnasAltura.length - 1) {
                columnasAltura[columnaIndex + 1] = max(
                    columnasAltura[columnaIndex + 1],
                    piso + (incrementoAltura * 0.5)
                );
              }
            }
          }

        } else {
          // Finalizar animación
          foodLevel = vaseHeight;
          isReloading = false;
          t.cancel();
          fetchFoodLevel();
        }
      });
    });
  }

  // Helper para obtener altura guardada (aunque ya la usamos directo en el loop)
  double _getAlturaPila(double x) {
    int index = (x / 15).floor();
    if (index >= columnasAltura.length) index = columnasAltura.length - 1;
    if (index < 0) index = 0;
    return columnasAltura[index];
  }

  // ----------------------------------------------------------
  //                        UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Comida de Gallinas"),
        backgroundColor: Colors.orangeAccent,
        centerTitle: true,
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
          child:Container(color: Colors.black.withOpacity(0.6),
            child: Center(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Text(
                    "NIVEL DE COMIDA",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Contenedor principal
                  Container(
                    width: 200,
                    height: 350,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // fondo del vaso
                        Container(
                          width: 180,
                          height: vaseHeight,
                          decoration: BoxDecoration(
                            //color: Colors.purple[200],
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.purple, width: 3),
                          ),
                        ),

                        // Comida base
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 180,
                            height: foodLevel,
                            child: Image.asset(
                              'assets/images/granos.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // granos animados
                        // granos animados
                        /*ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: vaseWidth,
                            height: vaseHeight,
                            child: Stack(
                              children: [
                                // Cambiamos .map((g)) para usar el objeto Grano
                                ...granos.map((g) {
                                  return Positioned(
                                    left: g.x,
                                    bottom: g.y, // Usamos la propiedad y del objeto
                                    child: SizedBox(
                                      width: 30, // Tamaño visual del grano
                                      height: 30,
                                      child: Image.asset('assets/images/grano.png'),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),*/
                      ],
                    ),
                  ),

                  SizedBox(height: 18),

                  Text(
                    "Nivel: ${(100*foodLevel / vaseHeight ).toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 25),

                  ElevatedButton(
                    onPressed: _recargarComida,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      isReloading ? "RECARGANDO..." : "RECARGAR",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class Grano {
  double x;
  double y; // Posición 'bottom'
  double velocidad;
  bool aterrizado;

  Grano({
    required this.x,
    required this.y,
    required this.velocidad,
    this.aterrizado = false
  });
}
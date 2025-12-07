import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DetectionsScreen extends StatefulWidget {
  @override
  _DetectionsScreenState createState() => _DetectionsScreenState();
}

class _DetectionsScreenState extends State<DetectionsScreen> {
  // CONFIGURACIÓN: Cambia esto por la IP y rutas reales de tu servidor
  final String serverBaseUrl = "http://192.168.43.127";
  final String imagePath = "/thermal_api/captures/";
  // Esta URL debe ser un script (PHP/Node/Python) que devuelva el JSON de archivos
  final String apiListEndpoint = "http://192.168.43.127/thermal_api/listar_imagenes.php";

  late Future<List<String>> _imagesFuture;

  @override
  void initState() {
    super.initState();
    _imagesFuture = fetchSavedImages();
  }

  // Función para obtener la lista desde el servidor
  Future<List<String>> fetchSavedImages() async {
    try {
      final response = await http.get(Uri.parse(apiListEndpoint));

      if (response.statusCode == 200) {
        // Asumimos que el servidor devuelve un JSON así: ["foto1.jpg", "foto2.jpg"]
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.cast<String>();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al conectar: $e');
    }
  }

  // Función para recargar (pull-to-refresh)
  Future<void> _refreshDetections() async {
    setState(() {
      _imagesFuture = fetchSavedImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detecciones en Servidor')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: FutureBuilder<List<String>>(
          future: _imagesFuture,
          builder: (context, snapshot) {
            // 1. Estado de Carga
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            // 2. Estado de Error
            else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 40),
                    SizedBox(height: 10),
                    Text("Error al cargar imágenes:\n${snapshot.error}", textAlign: TextAlign.center),
                    ElevatedButton(onPressed: _refreshDetections, child: Text("Reintentar"))
                  ],
                ),
              );
            }
            // 3. Estado Sin Datos
            else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text("No se encontraron detecciones."));
            }

            // 4. Estado Exitoso (Mostrar Grid)
            final savedImages = snapshot.data!;

            return RefreshIndicator(
              onRefresh: _refreshDetections,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8, // Ajustado para que quepa el texto abajo
                ),
                itemCount: savedImages.length,
                itemBuilder: (context, i) {
                  // Construir la URL completa de la imagen
                  String imageUrl = "$serverBaseUrl$imagePath${savedImages[i]}";
                  // --- IMPRIMIR EN CONSOLA PARA VERIFICAR ---
                  print("BUSCANDO IMAGEN EN: $imageUrl");


                  return Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            // Manejo de errores de carga de imagen individual
                            /*errorBuilder: (context, error, stackTrace) {
                              return Center(child: Icon(Icons.broken_image, color: Colors.grey));
                            },*/
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(child: CircularProgressIndicator(strokeWidth: 2));
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            savedImages[i], // Muestra el nombre real del archivo
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
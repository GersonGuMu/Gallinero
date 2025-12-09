import 'package:flutter/material.dart';
//import 'package:badges/badges.dart' as badges;
import 'home_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        elevation: 4,
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text(
          'Inicio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/messages'),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF202020),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF303030)),
              accountName: Text("Usuario"),
              accountEmail: Text("usuario@correo.com"),
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage('assets/user.jpg'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.white70),
              title: const Text('Estadísticas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/stats');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.white70),
              title: const Text('Cámaras'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/cameras');
              },
            ),
            ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.white70),
              title: const Text('Detecciones'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/detections');
              },
            ),
          ],
        ),
      ),
      body: Stack(
          children: [
      // 🔹 Imagen de fondo
            Container(
            decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('images/fondop.jpg'), // tu imagen local
              fit: BoxFit.cover, // cubre toda la pantalla
            ),
            ),
            ),

          // 🔹 Capa negra semitransparente (opacidad 60%)
            Container(
            color: Colors.black.withOpacity(0.6),
            ),
        Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Panel principal",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    HomeButton(
                      label: 'Agua',
                      icon: Icons.opacity,
                      color: Colors.blueAccent,
                      size: 100,
                      onTap: () => Navigator.pushNamed(context, '/water'),
                    ),
                    HomeButton(
                      label: 'Comida',
                      icon: Icons.food_bank,
                      color: Colors.orangeAccent,
                      size: 100,
                      onTap: () => Navigator.pushNamed(context, '/food'),
                    ),
                    HomeButton(
                      label: 'Cámara',
                      icon: Icons.videocam,
                      color: Colors.greenAccent,
                      size: 100,
                      onTap: () => Navigator.pushNamed(context, '/cameras'),
                    ),
                    HomeButton(
                      label: 'Temperatura',
                      icon: Icons.thermostat,
                      color: Colors.redAccent,
                      size: 100,
                      onTap: () => Navigator.pushNamed(context, '/thermal2'),
                    ),
                    /*HomeButton(
                      label: 'Ventilador',
                      icon: Icons.air,
                      color: Colors.orangeAccent,
                      size: 100,
                      onTap: () => Navigator.pushNamed(context, '/thermal2'),
                    ),*/
                    HomeButton(
                      label: 'Luces',
                      icon: Icons.light,
                      color: Colors.deepPurpleAccent,
                      size: 100,
                      onTap: () => Navigator.pushNamed(context, '/light'),
                    ),
                  ],
                ),
              ),
              const Text(
                'Sistema de monitoreo inteligente',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      ]
      ),
    );
  }
}


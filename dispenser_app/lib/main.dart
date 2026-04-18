import 'package:dispenser_app/screens/lights_screen.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/water_list_screen.dart';
import 'screens/food_list_screen.dart';
import 'screens/cameras_screen.dart';
import 'screens/detections_screen.dart';
import 'screens/detection_messages_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/thermal_screen.dart';
import 'screens/thermal2_screen.dart';

void main() {
  runApp(DispenserApp());
}

class DispenserApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GalliSmart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: const Color(0xFFFF8F00),
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF4E342E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF4E342E),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: Color(0xFF4E342E)),
        ),
        cardColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8F00),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/water': (context) => WaterListScreen(),
        '/food': (context) => FoodListScreen(),
        '/cameras': (context) => CamerasScreen(),
        '/detections': (context) => DetectionsScreen(),
        '/messages': (context) => DetectionMessagesScreen(),
        '/stats': (context) => StatsScreen(),
        '/thermal': (context) => ThermalScreen(),
        '/thermal2': (context) => Thermal2Screen(),
        '/light': (context) => LightsScreen(),
      },
    );
  }
}

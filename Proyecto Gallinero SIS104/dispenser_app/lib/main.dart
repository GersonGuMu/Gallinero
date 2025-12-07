
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
      title: 'Dispenser App',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.tealAccent,
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
        ),
        colorScheme: ColorScheme.dark(),
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

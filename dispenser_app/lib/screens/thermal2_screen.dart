import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Thermal2Screen extends StatefulWidget {
  @override
  _Thermal2Screen createState() => _Thermal2Screen();
}

class _Thermal2Screen extends State<Thermal2Screen> with TickerProviderStateMixin {
  final String serverUrl = "http://localhost/thermal_api/api.php";

  double _temperature = 0.0;
  double _humidity = 0.0;
  bool _fanOn = false;
  bool isLoading = true;
  String errorMessage = "";

  late AnimationController _fanCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fanCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() { isLoading = true; });
      final response = await http.get(Uri.parse(serverUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _temperature = (data['temperatura'] ?? 0).toDouble();
          _humidity = (data['humedad'] ?? 0).toDouble();
          _fanOn = data['ventilador_estado'] ?? false;
          isLoading = false;
        });
        if (_fanOn) _fanCtrl.repeat();
        _fadeCtrl.forward(from: 0);
      } else {
        throw Exception("Error código: ${response.statusCode}");
      }
    } catch (e) {
      setState(() { isLoading = false; errorMessage = "Error al conectar con el servidor: $e"; });
    }
  }

  Future<void> _saveData() async {
    try {
      await http.post(Uri.parse(serverUrl),
          headers: {"Content-Type": "application/json"},
          body: json.encode({"ventilador_estado": _fanOn}));
    } catch (e) {
      print("Error guardando datos: $e");
    }
  }

  void _toggleFan() {
    setState(() { _fanOn = !_fanOn; });
    if (_fanOn) _fanCtrl.repeat(); else { _fanCtrl.stop(); _fanCtrl.reset(); }
    _saveData();
  }

  Color get _tempColor {
    if (_temperature > 35) return const Color(0xFFD32F2F);
    if (_temperature > 28) return const Color(0xFFF57C00);
    if (_temperature > 20) return const Color(0xFF2E7D32);
    return const Color(0xFF0288D1);
  }

  String get _tempStatus {
    if (_temperature > 35) return 'MUY CALIENTE 🔥';
    if (_temperature > 28) return 'CALIENTE';
    if (_temperature > 20) return 'ÓPTIMO ✓';
    return 'FRÍO';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        title: const Text('Temperatura & Humedad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFD32F2F)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8F00))))
          : errorMessage.isNotEmpty
              ? _buildError()
              : FadeTransition(opacity: _fadeAnim, child: _buildMainUI()),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 56),
        const SizedBox(height: 12),
        Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8F00), foregroundColor: Colors.white),
        ),
      ],
    ),
  );

  Widget _buildMainUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ---- TEMP HERO ----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_tempColor, _tempColor.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: _tempColor.withOpacity(0.45), blurRadius: 22, offset: const Offset(0, 10))],
            ),
            child: Row(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.thermostat_rounded, color: Colors.white, size: 38),
                ),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_temperature.toStringAsFixed(1)} °C',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    Text(_tempStatus, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ---- GAUGES ----
          Row(
            children: [
              Expanded(child: _buildGaugeCard(
                title: "Temperatura",
                currentValue: _temperature,
                unit: "°C",
                color: _tempColor,
                maxValue: 50,
                icon: Icons.thermostat_rounded,
              )),
              const SizedBox(width: 14),
              Expanded(child: _buildGaugeCard(
                title: "Humedad",
                currentValue: _humidity,
                unit: "%",
                color: const Color(0xFF0288D1),
                maxValue: 100,
                icon: Icons.water_drop_rounded,
              )),
            ],
          ),

          const SizedBox(height: 20),

          // ---- FAN CARD ----
          GestureDetector(
            onTap: _toggleFan,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _fanOn
                    ? const LinearGradient(
                        colors: [Color(0xFF0288D1), Color(0xFF0277BD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(colors: [Colors.white, Colors.white]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _fanOn ? Colors.transparent : Colors.grey.shade200,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _fanOn ? const Color(0xFF0288D1).withOpacity(0.4) : Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  RotationTransition(
                    turns: _fanCtrl,
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: _fanOn ? Colors.white.withOpacity(0.2) : const Color(0xFF0288D1).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.air_rounded,
                          color: _fanOn ? Colors.white : const Color(0xFF0288D1), size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ventilador',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17,
                                color: _fanOn ? Colors.white : const Color(0xFF4E342E))),
                        Text(_fanOn ? 'Funcionando — toca para apagar' : 'Apagado — toca para encender',
                            style: TextStyle(color: _fanOn ? Colors.white70 : Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _fanOn,
                    onChanged: (v) => _toggleFan(),
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white.withOpacity(0.3),
                    inactiveThumbColor: const Color(0xFF0288D1),
                    inactiveTrackColor: const Color(0xFF0288D1).withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeCard({
    required String title,
    required double currentValue,
    required String unit,
    required Color color,
    required double maxValue,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 5),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          SleekCircularSlider(
            min: 0,
            max: maxValue,
            initialValue: currentValue,
            appearance: CircularSliderAppearance(
              size: 120,
              startAngle: 180,
              angleRange: 180,
              customWidths: CustomSliderWidths(trackWidth: 10, progressBarWidth: 10),
              customColors: CustomSliderColors(
                trackColor: Colors.grey.shade100,
                progressBarColor: color,
                dotColor: color,
                shadowColor: color,
                shadowMaxOpacity: 0.3,
              ),
            ),
            innerWidget: (value) => Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value.toStringAsFixed(0),
                        style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.w900)),
                    Text(unit, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

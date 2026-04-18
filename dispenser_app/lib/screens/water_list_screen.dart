import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WaterListScreen extends StatefulWidget {
  @override
  State<WaterListScreen> createState() => _WaterListScreenState();
}

class _WaterListScreenState extends State<WaterListScreen> with TickerProviderStateMixin {
  double waterHeight = 0;
  final double maxWaterHeight = 400;
  bool isReloading = false;
  bool isLoading = true;
  String errorMessage = "";
  final String serverUrl = "http://localhost/thermal_api/agua_api.php";

  late AnimationController _waveCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargarNivelAgua();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarNivelAgua() async {
    try {
      setState(() { isLoading = true; errorMessage = ""; });
      final response = await http.get(Uri.parse(serverUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData["error"] == null) {
          setState(() {
            waterHeight = (jsonData["nivel_agua"] ?? 0).toDouble();
            if (waterHeight > maxWaterHeight) waterHeight = maxWaterHeight;
            isLoading = false;
          });
          _fadeCtrl.forward(from: 0);
        } else {
          throw Exception(jsonData["error"]);
        }
      } else {
        throw Exception("Error servidor: ${response.statusCode}");
      }
    } catch (e) {
      setState(() { isLoading = false; errorMessage = "Error conectando al servidor: $e"; });
    }
  }

  Future<void> _guardarNivelAgua(double nivel) async {
    try {
      final response = await http.post(Uri.parse(serverUrl),
          headers: {"Content-Type": "application/json"},
          body: json.encode({"nivel_agua": nivel}));
      final jsonData = json.decode(response.body);
      if (jsonData["success"] != true) throw Exception("No se pudo guardar");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Error guardando en servidor"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _recargarAgua() {
    if (isReloading) return;
    setState(() { isReloading = true; waterHeight = 0; });
    Timer.periodic(const Duration(milliseconds: 15), (timer) {
      setState(() {
        if (waterHeight < maxWaterHeight) {
          waterHeight += 6;
        } else {
          waterHeight = maxWaterHeight;
          isReloading = false;
          timer.cancel();
          _guardarNivelAgua(waterHeight);
        }
      });
    });
  }

  double get _pct => waterHeight / maxWaterHeight;

  Color get _levelColor {
    if (_pct > 0.75) return const Color(0xFF0288D1);
    if (_pct > 0.5) return const Color(0xFF039BE5);
    if (_pct > 0.25) return const Color(0xFFF57C00);
    return const Color(0xFFD32F2F);
  }

  String get _levelLabel {
    if (_pct > 0.75) return 'ALTO';
    if (_pct > 0.5) return 'MEDIO';
    if (_pct > 0.25) return 'BAJO';
    return 'CRÍTICO';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        title: const Text('Nivel de Agua'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0288D1)),
            onPressed: _cargarNivelAgua,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF0288D1))))
          : errorMessage.isNotEmpty
              ? _buildError()
              : FadeTransition(opacity: _fadeAnim, child: _buildBody()),
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
          onPressed: _cargarNivelAgua,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1), foregroundColor: Colors.white),
        ),
      ],
    ),
  );

  Widget _buildBody() {
    final pct = _pct * 100;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ---- STATUS CARD ----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_levelColor, _levelColor.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: _levelColor.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pct.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                    Text('Estado: $_levelLabel',
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ---- TANK ----
          Center(child: _buildTank()),

          const SizedBox(height: 32),

          // ---- BUTTON ----
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: isReloading ? null : _recargarAgua,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 6,
                shadowColor: const Color(0xFF0288D1).withOpacity(0.4),
              ),
              icon: isReloading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.water, color: Colors.white, size: 24),
              label: Text(
                isReloading ? 'RECARGANDO...' : 'RECARGAR AGUA',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTank() {
    return SizedBox(
      width: 220,
      height: 380,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Fondo tanque
          Container(
            width: 200,
            height: 360,
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: const Color(0xFF0288D1).withOpacity(0.6), width: 3),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0288D1).withOpacity(0.15), blurRadius: 20, spreadRadius: 4),
              ],
            ),
          ),

          // Agua animada
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 180,
            height: (_pct * 340).clamp(0.0, 340.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF80D8FF), Color(0xFF0288D1), Color(0xFF01579B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(35),
            ),
          ),

          // Onda animada encima del agua
          if (_pct > 0.05)
            AnimatedBuilder(
              animation: _waveCtrl,
              builder: (ctx, _) {
                return Positioned(
                  bottom: (_pct * 340).clamp(0.0, 340.0) - 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 180,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3 + _waveCtrl.value * 0.2),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // Brillo
          Positioned(
            top: 40, left: 30,
            child: Container(
              width: 40, height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.4), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Marcadores
          _levelMark(270, 'ALTO', const Color(0xFF2E7D32)),
          _levelMark(190, 'MEDIO', const Color(0xFF0288D1)),
          _levelMark(110, 'BAJO', const Color(0xFFF57C00)),
          _levelMark(30, 'MÍNIMO', const Color(0xFFD32F2F)),
        ],
      ),
    );
  }

  Widget _levelMark(double bottom, String label, Color color) {
    return Positioned(
      bottom: bottom,
      right: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 18, height: 1.5, color: color.withOpacity(0.5)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

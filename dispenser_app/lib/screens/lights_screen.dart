import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LightsScreen extends StatefulWidget {
  @override
  _LightsScreen createState() => _LightsScreen();
}

class _LightsScreen extends State<LightsScreen> with TickerProviderStateMixin {
  bool _luz1Estado = false;
  bool isLoading = true;
  String errorMessage = '';

  final String _fOff = 'assets/images/foff.png';
  final String _fOn = 'assets/images/fonn.png';
  final String serverUrl = 'http://localhost/thermal_api/luces_api.php';

  late AnimationController _glowCtrl;
  late AnimationController _switchCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _switchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
    _cargarDatosServidor();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _switchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosServidor() async {
    try {
      setState(() { isLoading = true; errorMessage = ''; });
      final response = await http.get(Uri.parse(serverUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData["error"] != null) throw Exception(jsonData["error"]);
        setState(() {
          _luz1Estado = jsonData['luces_estado'] == "1" || jsonData['luces_estado'] == 1;
          isLoading = false;
        });
        if (_luz1Estado) _switchCtrl.forward();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      setState(() { isLoading = false; errorMessage = 'Error conectando: $e'; });
    }
  }

  Future<void> _guardarCambiosServidor() async {
    try {
      final response = await http.post(Uri.parse(serverUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'luces_estado': _luz1Estado ? 1 : 0}));
      final jsonData = json.decode(response.body);
      if (jsonData["success"] != true) throw Exception("No se pudo guardar");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_luz1Estado ? '💡 Luz encendida' : '🌙 Luz apagada'),
        backgroundColor: _luz1Estado ? const Color(0xFFFFB300) : const Color(0xFF546E7A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error guardando en el servidor'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _cambiarEstadoLuz(bool value) {
    setState(() => _luz1Estado = value);
    if (value) _switchCtrl.forward(); else _switchCtrl.reverse();
    _guardarCambiosServidor();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      color: _luz1Estado ? const Color(0xFFFFFDE7) : const Color(0xFF263238),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: _luz1Estado ? const Color(0xFF4E342E) : Colors.white),
          title: Text(
            'Control de Luces',
            style: TextStyle(color: _luz1Estado ? const Color(0xFF4E342E) : Colors.white, fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: _luz1Estado ? const Color(0xFFFBC02D) : Colors.white70),
              onPressed: _cargarDatosServidor,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFBC02D))))
            : errorMessage.isNotEmpty
                ? _buildError()
                : _buildBody(),
      ),
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
        ElevatedButton(onPressed: _cargarDatosServidor, child: const Text('Reintentar')),
      ],
    ),
  );

  Widget _buildBody() {
    final textColor = _luz1Estado ? const Color(0xFF4E342E) : Colors.white;
    final subColor = _luz1Estado ? const Color(0xFF8D6E63) : Colors.white60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ---- STATUS BANNER ----
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _luz1Estado
                    ? [const Color(0xFFFFB300), const Color(0xFFFF8F00)]
                    : [const Color(0xFF37474F), const Color(0xFF263238)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: (_luz1Estado ? const Color(0xFFFFB300) : Colors.black).withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (context, child) {
                    return Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        boxShadow: _luz1Estado ? [
                          BoxShadow(
                            color: const Color(0xFFFFCC02).withOpacity(0.4 + _glowAnim.value * 0.4),
                            blurRadius: 20 + _glowAnim.value * 20,
                            spreadRadius: 4,
                          ),
                        ] : [],
                      ),
                      child: Icon(
                        _luz1Estado ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        color: Colors.white,
                        size: 38,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _luz1Estado ? 'ENCENDIDA' : 'APAGADA',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _luz1Estado ? 'El gallinero está iluminado' : 'Modo nocturno activo',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ---- SWITCH CARD ----
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: _luz1Estado ? Colors.white : const Color(0xFF37474F),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_luz1Estado ? 0.08 : 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBC02D).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFFBC02D), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Luz Principal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: textColor)),
                      Text('Toca para encender o apagar', style: TextStyle(color: subColor, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: _luz1Estado,
                  onChanged: _cambiarEstadoLuz,
                  activeColor: const Color(0xFFFBC02D),
                  activeTrackColor: const Color(0xFFFFE082),
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade700,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ---- LAMP IMAGE ----
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _luz1Estado ? [
                    BoxShadow(
                      color: const Color(0xFFFFCC02).withOpacity(0.3 + _glowAnim.value * 0.35),
                      blurRadius: 60 + _glowAnim.value * 40,
                      spreadRadius: 10,
                    ),
                  ] : [],
                ),
                child: child,
              );
            },
            child: SizedBox(
              width: 240,
              height: 320,
              child: Image.asset(_luz1Estado ? _fOn : _fOff),
            ),
          ),
        ],
      ),
    );
  }
}

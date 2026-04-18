import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? data;
  String? endpoint;
  bool isLoading = true;
  String errorMessage = '';
  String? tipo;

  late AnimationController _animCtrl;
  late Animation<double> _anim;

  final String serverUrl = 'http://localhost/thermal_api';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args != null && endpoint == null) {
      endpoint = args as String;
      _detectarTipo();
      _cargarDatosServidor();
    }
  }

  void _detectarTipo() {
    if (endpoint!.startsWith('vaso')) tipo = 'agua';
    else if (endpoint!.startsWith('comida')) tipo = 'comida';
    else tipo = 'general';
  }

  String _getApiUrl() {
    if (tipo == 'agua') return '$serverUrl/agua_api.php?vaso=$endpoint';
    return '$serverUrl/comida_api.php?plato=$endpoint';
  }

  Future<void> _cargarDatosServidor() async {
    try {
      setState(() { isLoading = true; errorMessage = ''; });
      final response = await http.get(Uri.parse(_getApiUrl()), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        setState(() { data = json.decode(response.body); isLoading = false; });
        _animCtrl.forward(from: 0);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error cargando datos: $e';
        data = tipo == 'agua' ? {"vacio": 30, "agua": 70} : {"vacio": 10, "comida": 90};
      });
      _animCtrl.forward(from: 0);
    }
  }

  Color get _primaryColor {
    switch (tipo) {
      case 'agua': return const Color(0xFF0288D1);
      case 'comida': return const Color(0xFFFF8F00);
      default: return const Color(0xFF2E7D32);
    }
  }

  String get _titulo {
    switch (tipo) {
      case 'agua': return 'Nivel de Agua';
      case 'comida': return 'Nivel de Comida';
      default: return 'Estadísticas';
    }
  }

  IconData get _icon {
    switch (tipo) {
      case 'agua': return Icons.water_drop_rounded;
      case 'comida': return Icons.grain;
      default: return Icons.bar_chart_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8E1),
        appBar: AppBar(backgroundColor: Colors.white, title: Text(_titulo)),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFFF8F00))),
      );
    }

    final total = data!.values.fold<double>(0, (sum, val) => sum + (val is num ? val.toDouble() : 0));
    final sections = data!.entries.map((entry) {
      final value = entry.value is num ? entry.value.toDouble() : 0.0;
      final percentage = total > 0 ? (value / total) * 100 : 0;
      return PieChartSectionData(
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: _getColor(entry.key),
        radius: 80,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
      );
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_titulo),
      ),
      body: FadeTransition(
        opacity: _anim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Mostrando datos de ejemplo', style: TextStyle(color: Colors.orange.shade700, fontSize: 13))),
                    ],
                  ),
                ),

              // Chart card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: _primaryColor.withOpacity(0.15), shape: BoxShape.circle),
                          child: Icon(_icon, color: _primaryColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(_titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF4E342E))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 50,
                          sectionsSpace: 4,
                          pieTouchData: PieTouchData(enabled: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Legend
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: data!.entries.map((entry) {
                        final value = entry.value is num ? entry.value.toDouble() : 0.0;
                        final pct = total > 0 ? (value / total) * 100 : 0;
                        return _legendItem(entry.key, _getColor(entry.key), '${pct.toStringAsFixed(1)}%');
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF4E342E))),
                    const SizedBox(height: 12),
                    ...data!.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: _getColor(entry.key), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Text('${entry.value}', style: TextStyle(color: _getColor(entry.key), fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.home_rounded, color: Colors.white),
                  label: const Text('Ir al Inicio', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label ($value)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Color _getColor(String key) {
    switch (key.toLowerCase()) {
      case 'vacio': return Colors.grey.shade400;
      case 'agua': return const Color(0xFF0288D1);
      case 'comida': return const Color(0xFFFF8F00);
      case 'proteina': return const Color(0xFFD32F2F);
      case 'carbohidratos': return const Color(0xFF2E7D32);
      default: return Colors.purpleAccent;
    }
  }
}

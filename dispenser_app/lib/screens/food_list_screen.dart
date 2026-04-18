import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodListScreen extends StatefulWidget {
  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen>
    with TickerProviderStateMixin {
  final double vaseWidth = 180.0;
  final double vaseHeight = 320.0;

  bool isReloading = false;
  List<Grano> granos = [];
  List<double> columnasAltura = [];
  Random random = Random();
  double foodLevel = 0.0;

  late Timer timer;
  late AnimationController _fadeCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _fadeAnim;

  final String apiBase = "http://localhost/thermal_api/comida_api.php";

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    fetchFoodLevel();
  }

  @override
  void dispose() {
    if (timer.isActive) timer.cancel();
    _fadeCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchFoodLevel() async {
    try {
      final res = await http.get(Uri.parse(apiBase));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        double pct = ((data["nivel_comida"] ?? 0.0).toDouble()) / 100;
        setState(() { foodLevel = pct * vaseHeight; });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) { print("ERROR FETCH FOOD: $e"); }
  }

  Future<void> sendRefillRequest() async {
    try { await http.post(Uri.parse("$apiBase/api/refill-food")); }
    catch (e) { print("ERROR POST REFILL: $e"); }
  }

  void _recargarComida() async {
    if (isReloading) return;
    double anchoColumna = 2.5;
    int granosFisicos = 1000;
    double incrementoAltura = 0.4;

    setState(() {
      isReloading = true;
      granos.clear();
      foodLevel = 0.0;
      int numColumnas = (vaseWidth / anchoColumna).ceil();
      columnasAltura = List.filled(numColumnas, 0.0);
    });

    await sendRefillRequest();

    timer = Timer.periodic(const Duration(milliseconds: 15), (t) {
      setState(() {
        if (foodLevel < vaseHeight) {
          foodLevel += 2.0;
          if (foodLevel > vaseHeight) foodLevel = vaseHeight;
          int target = (foodLevel / vaseHeight * granosFisicos).toInt();
          while (granos.length < target) {
            double x = random.nextDouble() * (vaseWidth - 30.0);
            granos.add(Grano(x: x, y: vaseHeight, velocidad: random.nextDouble() * 10 + 10));
          }
          for (var g in granos) {
            if (g.aterrizado) continue;
            g.y -= g.velocidad;
            int ci = (g.x / anchoColumna).floor().clamp(0, columnasAltura.length - 1);
            double piso = max(foodLevel, columnasAltura[ci]);
            if (g.y <= piso) {
              g.y = piso; g.aterrizado = true;
              columnasAltura[ci] = piso + incrementoAltura;
              if (ci > 0) columnasAltura[ci - 1] = max(columnasAltura[ci - 1], piso + incrementoAltura * 0.5);
              if (ci < columnasAltura.length - 1) columnasAltura[ci + 1] = max(columnasAltura[ci + 1], piso + incrementoAltura * 0.5);
            }
          }
        } else {
          foodLevel = vaseHeight; isReloading = false; t.cancel(); fetchFoodLevel();
        }
      });
    });
  }

  Color get _levelColor {
    final pct = foodLevel / vaseHeight;
    if (pct > 0.6) return const Color(0xFF2E7D32);
    if (pct > 0.35) return const Color(0xFFF57C00);
    return const Color(0xFFD32F2F);
  }

  String get _levelLabel {
    final pct = foodLevel / vaseHeight;
    if (pct > 0.6) return 'BUENO';
    if (pct > 0.35) return 'MODERADO';
    return 'BAJO';
  }

  @override
  Widget build(BuildContext context) {
    double pct = (foodLevel / vaseHeight) * 100;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Nivel de Comida', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF8F00)),
            onPressed: fetchFoodLevel,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ---- STATUS CARD ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_levelColor, _levelColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: _levelColor.withOpacity(0.5), blurRadius: 22, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.grain, color: Colors.white, size: 34),
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

              // ---- SILO CUSTOM PAINTED ----
              Center(child: _buildSilo()),

              const SizedBox(height: 32),

              // ---- BUTTON ----
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: isReloading ? null : _recargarComida,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8F00),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 8,
                    shadowColor: const Color(0xFFFF8F00).withOpacity(0.5),
                  ),
                  icon: isReloading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.restaurant, color: Colors.white, size: 24),
                  label: Text(
                    isReloading ? 'RECARGANDO...' : 'RECARGAR COMIDA',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSilo() {
    return SizedBox(
      width: 240,
      height: vaseHeight + 60,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Fondo oscuro del silo
          Container(
            width: 200,
            height: vaseHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFF8F00).withOpacity(0.6), width: 2.5),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFF8F00).withOpacity(0.25), blurRadius: 24, spreadRadius: 2),
              ],
            ),
          ),

          // Fill con CustomPainter de granos
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              width: 195,
              height: vaseHeight,
              child: AnimatedBuilder(
                animation: _shimmerCtrl,
                builder: (context, _) {
                  return CustomPaint(
                    painter: GrainPainter(
                      fillRatio: foodLevel / vaseHeight,
                      shimmer: _shimmerCtrl.value,
                      levelColor: _levelColor,
                    ),
                    size: Size(195, vaseHeight),
                  );
                },
              ),
            ),
          ),

          // Marcadores de nivel
          _siloMark(vaseHeight * 0.75, '75%', const Color(0xFF69F0AE)),
          _siloMark(vaseHeight * 0.50, '50%', const Color(0xFFFFD54F)),
          _siloMark(vaseHeight * 0.25, '25%', const Color(0xFFFF7043)),

          // Tapa del silo (embudo superior)
          Positioned(
            top: 0,
            child: Container(
              width: 220,
              height: 36,
              child: CustomPaint(painter: SiloCapPainter()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _siloMark(double bottom, String text, Color color) {
    return Positioned(
      bottom: bottom,
      right: 6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, height: 1.5, color: color.withOpacity(0.7)),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// =============================================
//   CUSTOM PAINTER: Granos dibujados a mano
// =============================================
class GrainPainter extends CustomPainter {
  final double fillRatio;
  final double shimmer;
  final Color levelColor;
  final Random _rng = Random(42); // seed fijo para posiciones consistentes

  GrainPainter({required this.fillRatio, required this.shimmer, required this.levelColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (fillRatio <= 0) return;

    final fillHeight = size.height * fillRatio;
    final top = size.height - fillHeight;

    // Fondo degradado del relleno
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          levelColor.withOpacity(0.9),
          levelColor.withOpacity(0.6),
          const Color(0xFF3E2000).withOpacity(0.9),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, top, size.width, fillHeight));

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, top, size.width, fillHeight),
      const Radius.circular(0),
    );
    canvas.drawRRect(rrect, bgPaint);

    // Granos individuales dibujados
    final rng = Random(42);
    final grainCount = (fillRatio * 320).toInt();

    for (int i = 0; i < grainCount; i++) {
      final x = rng.nextDouble() * size.width;
      final yRel = rng.nextDouble() * fillHeight;
      final y = top + yRel;
      final radius = 2.5 + rng.nextDouble() * 2.5;
      final angle = rng.nextDouble() * pi;

      // Color del grano: mezcla cálida
      final shade = 0.5 + rng.nextDouble() * 0.5;
      final grainColor = Color.lerp(
        const Color(0xFFFFCC02),
        const Color(0xFFBF6A00),
        rng.nextDouble(),
      )!.withOpacity(0.75 + shimmer * 0.25);

      final paint = Paint()..color = grainColor;

      // Dibujar elipse (grano ovalado)
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius), paint);
      canvas.restore();
    }

    // Brillo encima del relleno
    final glossPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.15 + shimmer * 0.10),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, top, size.width, fillHeight * 0.4));

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, top, size.width, fillHeight * 0.4), const Radius.circular(0)),
      glossPaint,
    );

    // Línea de superficie ondulada
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.3 + shimmer * 0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final wavePath = Path();
    wavePath.moveTo(0, top);
    for (double dx = 0; dx <= size.width; dx += 8) {
      final dy = sin((dx / size.width * 2 * pi) + shimmer * pi) * 3;
      wavePath.lineTo(dx, top + dy);
    }
    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(GrainPainter old) =>
      old.fillRatio != fillRatio || old.shimmer != shimmer;
}

// Embudo superior del silo
class SiloCapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F3460), Color(0xFF16213E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFFF8F00).withOpacity(0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.1, 0);
    path.lineTo(size.width * 0.9, 0);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Grano {
  double x, y, velocidad;
  bool aterrizado;
  Grano({required this.x, required this.y, required this.velocidad, this.aterrizado = false});
}

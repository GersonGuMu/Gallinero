import 'package:flutter/material.dart';
import 'home_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _gridCtrl;
  late Animation<Offset> _headerSlide;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _gridCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () => _gridCtrl.forward());
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _gridCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFFFB300)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFFFF8F00).withOpacity(0.4), blurRadius: 8)],
              ),
              child: const Icon(Icons.egg_alt, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('GalliSmart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.notifications_outlined, color: Color(0xFFFF8F00), size: 20),
              ),
              onPressed: () => Navigator.pushNamed(context, '/messages'),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========= HERO BANNER =========
            SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerFade,
                child: _buildHero(),
              ),
            ),
            const SizedBox(height: 24),

            // ========= QUICK STATS =========
            FadeTransition(
              opacity: _headerFade,
              child: _buildQuickStats(),
            ),

            const SizedBox(height: 28),

            // ========= TITLE =========
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Controles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),

            // ========= GRID =========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  _staggerButton(0, HomeButton(label: 'Agua', icon: Icons.water_drop_rounded, color: const Color(0xFF0288D1), size: 110, onTap: () => Navigator.pushNamed(context, '/water'))),
                  _staggerButton(1, HomeButton(label: 'Comida', icon: Icons.grain, color: const Color(0xFFFF8F00), size: 110, onTap: () => Navigator.pushNamed(context, '/food'))),
                  _staggerButton(2, HomeButton(label: 'Cámara', icon: Icons.videocam_rounded, color: const Color(0xFF2E7D32), size: 110, onTap: () => Navigator.pushNamed(context, '/cameras'))),
                  _staggerButton(3, HomeButton(label: 'Temperatura', icon: Icons.thermostat_rounded, color: const Color(0xFFD32F2F), size: 110, onTap: () => Navigator.pushNamed(context, '/thermal2'))),
                  _staggerButton(4, HomeButton(label: 'Luces', icon: Icons.wb_sunny_rounded, color: const Color(0xFFFBC02D), size: 110, onTap: () => Navigator.pushNamed(context, '/light'))),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                'Sistema de monitoreo inteligente',
                style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _staggerButton(int i, Widget child) {
    return AnimatedBuilder(
      animation: _gridCtrl,
      builder: (context, _) {
        final delay = i * 0.12;
        final progress = ((_gridCtrl.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutBack.transform(progress);
        return Transform.scale(
          scale: curve,
          child: Opacity(opacity: progress.clamp(0.0, 1.0), child: child),
        );
      },
    );
  }

  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFFB300), Color(0xFFFFCC02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF8F00).withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          // Círculo decorativo fondo
          Positioned(
            right: -30, top: -30,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            right: 30, bottom: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bienvenido',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gallinero\nInteligente',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('Sistema activo', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Ícono grande
          Positioned(
            right: 20, top: 0, bottom: 0,
            child: Center(
              child: Icon(Icons.egg_alt, size: 90, color: Colors.white.withOpacity(0.25)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _statChip(Icons.water_drop_rounded, 'Agua', 'Normal', const Color(0xFF0288D1)),
          _statChip(Icons.grain, 'Comida', 'Normal', const Color(0xFFFF8F00)),
          _statChip(Icons.thermostat_rounded, 'Temp', 'Óptima', const Color(0xFFD32F2F)),
          _statChip(Icons.wb_sunny_rounded, 'Luz', 'ON', const Color(0xFFFBC02D)),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String status, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w500)),
              Text(status, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF8F00), Color(0xFFFFCC02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                const Text('Administrador', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const Text('admin@gallinero.com', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _drawerTile(Icons.bar_chart_rounded, 'Estadísticas', () { Navigator.pop(context); Navigator.pushNamed(context, '/stats'); }),
                _drawerTile(Icons.videocam_rounded, 'Cámaras', () { Navigator.pop(context); Navigator.pushNamed(context, '/cameras'); }),
                _drawerTile(Icons.pest_control, 'Detecciones', () { Navigator.pop(context); Navigator.pushNamed(context, '/detections'); }),
                const Divider(height: 24, indent: 20, endIndent: 20),
                _drawerTile(Icons.info_outline, 'Acerca de', () => Navigator.pop(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFF8F00).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFFFF8F00), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4E342E), fontSize: 15)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}

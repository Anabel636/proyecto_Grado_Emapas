import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/tutorial_service.dart';
import '../models/reporte_model.dart';
import '../widgets/mapa_widget.dart';
import 'reporte_screen.dart';
import 'historial_screen.dart';
import 'perfil_screen.dart';
import 'login_screen.dart';

// ═══════════════════════════════════════════════
//  HomeScreen — StatefulWidget
// ═══════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ═══════════════════════════════════════════════
//  _HomeScreenState — UNA SOLA clase con todo
// ═══════════════════════════════════════════════

class _HomeScreenState extends State<HomeScreen> {

  // ── Navegación ──
  int _currentIndex = 0;
  late final List<Widget> _screens;

  // ── Servicios ──
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TutorialService _tutorialService = TutorialService();

  // ── GlobalKeys para el tutorial ──
  // Cada key identifica un widget en la pantalla
  // para que el tutorial sepa dónde apuntar
  final GlobalKey _keyMapa      = GlobalKey();
  final GlobalKey _keyReportar  = GlobalKey();
  final GlobalKey _keyHistorial = GlobalKey();
  final GlobalKey _keyPerfil    = GlobalKey();
  final GlobalKey _keyFab       = GlobalKey();

  late TutorialCoachMark _tutorialCoachMark;

  // ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Inicializar pantallas
    _screens = [
      const _MapaTab(),
      const ReporteScreen(),
      const HistorialScreen(),
      const PerfilScreen(),
    ];

    // Verificar si mostrar tutorial después de que la UI carga
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarYMostrarTutorial();
    });
  }

  // ─────────────────────────────────────────
  //  TUTORIAL
  // ─────────────────────────────────────────

  Future<void> _verificarYMostrarTutorial() async {
    final yaVio = await _tutorialService.yaVioTutorialHome();
    if (!yaVio && mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      _iniciarTutorial();
    }
  }

  void _iniciarTutorial() {
    final List<TargetFocus> targets = [

      TargetFocus(
        identify: "mapa",
        keyTarget: _keyMapa,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _BurbujaTutorial(
              icono: Icons.map,
              titulo: "🗺️ Mapa de Reportes",
              mensaje:
                  "Aquí ves todas las fugas reportadas en Sacaba.\n\n"
                  "🟠 Naranja = Pendiente\n"
                  "🔵 Azul = En proceso\n"
                  "🟢 Verde = Resuelto\n\n"
                  "Toca cualquier marcador para ver los detalles.",
              onSiguiente: controller.next,
              onSaltar: controller.skip,
              paso: "1 de 5",
            ),
          ),
        ],
      ),

      TargetFocus(
        identify: "reportar",
        keyTarget: _keyReportar,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _BurbujaTutorial(
              icono: Icons.add_circle,
              titulo: "📋 Reportar Fuga",
              mensaje:
                  "Toca aquí para reportar una fuga de agua "
                  "o problema de alcantarillado.\n\n"
                  "El formulario te guía en 3 pasos:\n"
                  "1️⃣ Describe el problema\n"
                  "2️⃣ Marca la ubicación en el mapa\n"
                  "3️⃣ Adjunta una foto (opcional)",
              onSiguiente: controller.next,
              onSaltar: controller.skip,
              paso: "2 de 5",
            ),
          ),
        ],
      ),

      TargetFocus(
        identify: "historial",
        keyTarget: _keyHistorial,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _BurbujaTutorial(
              icono: Icons.history,
              titulo: "📂 Mis Reportes",
              mensaje:
                  "Aquí encuentras todos los reportes que "
                  "has enviado y puedes ver su estado actual.\n\n"
                  "Recibirás una notificación automática "
                  "cada vez que EMAPAS actualice el estado "
                  "de tu reporte.",
              onSiguiente: controller.next,
              onSaltar: controller.skip,
              paso: "3 de 5",
            ),
          ),
        ],
      ),

      TargetFocus(
        identify: "perfil",
        keyTarget: _keyPerfil,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _BurbujaTutorial(
              icono: Icons.person,
              titulo: "👤 Mi Perfil",
              mensaje:
                  "Aquí puedes ver y actualizar tus datos "
                  "personales: nombre, teléfono y correo.\n\n"
                  "También puedes cerrar sesión desde este menú.",
              onSiguiente: controller.next,
              onSaltar: controller.skip,
              paso: "4 de 5",
            ),
          ),
        ],
      ),

      TargetFocus(
        identify: "fab",
        keyTarget: _keyFab,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _BurbujaTutorial(
              icono: Icons.add,
              titulo: "⚡ Acceso Rápido",
              mensaje:
                  "Este botón te lleva directamente al "
                  "formulario de reporte sin necesidad de "
                  "tocar la barra inferior.\n\n"
                  "¡Úsalo cuando veas una fuga y necesites "
                  "reportarla rápidamente!",
              esUltimo: true,
              onSiguiente: controller.next,
              onSaltar: controller.skip,
              paso: "5 de 5",
            ),
          ),
        ],
      ),
    ];

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0D47A1),
      opacityShadow: 0.85,
      onFinish: () => _tutorialService.marcarTutorialHomeVisto(),
      onSkip: () {
        _tutorialService.marcarTutorialHomeVisto();
        return true;
      },
    );

    _tutorialCoachMark.show(context: context);
  }

  // ─────────────────────────────────────────
  //  CERRAR SESIÓN
  // ─────────────────────────────────────────

  Future<void> _handleSignOut() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // ─────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.water_drop, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'EMAPAS Sacaba',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          // Botón para repetir el tutorial
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'Ver tutorial',
            onPressed: () async {
              await _tutorialService.reiniciarTodos();
              _iniciarTutorial();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // _keyMapa envuelve la pestaña del mapa
          Container(key: _keyMapa, child: const _MapaTab()),
          const ReporteScreen(),
          const HistorialScreen(),
          const PerfilScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined, key: _keyMapa),
            activeIcon: const Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, key: _keyReportar),
            activeIcon: const Icon(Icons.add_circle),
            label: 'Reportar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined, key: _keyHistorial),
            activeIcon: const Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, key: _keyPerfil),
            activeIcon: const Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              key: _keyFab,
              onPressed: () => setState(() => _currentIndex = 1),
              backgroundColor: const Color(0xFF1565C0),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Reportar Fuga',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}

// ═══════════════════════════════════════════════
//  _MapaTab
// ═══════════════════════════════════════════════

class _MapaTab extends StatelessWidget {
  const _MapaTab();

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return StreamBuilder<List<ReporteModel>>(
      stream: firestoreService.getTodosLosReportes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<ReporteModel> reportes = snapshot.data ?? [];

        return Stack(
          children: [
            MapaWidget(reportes: reportes, modoSeleccion: false),
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Leyenda',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    _LeyendaItem(color: Colors.orange, label: 'Pendiente'),
                    _LeyendaItem(color: Colors.blue, label: 'En Proceso'),
                    _LeyendaItem(color: Colors.green, label: 'Resuelto'),
                    const SizedBox(height: 4),
                    Text(
                      '${reportes.length} reporte(s) activo(s)',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
//  _LeyendaItem
// ═══════════════════════════════════════════════

class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LeyendaItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  _BurbujaTutorial
// ═══════════════════════════════════════════════

class _BurbujaTutorial extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final VoidCallback onSiguiente;
  final VoidCallback onSaltar;
  final String paso;
  final bool esUltimo;

  const _BurbujaTutorial({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    required this.onSiguiente,
    required this.onSaltar,
    required this.paso,
    this.esUltimo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: const Color(0xFF1565C0), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0D47A1))),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10)),
                child: Text(paso,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(mensaje,
              style: const TextStyle(
                  fontSize: 14, height: 1.6, color: Color(0xFF333333))),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!esUltimo)
                TextButton(
                  onPressed: onSaltar,
                  child: const Text('Saltar tutorial',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: onSiguiente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: Text(
                  esUltimo ? '¡Entendido! 🎉' : 'Siguiente →',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
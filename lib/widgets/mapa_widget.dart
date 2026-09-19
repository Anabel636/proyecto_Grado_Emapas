import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'
hide Path; // Evita conflicto con Path de Flutter
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../models/reporte_model.dart';

class MapaWidget extends StatefulWidget {
  final List<ReporteModel> reportes;
  final Function(LatLng)? onLocationSelected;
  final bool modoSeleccion;
  final LatLng? posicionInicial;

  const MapaWidget({
    super.key,
    this.reportes = const [],
    this.onLocationSelected,
    this.modoSeleccion = false,
    this.posicionInicial,
  });

  @override
  State<MapaWidget> createState() => _MapaWidgetState();
}

class _MapaWidgetState extends State<MapaWidget> {
  // Controlador del mapa para mover la cámara
  final MapController _mapController = MapController();

  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  bool _isLoadingLocation = true;

  final LocationService _locationService = LocationService();

  // Centro de Sacaba, Cochabamba — posición por defecto
  static const LatLng _sacabaCenter = LatLng(-17.3935, -66.0427);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (widget.posicionInicial != null) {
      setState(() {
        _currentPosition = widget.posicionInicial;
        _isLoadingLocation = false;
      });
    } else {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final Position position =
          await _locationService.getCurrentPosition();
      setState(() {
        _currentPosition =
            LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _currentPosition = _sacabaCenter;
        _isLoadingLocation = false;
      });
    }
  }

  // Construye los marcadores de los reportes
  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];

    // Marcador de ubicación actual (punto azul)
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Marcador de posición seleccionada (modo selección)
    if (_selectedPosition != null) {
      markers.add(
        Marker(
          point: _selectedPosition!,
          width: 40,
          height: 50,
          alignment: Alignment.topCenter,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 46,
          ),
        ),
      );
    }

    // Marcadores de cada reporte
    for (final ReporteModel reporte in widget.reportes) {
      final estadoInfo = ReporteModel.getEstadoInfo(reporte.estado);
      final Color color = Color(estadoInfo['color']);

      markers.add(
        Marker(
          point: LatLng(reporte.latitud, reporte.longitud),
          width: 44,
          height: 54,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _mostrarInfoReporte(reporte, color),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    reporte.tipo == 'fuga_agua'
                        ? Icons.water_drop
                        : Icons.plumbing,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                // Triángulo del pin
                CustomPaint(
                  painter: _TrianglePainter(color: color),
                  size: const Size(12, 8),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  // Muestra un SnackBar con info del reporte al tocar el marcador
  void _mostrarInfoReporte(ReporteModel reporte, Color color) {
    final estadoInfo = ReporteModel.getEstadoInfo(reporte.estado);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              reporte.tipo == 'fuga_agua'
                  ? Icons.water_drop
                  : Icons.plumbing,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(reporte.titulo,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  Text(estadoInfo['label'],
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1565C0)),
            SizedBox(height: 12),
            Text('Obteniendo ubicación GPS...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // ── El mapa principal ──
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            // Posición inicial de la cámara
            initialCenter: _currentPosition ?? _sacabaCenter,
            initialZoom: 15,
            // Acción al tocar el mapa (modo selección)
            onTap: widget.modoSeleccion
                ? (tapPosition, point) async {
                    setState(() => _selectedPosition = point);
                    final dir =
                        await _locationService.getAddressFromCoordinates(
                      point.latitude,
                      point.longitude,
                    );
                    widget.onLocationSelected?.call(point);
                  }
                : null,
          ),
          children: [
            // Capa de mosaicos (tiles) de OpenStreetMap — GRATUITO
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.emapas.emapas_sacaba',
              // Caché local para no descargar los mismos tiles varias veces
              maxNativeZoom: 19,
            ),
            // Capa de marcadores
            MarkerLayer(
              markers: _buildMarkers(),
            ),
          ],
        ),

        // ── Instrucción en modo selección ──
        if (widget.modoSeleccion)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
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
              child: Row(
                children: [
                  const Icon(Icons.touch_app,
                      color: Color(0xFF1565C0), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedPosition == null
                          ? 'Toca el mapa para marcar la ubicación'
                          : '✅ Ubicación marcada. Toca para ajustar.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedPosition == null
                            ? Colors.black87
                            : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Botones de zoom y centrar ──
        Positioned(
          right: 12,
          bottom: 80,
          child: Column(
            children: [
              // Botón centrar en mi ubicación
              FloatingActionButton.small(
                heroTag: 'center',
                backgroundColor: Colors.white,
                onPressed: () {
                  if (_currentPosition != null) {
                    _mapController.move(_currentPosition!, 16);
                  }
                },
                child: const Icon(Icons.my_location,
                    color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 8),
              // Zoom +
              FloatingActionButton.small(
                heroTag: 'zoomin',
                backgroundColor: Colors.white,
                onPressed: () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(
                      _mapController.camera.center, zoom + 1);
                },
                child: const Icon(Icons.add, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              // Zoom -
              FloatingActionButton.small(
                heroTag: 'zoomout',
                backgroundColor: Colors.white,
                onPressed: () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(
                      _mapController.camera.center, zoom - 1);
                },
                child: const Icon(Icons.remove, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Pintor para el triángulo inferior del pin de marcador
class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
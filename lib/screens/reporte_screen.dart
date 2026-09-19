import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../models/reporte_model.dart';
import '../widgets/mapa_widget.dart';

// Esta es la pantalla más importante de la app.
// Permite al ciudadano registrar una fuga con todos sus datos.

class ReporteScreen extends StatefulWidget {
  const ReporteScreen({super.key});

  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  // Clave para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _direccionController = TextEditingController();

  // Servicios
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();
  final _authService = AuthService();

  // Estado del formulario
  String _tipoReporte = 'fuga_agua'; // Valor por defecto
  File? _fotoSeleccionada;           // Foto elegida por el usuario
  LatLng? _ubicacionSeleccionada;    // Coordenadas elegidas en el mapa
  bool _isLoading = false;
  bool _mostrarMapa = false;         // Controla si el mapa es visible

  // Paso actual del formulario (1, 2 o 3)
  int _pasoActual = 0;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // SELECCIONAR FOTO
  // ─────────────────────────────────────────

  Future<void> _seleccionarFoto(ImageSource source) async {
    // Cerramos el bottom sheet antes de abrir la cámara/galería
    Navigator.pop(context);

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,    // Limitamos el tamaño para no consumir mucho almacenamiento
      maxHeight: 1024,
      imageQuality: 80,  // 80% de calidad — buen balance entre tamaño y calidad
    );

    if (image != null) {
      setState(() {
        _fotoSeleccionada = File(image.path);
      });
    }
  }

  // Muestra un menú para elegir entre cámara o galería
  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Adjuntar foto',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1565C0),
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Tomar foto con la cámara'),
                onTap: () => _seleccionarFoto(ImageSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Elegir de la galería'),
                onTap: () => _seleccionarFoto(ImageSource.gallery),
              ),
              if (_fotoSeleccionada != null)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  title: const Text('Eliminar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _fotoSeleccionada = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // OBTENER UBICACIÓN ACTUAL AUTOMÁTICAMENTE
  // ─────────────────────────────────────────

  Future<void> _obtenerUbicacionActual() async {
    setState(() => _isLoading = true);

    try {
      final position = await _locationService.getCurrentPosition();
      final ubicacion = LatLng(position.latitude, position.longitude);
      final direccion = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _ubicacionSeleccionada = ubicacion;
        _direccionController.text = direccion;
        _mostrarMapa = true; // Abrimos el mapa para que pueda ajustar
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo obtener la ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Se ejecuta cuando el usuario toca el mapa para elegir una ubicación
  Future<void> _onUbicacionSeleccionada(LatLng position) async {
    // Convertimos las coordenadas a dirección textual
    final direccion = await _locationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    setState(() {
      _ubicacionSeleccionada = position;
      _direccionController.text = direccion;
    });
  }

  // ─────────────────────────────────────────
  // ENVIAR REPORTE
  // ─────────────────────────────────────────

  Future<void> _enviarReporte() async {
    // Validar el formulario
    if (!_formKey.currentState!.validate()) return;

    // Validar que se haya seleccionado una ubicación
    if (_ubicacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '⚠️ Por favor selecciona la ubicación de la fuga en el mapa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userData = await _authService.getUserData();

      // Creamos el objeto ReporteModel con todos los datos
      final reporte = ReporteModel(
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        tipo: _tipoReporte,
        latitud: _ubicacionSeleccionada!.latitude,
        longitud: _ubicacionSeleccionada!.longitude,
        direccion: _direccionController.text.trim(),
        usuarioId: user.uid,
        usuarioNombre: userData?['nombre'] ?? user.email ?? 'Usuario',
      );

      // Guardamos en Firebase (con foto si la hay)
      final String reporteId =
          await _firestoreService.crearReporteCompleto(
        reporte: reporte,
        fotoFile: _fotoSeleccionada,
        userId: user.uid,
      );

      // Mostramos confirmación de éxito
      if (mounted) {
        _mostrarDialogoExito(reporteId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar el reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Diálogo que aparece cuando el reporte se guardó exitosamente
  void _mostrarDialogoExito(String reporteId) {
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 72),
            const SizedBox(height: 16),
            const Text(
              '¡Reporte Enviado!',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu reporte fue registrado correctamente. EMAPAS Sacaba lo revisará pronto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: $reporteId',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                _limpiarFormulario();   // Limpia el formulario
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Aceptar'),
            ),
          ),
        ],
      ),
    );
  }

  // Limpia todos los campos del formulario después de enviar
  void _limpiarFormulario() {
    setState(() {
      _tituloController.clear();
      _descripcionController.clear();
      _direccionController.clear();
      _tipoReporte = 'fuga_agua';
      _fotoSeleccionada = null;
      _ubicacionSeleccionada = null;
      _mostrarMapa = false;
      _pasoActual = 0;
    });
  }

  // ─────────────────────────────────────────
  // INTERFAZ — BUILD PRINCIPAL
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Indicador de progreso en 3 pasos
          _buildIndicadorPasos(),

          // Contenido según el paso actual
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_pasoActual == 0) _buildPaso1(),
                    if (_pasoActual == 1) _buildPaso2(),
                    if (_pasoActual == 2) _buildPaso3(),
                  ],
                ),
              ),
            ),
          ),

          // Botones de navegación entre pasos
          _buildBotonesNavegacion(),
        ],
      ),
    );
  }

  // ─── Indicador de pasos (1, 2, 3) ───

  Widget _buildIndicadorPasos() {
    final pasos = ['Datos', 'Ubicación', 'Foto'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: List.generate(pasos.length * 2 - 1, (index) {
          // Los índices pares son los círculos, los impares son las líneas
          if (index.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: index ~/ 2 < _pasoActual
                    ? const Color(0xFF1565C0)
                    : Colors.grey[300],
              ),
            );
          }

          final pasoIndex = index ~/ 2;
          final bool completado = pasoIndex < _pasoActual;
          final bool activo = pasoIndex == _pasoActual;

          return Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: completado || activo
                    ? const Color(0xFF1565C0)
                    : Colors.grey[300],
                child: completado
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '${pasoIndex + 1}',
                        style: TextStyle(
                          color: activo ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                pasos[pasoIndex],
                style: TextStyle(
                  fontSize: 11,
                  color: activo
                      ? const Color(0xFF1565C0)
                      : Colors.grey,
                  fontWeight:
                      activo ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ─── PASO 1: Datos del reporte ───

  Widget _buildPaso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información de la fuga',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Describe el problema que observaste',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // Tipo de reporte — selector con dos opciones visuales
        const Text('Tipo de problema',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _TipoReporteCard(
                icono: Icons.water_drop,
                label: 'Fuga de Agua',
                valor: 'fuga_agua',
                seleccionado: _tipoReporte == 'fuga_agua',
                onTap: () =>
                    setState(() => _tipoReporte = 'fuga_agua'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TipoReporteCard(
                icono: Icons.plumbing,
                label: 'Alcantarillado',
                valor: 'alcantarillado',
                seleccionado: _tipoReporte == 'alcantarillado',
                onTap: () =>
                    setState(() => _tipoReporte = 'alcantarillado'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Título del reporte
        TextFormField(
          controller: _tituloController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Título del reporte',
            hintText: 'Ej: Fuga de agua en Av. Blanco Galindo',
            prefixIcon: const Icon(Icons.title),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLength: 80,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor escribe un título';
            }
            if (value.trim().length < 10) {
              return 'El título debe tener al menos 10 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Descripción detallada
        TextFormField(
          controller: _descripcionController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Descripción detallada',
            hintText:
                'Describe qué observas: cantidad de agua, si afecta el tráfico, hace cuánto tiempo...',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: Icon(Icons.description),
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLength: 500,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor escribe una descripción';
            }
            if (value.trim().length < 20) {
              return 'La descripción debe tener al menos 20 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─── PASO 2: Ubicación en el mapa ───

  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación de la fuga',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Marca el lugar exacto en el mapa',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Botón para usar ubicación GPS automática
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _obtenerUbicacionActual,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: const Text('Usar mi ubicación actual (GPS)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF1565C0)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        // Separador "O"
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('O', style: TextStyle(color: Colors.grey[500])),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),
        ),

        // Botón para abrir el mapa y tocar manualmente
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _mostrarMapa = !_mostrarMapa),
            icon: Icon(_mostrarMapa ? Icons.map : Icons.map_outlined),
            label: Text(_mostrarMapa ? 'Ocultar mapa' : 'Seleccionar en el mapa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // El mapa (visible solo si _mostrarMapa es true)
        if (_mostrarMapa)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 300,
              child: MapaWidget(
                modoSeleccion: true,
                posicionInicial: _ubicacionSeleccionada,
                onLocationSelected: _onUbicacionSeleccionada,
              ),
            ),
          ),

        if (_mostrarMapa) const SizedBox(height: 16),

        // Campo de dirección (se llena automáticamente)
        TextFormField(
          controller: _direccionController,
          decoration: InputDecoration(
            labelText: 'Dirección',
            hintText: 'Se completa automáticamente al seleccionar en el mapa',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            // Muestra un check verde si ya tiene dirección
            suffixIcon: _ubicacionSeleccionada != null
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
          validator: (value) {
            if (_ubicacionSeleccionada == null) {
              return 'Por favor selecciona una ubicación en el mapa';
            }
            return null;
          },
        ),

        // Muestra las coordenadas si ya están seleccionadas
        if (_ubicacionSeleccionada != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '📍 Lat: ${_ubicacionSeleccionada!.latitude.toStringAsFixed(6)}, '
              'Lng: ${_ubicacionSeleccionada!.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  // ─── PASO 3: Foto del problema ───

  Widget _buildPaso3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto del problema',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Adjunta una foto para agilizar la atención (opcional)',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // Vista previa de la foto o botón para agregar
        GestureDetector(
          onTap: _mostrarOpcionesFoto,
          child: Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _fotoSeleccionada != null
                    ? const Color(0xFF1565C0)
                    : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: _fotoSeleccionada != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _fotoSeleccionada!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 56, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Toca para agregar foto',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cámara o galería',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),

        if (_fotoSeleccionada != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _mostrarOpcionesFoto,
              icon: const Icon(Icons.edit),
              label: const Text('Cambiar foto'),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Resumen del reporte antes de enviar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📋 Resumen del reporte',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              _ResumenItem(
                  icon: Icons.info_outline,
                  label: 'Tipo',
                  value: _tipoReporte == 'fuga_agua'
                      ? '💧 Fuga de agua potable'
                      : '🚰 Alcantarillado'),
              _ResumenItem(
                  icon: Icons.title,
                  label: 'Título',
                  value: _tituloController.text.isEmpty
                      ? 'Sin título'
                      : _tituloController.text),
              _ResumenItem(
                  icon: Icons.location_on,
                  label: 'Ubicación',
                  value: _direccionController.text.isEmpty
                      ? 'No seleccionada'
                      : _direccionController.text),
              _ResumenItem(
                  icon: Icons.photo,
                  label: 'Foto',
                  value: _fotoSeleccionada != null
                      ? '✅ Adjuntada'
                      : '❌ Sin foto'),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Botones de navegación ───

  Widget _buildBotonesNavegacion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          // Botón "Anterior" (no aparece en el paso 1)
          if (_pasoActual > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    setState(() => _pasoActual--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Anterior'),
              ),
            ),

          if (_pasoActual > 0) const SizedBox(width: 12),

          // Botón "Siguiente" o "Enviar Reporte"
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_pasoActual < 2) {
                        // Validamos el paso actual antes de avanzar
                        if (_pasoActual == 0 &&
                            !_formKey.currentState!.validate()) {
                          return;
                        }
                        setState(() => _pasoActual++);
                      } else {
                        _enviarReporte();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _pasoActual == 2
                    ? Colors.green
                    : const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Enviando...'),
                      ],
                    )
                  : Text(
                      _pasoActual == 2 ? '✅ Enviar Reporte' : 'Siguiente →',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ───

// Tarjeta para seleccionar el tipo de reporte
class _TipoReporteCard extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;
  final bool seleccionado;
  final VoidCallback onTap;

  const _TipoReporteCard({
    required this.icono,
    required this.label,
    required this.valor,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: seleccionado
              ? const Color(0xFF1565C0)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFF1565C0)
                : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              size: 32,
              color: seleccionado ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: seleccionado ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ítem del resumen final
class _ResumenItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ResumenItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
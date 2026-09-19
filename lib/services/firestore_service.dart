import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reporte_model.dart';
import 'storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  // ─────────────────────────────────────────
  // CREAR REPORTE COMPLETO (con foto opcional)
  // ─────────────────────────────────────────
  Future<String> crearReporteCompleto({
    required ReporteModel reporte,
    File? fotoFile, // El archivo de imagen (puede ser null)
    required String userId,
  }) async {
    String? fotoUrl;

    // Si el usuario adjuntó una foto, la subimos primero a Storage
    if (fotoFile != null) {
      fotoUrl = await _storageService.uploadReportPhoto(
        imageFile: fotoFile,
        userId: userId,
      );
    }

    // Creamos el reporte con la URL de la foto (o null si no hay foto)
    final reporteConFoto = ReporteModel(
      titulo: reporte.titulo,
      descripcion: reporte.descripcion,
      tipo: reporte.tipo,
      latitud: reporte.latitud,
      longitud: reporte.longitud,
      direccion: reporte.direccion,
      fotoUrl: fotoUrl,
      usuarioId: reporte.usuarioId,
      usuarioNombre: reporte.usuarioNombre,
    );

    // Guardamos en Firestore y retornamos el ID generado
    final docRef = await _firestore
        .collection('reportes')
        .add(reporteConFoto.toFirestore());

    return docRef.id;
  }

  // Método simple sin foto (mantener compatibilidad)
  Future<String> crearReporte(ReporteModel reporte) async {
    final docRef = await _firestore
        .collection('reportes')
        .add(reporte.toFirestore());
    return docRef.id;
  }

  // Stream de reportes del usuario actual
  Stream<List<ReporteModel>> getReportesUsuario(String usuarioId) {
    return _firestore
        .collection('reportes')
        .where('usuarioId', isEqualTo: usuarioId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ReporteModel.fromFirestore(d)).toList());
  }

  // Stream de todos los reportes (admin)
  Stream<List<ReporteModel>> getTodosLosReportes() {
    return _firestore
        .collection('reportes')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ReporteModel.fromFirestore(d)).toList());
  }

  // Actualizar estado de un reporte
  Future<void> actualizarEstadoReporte(
      String reporteId, String nuevoEstado) async {
    await _firestore.collection('reportes').doc(reporteId).update({
      'estado': nuevoEstado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  // Obtener reporte por ID
  Future<ReporteModel?> getReportePorId(String reporteId) async {
    final doc =
        await _firestore.collection('reportes').doc(reporteId).get();
    if (doc.exists) return ReporteModel.fromFirestore(doc);
    return null;
  }
}
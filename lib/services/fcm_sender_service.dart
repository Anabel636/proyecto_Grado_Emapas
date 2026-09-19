import 'package:cloud_firestore/cloud_firestore.dart';

// Este servicio guarda solicitudes de notificación en Firestore.
// Una Cloud Function de Firebase las procesa y envía via FCM.
// (Para tesis es aceptable; en producción se usa Firebase Admin SDK)

class FCMSenderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cuando el admin cambia el estado, guardamos una solicitud de notificación.
  // Una Cloud Function detecta este nuevo documento y envía el push.
  Future<void> enviarNotificacionCambioEstado({
    required String usuarioId,
    required String reporteId,
    required String tituloReporte,
    required String nuevoEstado,
  }) async {
    final Map<String, String> estadoMensajes = {
      'en_proceso': 'Tu reporte está siendo atendido por nuestro equipo técnico.',
      'resuelto': '¡Tu reporte fue resuelto! Gracias por ayudarnos a mejorar.',
      'rechazado': 'Tu reporte fue revisado y no pudo ser procesado.',
    };

    final String cuerpo =
        estadoMensajes[nuevoEstado] ?? 'El estado de tu reporte fue actualizado.';

    // Guardamos la solicitud en la colección 'notificaciones_pendientes'
    // Una Cloud Function de Firebase (o el admin) la procesa
    await _firestore.collection('notificaciones_pendientes').add({
      'usuarioId': usuarioId,
      'reporteId': reporteId,
      'titulo': '📋 Actualización: $tituloReporte',
      'cuerpo': cuerpo,
      'nuevoEstado': nuevoEstado,
      'topic': 'usuario_$usuarioId', // El tema personal del usuario
      'enviado': false,
      'fechaCreacion': FieldValue.serverTimestamp(),
    });
  }
}
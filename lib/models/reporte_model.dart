import 'package:cloud_firestore/cloud_firestore.dart';

class ReporteModel {
  final String? id;
  final String titulo;
  final String descripcion;
  final String tipo;      // 'fuga_agua' o 'alcantarillado'
  final String estado;    // 'pendiente', 'en_proceso', 'resuelto'
  final double latitud;
  final double longitud;
  final String direccion;
  final String? fotoUrl;
  final String usuarioId;
  final String usuarioNombre;
  final DateTime? fechaCreacion;

  ReporteModel({
    this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    this.estado = 'pendiente',
    required this.latitud,
    required this.longitud,
    required this.direccion,
    this.fotoUrl,
    required this.usuarioId,
    required this.usuarioNombre,
    this.fechaCreacion,
  });

  // Convierte documento Firestore → objeto Dart
  factory ReporteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReporteModel(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      tipo: data['tipo'] ?? 'fuga_agua',
      estado: data['estado'] ?? 'pendiente',
      latitud: (data['latitud'] ?? 0.0).toDouble(),
      longitud: (data['longitud'] ?? 0.0).toDouble(),
      direccion: data['direccion'] ?? '',
      fotoUrl: data['fotoUrl'],
      usuarioId: data['usuarioId'] ?? '',
      usuarioNombre: data['usuarioNombre'] ?? '',
      fechaCreacion: data['fechaCreacion'] != null
          ? (data['fechaCreacion'] as Timestamp).toDate()
          : null,
    );
  }

  // Convierte objeto Dart → Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo,
      'estado': estado,
      'latitud': latitud,
      'longitud': longitud,
      'direccion': direccion,
      'fotoUrl': fotoUrl,
      'usuarioId': usuarioId,
      'usuarioNombre': usuarioNombre,
      'fechaCreacion': FieldValue.serverTimestamp(),
    };
  }

  // Color e información según el estado del reporte
  static Map<String, dynamic> getEstadoInfo(String estado) {
    switch (estado) {
      case 'pendiente': return {'label': 'Pendiente', 'color': 0xFFFF9800};
      case 'en_proceso': return {'label': 'En Proceso', 'color': 0xFF2196F3};
      case 'resuelto': return {'label': 'Resuelto', 'color': 0xFF4CAF50};
      case 'rechazado': return {'label': 'Rechazado', 'color': 0xFFF44336};
      default: return {'label': 'Desconocido', 'color': 0xFF9E9E9E};
    }
  }
}

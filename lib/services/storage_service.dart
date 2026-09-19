import 'dart:io'; // Para trabajar con archivos del dispositivo
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart'; // Para generar nombres únicos

// Este servicio sube imágenes a Firebase Storage
// y retorna la URL pública de la foto guardada.

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // ─────────────────────────────────────────
  // SUBIR FOTO DE UN REPORTE
  // Recibe el archivo de imagen y el ID del usuario.
  // Retorna la URL pública para acceder a la imagen.
  // ─────────────────────────────────────────
  Future<String> uploadReportPhoto({
    required File imageFile,
    required String userId,
  }) async {
    // Generamos un nombre único para evitar colisiones
    // Ejemplo: reportes/uid123/foto_a1b2c3d4.jpg
    final String fileName = 'foto_${_uuid.v4()}.jpg';
    final String path = 'reportes/$userId/$fileName';

    // Referencia al lugar en Storage donde guardaremos la foto
    final Reference ref = _storage.ref().child(path);

    // Subimos el archivo con metadatos
    final UploadTask uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // Esperamos a que termine la subida
    // TaskSnapshot contiene información sobre la subida completada
    final TaskSnapshot snapshot = await uploadTask;

    // Obtenemos y retornamos la URL pública de descarga
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  // ─────────────────────────────────────────
  // ELIMINAR UNA FOTO (si el reporte se cancela)
  // ─────────────────────────────────────────
  Future<void> deletePhoto(String photoUrl) async {
    try {
      // Obtenemos la referencia a partir de la URL
      final Reference ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      // Si falla la eliminación, no interrumpimos el flujo
      print('No se pudo eliminar la foto: $e');
    }
  }
}
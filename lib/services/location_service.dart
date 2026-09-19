import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Este servicio maneja todo lo relacionado con el GPS:
// - Pedir permisos al usuario
// - Obtener las coordenadas actuales
// - Convertir coordenadas en dirección textual (geocodificación inversa)

class LocationService {

  // ─────────────────────────────────────────
  // VERIFICAR Y PEDIR PERMISOS
  // ─────────────────────────────────────────

  // Verifica si tenemos permiso y si el GPS está activado.
  // Retorna true si todo está listo, false si hay algún problema.
  Future<bool> checkAndRequestPermission() async {

    // Paso 1: Verificar si el servicio de ubicación está activado
    // (el usuario puede tener el GPS apagado en ajustes del celular)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      // El GPS está apagado — no podemos hacer nada sin que el usuario lo active
      return false;
    }

    // Paso 2: Verificar qué permiso tenemos actualmente
    LocationPermission permission = await Geolocator.checkPermission();

    // Si el permiso fue denegado, lo pedimos al usuario
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      // Si el usuario volvió a denegar, no podemos continuar
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    // Si el usuario marcó "No preguntar de nuevo", debemos mandarlo a Ajustes
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    // Si llegamos aquí, tenemos permiso ✅
    return true;
  }

  // ─────────────────────────────────────────
  // OBTENER POSICIÓN ACTUAL
  // ─────────────────────────────────────────

  // Retorna las coordenadas GPS actuales del dispositivo.
  // Puede lanzar una excepción si no hay permisos.
  Future<Position> getCurrentPosition() async {

    final bool hasPermission = await checkAndRequestPermission();

    if (!hasPermission) {
      throw Exception(
          'No se pudo obtener la ubicación. Verifica que el GPS esté activado y los permisos otorgados.');
    }

    // Obtenemos la posición con alta precisión
    // LocationAccuracy.high usa GPS (más preciso pero consume más batería)
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15), // Tiempo máximo de espera
    );
  }

  // ─────────────────────────────────────────
  // GEOCODIFICACIÓN INVERSA
  // Convierte coordenadas (lat, lng) en una dirección legible
  // Ejemplo: -17.3935, -66.1568 → "Av. Blanco Galindo, Sacaba"
  // ─────────────────────────────────────────

  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      // Pedimos la lista de lugares en esas coordenadas
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        // Construimos la dirección combinando los campos disponibles
        final List<String> parts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          parts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }

        // Si no encontramos nada útil, usamos las coordenadas directamente
        if (parts.isEmpty) {
          return 'Lat: ${latitude.toStringAsFixed(4)}, '
              'Lng: ${longitude.toStringAsFixed(4)}';
        }

        return parts.join(', ');
      }

      return 'Dirección no disponible';

    } catch (e) {
      // Si falla la geocodificación (sin internet, etc.),
      // retornamos las coordenadas como texto
      return 'Lat: ${latitude.toStringAsFixed(4)}, '
          'Lng: ${longitude.toStringAsFixed(4)}';
    }
  }

  // ─────────────────────────────────────────
  // CALCULAR DISTANCIA ENTRE DOS PUNTOS
  // Útil para mostrar qué tan lejos está un reporte del usuario
  // Retorna la distancia en metros
  // ─────────────────────────────────────────

  double distanceBetween({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
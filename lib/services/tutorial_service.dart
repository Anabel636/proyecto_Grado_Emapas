import 'package:shared_preferences/shared_preferences.dart';

// Este servicio recuerda si el usuario ya vio el tutorial
// para no mostrárselo cada vez que abre la app.

class TutorialService {

  // Claves para guardar en SharedPreferences
  // (pequeña base de datos local del celular)
  static const String _keyHome     = 'tutorial_home_visto';
  static const String _keyReporte  = 'tutorial_reporte_visto';
  static const String _keyAdmin    = 'tutorial_admin_visto';

  // ¿Ya vio el tutorial de la pantalla principal?
  Future<bool> yaVioTutorialHome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHome) ?? false;
  }

  // Marcar que ya vio el tutorial de Home
  Future<void> marcarTutorialHomeVisto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHome, true);
  }

  Future<bool> yaVioTutorialReporte() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReporte) ?? false;
  }

  Future<void> marcarTutorialReporteVisto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReporte, true);
  }

  Future<bool> yaVioTutorialAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAdmin) ?? false;
  }

  Future<void> marcarTutorialAdminVisto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdmin, true);
  }

  // Reiniciar todos los tutoriales (útil para pruebas)
  Future<void> reiniciarTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHome);
    await prefs.remove(_keyReporte);
    await prefs.remove(_keyAdmin);
  }
}
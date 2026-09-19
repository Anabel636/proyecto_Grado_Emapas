import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

// Instancia global del servicio de notificaciones
final NotificationService notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar el servicio de notificaciones
  await notificationService.initialize();

  runApp(const EMAPASApp());
}

class EMAPASApp extends StatelessWidget {
  const EMAPASApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMAPAS Sacaba',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
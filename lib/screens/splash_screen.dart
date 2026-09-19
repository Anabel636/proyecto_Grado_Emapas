import 'package:flutter/material.dart';
import 'dart:async'; // Para usar Timer
// En splash_screen.dart, cambia la importación y el Navigator:
import 'auth_wrapper.dart'; // Cambiar login_screen.dart por esto


// Esta pantalla es lo primero que ve el usuario al abrir la app.
// Muestra el logo y nombre de EMAPAS por 3 segundos, luego va al Login.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  
  // Controlador para la animación de aparición del logo
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Configuramos la animación: dura 1.5 segundos y hace aparecer el logo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Iniciamos la animación
    _controller.forward();

    // Y en el Timer, cambia LoginScreen() por AuthWrapper():
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    });
  }
  @override
  void dispose() {
    _controller.dispose(); // Liberamos memoria
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Color de fondo azul corporativo de EMAPAS
      backgroundColor: const Color(0xFF1565C0),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono de gota de agua (representando el servicio de agua)
              const Icon(
                Icons.water_drop,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24), // Espacio de 24 píxeles
              // Nombre de la empresa
              const Text(
                'EMAPAS Sacaba',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              // Subtítulo
              const Text(
                'Sistema de Reportes',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              // Indicador de carga giratorio
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
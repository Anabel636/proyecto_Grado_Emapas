import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

// Este widget decide automáticamente a dónde ir:
// Si hay sesión activa → HomeScreen
// Si no hay sesión     → LoginScreen
// Así el usuario no tiene que iniciar sesión cada vez que abre la app.

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      // Escucha en tiempo real los cambios de sesión
      stream: authService.authStateChanges,
      builder: (context, snapshot) {

        // Mientras Firebase verifica la sesión, mostramos un indicador
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si hay un usuario con sesión iniciada
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // Si no hay sesión
        return const LoginScreen();
      },
    );
  }
}
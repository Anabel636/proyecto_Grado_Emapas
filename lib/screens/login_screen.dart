import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import '../main.dart'; // Importa la instancia global de NotificationService
import '../services/notification_service.dart'; // Importa el servicio de notificaciones

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Instancia del servicio de autenticación
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Llamamos al servicio real de Firebase
        await _authService.loginWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Guardar token FCM para este usuario
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await notificationService.subscribeToTopic('todos'); // Todos los ciudadanos
          await notificationService.subscribeToTopic('usuario_${user.uid}'); // Canal personal
        }
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        // Capturamos errores específicos de Firebase
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_authService.getErrorMessage(e.code)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // El build es idéntico al de la Fase 3 — no cambia la interfaz,
    // solo cambia la lógica del botón que ahora usa Firebase real.
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Icon(Icons.water_drop, size: 72, color: Color(0xFF1565C0)),
              const SizedBox(height: 16),
              const Text(
                'EMAPAS Sacaba',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              const Text(
                'Iniciar Sesión',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu correo';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña';
                        }
                        if (value.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Iniciar Sesión',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿No tienes cuenta? '),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          ),
                          child: const Text('Regístrate',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
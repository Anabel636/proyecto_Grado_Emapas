import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _authService.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nombre: _nombreController.text.trim(),
          telefono: _telefonoController.text.trim(),
        );

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false, // Elimina todas las pantallas anteriores
          );
        }
      } on FirebaseAuthException catch (e) {
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Campo Nombre completo
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    if (value.trim().length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Teléfono
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Teléfono / Celular',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu teléfono';
                    }
                    if (value.length < 7) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
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

                // Campo Contraseña
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
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor crea una contraseña';
                    }
                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Confirmar Contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu contraseña';
                    }
                    // Verifica que ambas contraseñas sean iguales
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botón Registrarse
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Crear Cuenta',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false; // Controla si ya se envió el correo

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _authService
            .sendPasswordResetEmail(_emailController.text.trim());

        // Mostramos la pantalla de confirmación
        if (mounted) setState(() => _emailSent = true);
        
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'No se pudo enviar el correo. Verifica el email.'),
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
        title: const Text('Recuperar Contraseña'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Muestra una pantalla diferente según si ya se envió el correo
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  // Vista del formulario (antes de enviar)
  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const Icon(Icons.lock_reset, size: 72, color: Color(0xFF1565C0)),
        const SizedBox(height: 24),
        const Text(
          'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: TextFormField(
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
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Enviar enlace',
                    style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // Vista de éxito (después de enviar)
  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          '¡Correo enviado!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Revisa tu bandeja de entrada en ${_emailController.text}.\n\nSigue el enlace del correo para crear una nueva contraseña.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Volver al Login'),
        ),
      ],
    );
  }
}
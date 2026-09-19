import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserData(),
      builder: (context, snapshot) {
        final userData = snapshot.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Avatar con inicial del nombre
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFF1565C0),
                child: Text(
                  (userData?['nombre'] ?? user?.email ?? 'U')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userData?['nombre'] ?? 'Usuario',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                user?.email ?? '',
                style:
                    const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              // Tarjeta de información
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _InfoTile(
                        icon: Icons.phone,
                        label: 'Teléfono',
                        value: userData?['telefono'] ?? 'No registrado'),
                    const Divider(height: 1),
                    _InfoTile(
                        icon: Icons.badge,
                        label: 'Rol',
                        value: userData?['rol'] == 'admin'
                            ? 'Administrador'
                            : 'Ciudadano'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1565C0)),
      title: Text(label,
          style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500)),
    );
  }
}
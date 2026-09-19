import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/reporte_model.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox();

    return StreamBuilder<List<ReporteModel>>(
      stream: firestoreService.getReportesUsuario(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reportes = snapshot.data ?? [];

        if (reportes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 72, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aún no tienes reportes',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                const Text('Toca "Reportar" para crear tu primer reporte'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reportes.length,
          itemBuilder: (context, index) {
            final reporte = reportes[index];
            final estadoInfo = ReporteModel.getEstadoInfo(reporte.estado);
            final color = Color(estadoInfo['color']);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(
                    reporte.tipo == 'fuga_agua'
                        ? Icons.water_drop
                        : Icons.plumbing,
                    color: color,
                  ),
                ),
                title: Text(
                  reporte.titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      reporte.direccion,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            estadoInfo['label'],
                            style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        if (reporte.fechaCreacion != null)
                          Text(
                            DateFormat('dd/MM/yyyy')
                                .format(reporte.fechaCreacion!),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
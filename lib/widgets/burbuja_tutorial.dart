import 'package:flutter/material.dart';

// Este widget es el globito/burbuja que aparece en cada paso
// del tutorial explicando qué hace ese elemento.

class _BurbujaTutorial extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final VoidCallback onSiguiente;
  final VoidCallback onSaltar;
  final String paso;
  final bool esUltimo;

  const _BurbujaTutorial({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    required this.onSiguiente,
    required this.onSaltar,
    required this.paso,
    this.esUltimo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          // Encabezado: ícono + título + indicador de paso
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: const Color(0xFF1565C0), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
              // Indicador "1 de 5"
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  paso,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Mensaje explicativo
          Text(
            mensaje,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF333333),
            ),
          ),

          const SizedBox(height: 16),

          // Botones
          Row(
            children: [
              // Botón "Saltar" — solo si no es el último paso
              if (!esUltimo)
                TextButton(
                  onPressed: onSaltar,
                  child: const Text(
                    "Saltar tutorial",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),

              const Spacer(),

              // Botón "Siguiente" o "¡Entendido!" en el último
              ElevatedButton(
                onPressed: onSiguiente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: Text(
                  esUltimo ? "¡Entendido! 🎉" : "Siguiente →",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
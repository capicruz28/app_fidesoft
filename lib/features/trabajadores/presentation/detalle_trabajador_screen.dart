// lib/features/trabajadores/presentation/detalle_trabajador_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trabajador_model.dart';

class DetalleTrabajadorScreen extends StatelessWidget {
  final TrabajadorModel trabajador;

  const DetalleTrabajadorScreen({
    super.key,
    required this.trabajador,
  });

  @override
  Widget build(BuildContext context) {
    final edad = trabajador.edad;
    final dateFormat = DateFormat('dd/MM/yyyy', 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Trabajador'),
        backgroundColor: const Color(0xFF4CCB9E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principal con información básica
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF4CCB9E).withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF4CCB9E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      trabajador.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CCB9E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trabajador.codigoTrabajador,
                        style: const TextStyle(
                          color: Color(0xFF4CCB9E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Información personal
            _buildSectionTitle('Información Personal'),
            Card(
              elevation: 2,
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.badge,
                    label: 'DNI',
                    value: trabajador.dni,
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.cake,
                    label: 'Fecha de Nacimiento',
                    value: trabajador.fechaNacimiento != null
                        ? '${dateFormat.format(trabajador.fechaNacimiento!)}${edad != null ? ' ($edad años)' : ''}'
                        : 'No disponible',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Información laboral
            _buildSectionTitle('Información Laboral'),
            Card(
              elevation: 2,
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.business,
                    label: 'Área',
                    value: trabajador.descripcionArea.trim(),
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.domain,
                    label: 'Sección',
                    value: trabajador.descripcionSeccion.trim(),
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.work,
                    label: 'Cargo',
                    value: trabajador.descripcionCargo.trim(),
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Fecha de Ingreso',
                    value: trabajador.fechaIngreso != null
                        ? dateFormat.format(trabajador.fechaIngreso!)
                        : 'No disponible',
                  ),
                  if (trabajador.fechaFinContrato != null) ...[
                    const Divider(height: 1),
                    _buildInfoRow(
                      icon: Icons.event_busy,
                      label: 'Fecha Fin de Contrato',
                      value: dateFormat.format(trabajador.fechaFinContrato!),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Códigos
            _buildSectionTitle('Códigos'),
            Card(
              elevation: 2,
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.tag,
                    label: 'Código Área',
                    value: trabajador.codigoArea,
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.tag,
                    label: 'Código Sección',
                    value: trabajador.codigoSeccion,
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.tag,
                    label: 'Código Cargo',
                    value: trabajador.codigoCargo,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4CCB9E),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4CCB9E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// lib/features/vacaciones/presentation/detalle_solicitud_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/solicitud_model.dart';
import '../../../../data/services/vacaciones_permisos_service.dart';

class DetalleSolicitudScreen extends StatefulWidget {
  final SolicitudModel solicitud;

  const DetalleSolicitudScreen({
    super.key,
    required this.solicitud,
  });

  @override
  State<DetalleSolicitudScreen> createState() => _DetalleSolicitudScreenState();
}

class _DetalleSolicitudScreenState extends State<DetalleSolicitudScreen> {
  final VacacionesPermisosService _service = VacacionesPermisosService();
  SolicitudModel? _solicitudCompleta;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalleCompleto();
  }

  Future<void> _cargarDetalleCompleto() async {
    if (widget.solicitud.idSolicitud == null) {
      setState(() {
        _solicitudCompleta = widget.solicitud;
        _isLoading = false;
      });
      return;
    }

    try {
      final solicitud = await _service.obtenerSolicitud(widget.solicitud.idSolicitud!);
      final aprobaciones = await _service.obtenerAprobaciones(widget.solicitud.idSolicitud!);
      
      setState(() {
        _solicitudCompleta = SolicitudModel(
          idSolicitud: solicitud.idSolicitud,
          tipoSolicitud: solicitud.tipoSolicitud,
          codigoPermiso: solicitud.codigoPermiso,
          codigoTrabajador: solicitud.codigoTrabajador,
          fechaInicio: solicitud.fechaInicio,
          fechaFin: solicitud.fechaFin,
          diasSolicitados: solicitud.diasSolicitados,
          observacion: solicitud.observacion,
          motivo: solicitud.motivo,
          estado: solicitud.estado,
          fechaRegistro: solicitud.fechaRegistro,
          usuarioRegistro: solicitud.usuarioRegistro,
          fechaModificacion: solicitud.fechaModificacion,
          usuarioModificacion: solicitud.usuarioModificacion,
          fechaAnulacion: solicitud.fechaAnulacion,
          usuarioAnulacion: solicitud.usuarioAnulacion,
          motivoAnulacion: solicitud.motivoAnulacion,
          nombreTrabajador: solicitud.nombreTrabajador,
          nombrePermiso: solicitud.nombrePermiso,
          aprobaciones: aprobaciones,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _solicitudCompleta = widget.solicitud;
        _isLoading = false;
      });
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'A':
        return Colors.green;
      case 'R':
        return Colors.red;
      case 'N':
        return Colors.grey;
      case 'P':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitud = _solicitudCompleta ?? widget.solicitud;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de ${solicitud.tipoSolicitudTexto}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de Información General
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                solicitud.tipoSolicitudTexto,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(solicitud.estado).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getEstadoColor(solicitud.estado),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  solicitud.estadoTexto,
                                  style: TextStyle(
                                    color: _getEstadoColor(solicitud.estado),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (solicitud.nombrePermiso != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tipo: ${solicitud.nombrePermiso}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.person,
                            'Trabajador',
                            solicitud.nombreTrabajador ?? solicitud.codigoTrabajador,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Fecha Inicio',
                            DateFormat('dd/MM/yyyy', 'es').format(solicitud.fechaInicio),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Fecha Fin',
                            DateFormat('dd/MM/yyyy', 'es').format(solicitud.fechaFin),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.calculate,
                            'Días Solicitados',
                            '${solicitud.diasSolicitados?.toStringAsFixed(1) ?? '0'} días',
                          ),
                          if (solicitud.observacion != null && solicitud.observacion!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Observaciones',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(solicitud.observacion!),
                          ],
                          if (solicitud.motivo != null && solicitud.motivo!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Motivo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(solicitud.motivo!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card de Flujo de Aprobación
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Flujo de Aprobación',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (solicitud.aprobaciones == null || solicitud.aprobaciones!.isEmpty)
                            const Text(
                              'No hay aprobaciones registradas',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...solicitud.aprobaciones!.map((aprobacion) {
                              return _buildAprobacionItem(aprobacion);
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
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
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAprobacionItem(AprobacionModel aprobacion) {
    final isAprobado = aprobacion.estaAprobado;
    final isRechazado = aprobacion.estaRechazado;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isAprobado) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Aprobado';
    } else if (isRechazado) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Rechazado';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Pendiente';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: statusColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: statusColor.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nivel ${aprobacion.nivel}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (aprobacion.nombreAprobador != null || aprobacion.codigoTrabajadorAprueba.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Aprobador: ${aprobacion.nombreAprobador ?? aprobacion.codigoTrabajadorAprueba}',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
          if (aprobacion.fecha != null) ...[
            const SizedBox(height: 4),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy HH:mm', 'es').format(aprobacion.fecha!)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
          if (aprobacion.observacion != null && aprobacion.observacion!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                aprobacion.observacion!,
                style: TextStyle(color: Colors.grey[800], fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

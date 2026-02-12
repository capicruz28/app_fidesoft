// lib/features/vacaciones/presentation/mis_solicitudes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/vacaciones_permisos_service.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/models/solicitud_model.dart';
import '../../../../core/providers/user_provider.dart';
import 'detalle_solicitud_screen.dart';

class MisSolicitudesScreen extends StatefulWidget {
  final String tipo; // 'V' para vacaciones, 'P' para permisos, 'T' para todos

  const MisSolicitudesScreen({
    super.key,
    this.tipo = 'T',
  });

  @override
  State<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends State<MisSolicitudesScreen> {
  final VacacionesPermisosService _service = VacacionesPermisosService();
  List<SolicitudModel> _solicitudes = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      List<SolicitudModel> solicitudes;
      
      if (widget.tipo == 'V') {
        solicitudes = await _service.misSolicitudesVacaciones();
        // Filtrar solo vacaciones
        solicitudes = solicitudes.where((s) => s.tipoSolicitud == 'V').toList();
      } else if (widget.tipo == 'P') {
        solicitudes = await _service.misSolicitudesPermisos();
      } else {
        // Todos
        solicitudes = await _service.misSolicitudesVacaciones();
      }

      // Cargar aprobaciones para cada solicitud
      for (var solicitud in solicitudes) {
        try {
          final aprobaciones = await _service.obtenerAprobaciones(solicitud.idSolicitud ?? 0);
          solicitud = SolicitudModel(
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
        } catch (e) {
          print('Error al cargar aprobaciones: $e');
        }
      }

      setState(() {
        _solicitudes = solicitudes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString();
      if (errMsg.contains('SESSION_EXPIRED') || errMsg.contains('credenciales')) {
        Provider.of<UserProvider>(context, listen: false).logout();
        final authService = AuthService();
        await authService.logout();
        await authService.clearSavedCredentials();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }
      setState(() {
        _error = 'Error al cargar solicitudes: $e';
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

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'A':
        return Icons.check_circle;
      case 'R':
        return Icons.cancel;
      case 'N':
        return Icons.block;
      case 'P':
      default:
        return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tipo == 'V'
              ? 'Mis Vacaciones'
              : widget.tipo == 'P'
                  ? 'Mis Permisos'
                  : 'Mis Solicitudes',
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarSolicitudes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarSolicitudes,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _solicitudes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay solicitudes',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarSolicitudes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _solicitudes.length,
                        itemBuilder: (context, index) {
                          final solicitud = _solicitudes[index];
                          return _buildSolicitudCard(solicitud);
                        },
                      ),
                    ),
    );
  }

  Widget _buildSolicitudCard(SolicitudModel solicitud) {
    final estadoColor = _getEstadoColor(solicitud.estado);
    final estadoIcon = _getEstadoIcon(solicitud.estado);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleSolicitudScreen(
                solicitud: solicitud,
              ),
            ),
          );
          if (resultado == true) {
            _cargarSolicitudes(); // Recargar si hubo cambios
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con tipo y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        solicitud.tipoSolicitud == 'V'
                            ? Icons.beach_access
                            : Icons.event_available,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        solicitud.tipoSolicitudTexto,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (solicitud.nombrePermiso != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '- ${solicitud.nombrePermiso}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: estadoColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(estadoIcon, size: 16, color: estadoColor),
                        const SizedBox(width: 4),
                        Text(
                          solicitud.estadoTexto,
                          style: TextStyle(
                            color: estadoColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Fechas
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd/MM/yyyy', 'es').format(solicitud.fechaInicio)} - ${DateFormat('dd/MM/yyyy', 'es').format(solicitud.fechaFin)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Días
              Row(
                children: [
                  Icon(Icons.calculate, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${solicitud.diasSolicitados?.toStringAsFixed(1) ?? '0'} días',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              
              // Flujo de aprobación (mini vista)
              if (solicitud.aprobaciones != null && solicitud.aprobaciones!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Progreso de Aprobación',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                ...solicitud.aprobaciones!.map((aprobacion) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          aprobacion.estaAprobado
                              ? Icons.check_circle
                              : aprobacion.estaRechazado
                                  ? Icons.cancel
                                  : Icons.pending,
                          size: 16,
                          color: aprobacion.estaAprobado
                              ? Colors.green
                              : aprobacion.estaRechazado
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nivel ${aprobacion.nivel}: ${aprobacion.estadoTexto}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              
              // Fecha de registro
              if (solicitud.fechaRegistro != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Solicitado: ${DateFormat('dd/MM/yyyy HH:mm', 'es').format(solicitud.fechaRegistro!)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

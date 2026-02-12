// lib/features/vacaciones/presentation/pendientes_aprobar_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/vacaciones_permisos_service.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/models/solicitud_model.dart';
import '../../../../core/providers/user_provider.dart';
import 'detalle_solicitud_screen.dart';
import 'aprobar_solicitud_dialog.dart';

class PendientesAprobarScreen extends StatefulWidget {
  final String? tipoFiltro; // 'T' = Todos, 'V' = Vacaciones, 'P' = Permisos
  
  const PendientesAprobarScreen({super.key, this.tipoFiltro});

  @override
  State<PendientesAprobarScreen> createState() => _PendientesAprobarScreenState();
}

class _PendientesAprobarScreenState extends State<PendientesAprobarScreen> {
  final VacacionesPermisosService _service = VacacionesPermisosService();
  List<SolicitudModel> _solicitudes = [];
  bool _isLoading = true;
  String _error = '';
  late String _filtroTipo; // 'T' = Todos, 'V' = Vacaciones, 'P' = Permisos

  @override
  void initState() {
    super.initState();
    // Usar el filtro pasado como parámetro o 'T' por defecto
    _filtroTipo = widget.tipoFiltro ?? 'T';
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // El backend ahora filtra correctamente por nivel jerárquico y envía nombre_trabajador
      final solicitudesRaw = await _service.pendientesAprobar();
      final List<SolicitudModel> solicitudesEnriquecidas = [];

      for (final s in solicitudesRaw) {
        try {
          final aprobaciones = await _service.obtenerAprobaciones(s.idSolicitud ?? 0);
          solicitudesEnriquecidas.add(SolicitudModel(
            idSolicitud: s.idSolicitud,
            tipoSolicitud: s.tipoSolicitud,
            codigoPermiso: s.codigoPermiso,
            codigoTrabajador: s.codigoTrabajador,
            fechaInicio: s.fechaInicio,
            fechaFin: s.fechaFin,
            diasSolicitados: s.diasSolicitados,
            observacion: s.observacion,
            motivo: s.motivo,
            estado: s.estado,
            fechaRegistro: s.fechaRegistro,
            usuarioRegistro: s.usuarioRegistro,
            fechaModificacion: s.fechaModificacion,
            usuarioModificacion: s.usuarioModificacion,
            fechaAnulacion: s.fechaAnulacion,
            usuarioAnulacion: s.usuarioAnulacion,
            motivoAnulacion: s.motivoAnulacion,
            nombreTrabajador: s.nombreTrabajador,
            nombrePermiso: s.nombrePermiso,
            aprobaciones: aprobaciones,
          ));
        } catch (e) {
          print('Error al cargar aprobaciones: $e');
          solicitudesEnriquecidas.add(s);
        }
      }

      setState(() {
        _solicitudes = solicitudesEnriquecidas;
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

  Future<void> _mostrarDialogoAprobar(SolicitudModel solicitud) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AprobarSolicitudDialog(
        solicitud: solicitud,
        esAprobar: true,
      ),
    );

    if (resultado == true) {
      _cargarSolicitudes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud aprobada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _mostrarDialogoRechazar(SolicitudModel solicitud) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AprobarSolicitudDialog(
        solicitud: solicitud,
        esAprobar: false,
      ),
    );

    if (resultado == true) {
      _cargarSolicitudes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud rechazada'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  List<SolicitudModel> get _solicitudesFiltradas {
    if (_filtroTipo == 'T') return _solicitudes;
    return _solicitudes.where((s) => s.tipoSolicitud == _filtroTipo).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendientes de Aprobar'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarSolicitudes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text('Filtrar: '),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _filtroTipo == 'T',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filtroTipo = 'T');
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Vacaciones'),
                  selected: _filtroTipo == 'V',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filtroTipo = 'V');
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Permisos'),
                  selected: _filtroTipo == 'P',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filtroTipo = 'P');
                    }
                  },
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: _isLoading
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
                    : _solicitudesFiltradas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay solicitudes pendientes',
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
                              itemCount: _solicitudesFiltradas.length,
                              itemBuilder: (context, index) {
                                final solicitud = _solicitudesFiltradas[index];
                                return _buildSolicitudCard(solicitud);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudCard(SolicitudModel solicitud) {
    // Encontrar el nivel pendiente
    final aprobacionPendiente = solicitud.aprobaciones
        ?.where((a) => a.estaPendiente)
        .firstOrNull;

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
            _cargarSolicitudes();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pending, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Pendiente',
                          style: TextStyle(
                            color: Colors.orange,
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

              // Información del trabajador: codigo - nombres y apellidos
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (solicitud.nombreTrabajador != null &&
                              solicitud.nombreTrabajador!.trim().isNotEmpty)
                          ? '${solicitud.codigoTrabajador} - ${solicitud.nombreTrabajador!.trim()}'
                          : solicitud.codigoTrabajador,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

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

              // Nivel de aprobación pendiente
              if (aprobacionPendiente != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Pendiente de aprobación - Nivel ${aprobacionPendiente.nivel}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Botones de acción
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _mostrarDialogoRechazar(solicitud),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Rechazar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _mostrarDialogoAprobar(solicitud),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

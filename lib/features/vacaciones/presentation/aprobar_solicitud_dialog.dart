// lib/features/vacaciones/presentation/aprobar_solicitud_dialog.dart
import 'package:flutter/material.dart';
import '../../../../data/models/solicitud_model.dart';
import '../../../../data/services/vacaciones_permisos_service.dart';

class AprobarSolicitudDialog extends StatefulWidget {
  final SolicitudModel solicitud;
  final bool esAprobar; // true = aprobar, false = rechazar

  const AprobarSolicitudDialog({
    super.key,
    required this.solicitud,
    required this.esAprobar,
  });

  @override
  State<AprobarSolicitudDialog> createState() => _AprobarSolicitudDialogState();
}

class _AprobarSolicitudDialogState extends State<AprobarSolicitudDialog> {
  final _observacionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final VacacionesPermisosService _service = VacacionesPermisosService();
  bool _isLoading = false;

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _procesarAccion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Si es rechazar, la observación es obligatoria
    if (!widget.esAprobar && _observacionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar un motivo para rechazar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener IP del dispositivo (por ahora vacío, el backend puede obtenerla del request)
      final ipDispositivo = ''; // Se puede implementar obtención real de IP si es necesario
      
      if (widget.esAprobar) {
        await _service.aprobarSolicitud(
          idSolicitud: widget.solicitud.idSolicitud!,
          observacion: _observacionController.text.trim().isEmpty
              ? null
              : _observacionController.text.trim(),
          ipDispositivo: ipDispositivo,
        );
      } else {
        await _service.rechazarSolicitud(
          idSolicitud: widget.solicitud.idSolicitud!,
          observacion: _observacionController.text.trim(),
          ipDispositivo: ipDispositivo,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true); // Retornar true para indicar éxito
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.esAprobar ? 'Aprobar Solicitud' : 'Rechazar Solicitud',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.esAprobar
                    ? '¿Está seguro que desea aprobar esta solicitud?'
                    : '¿Está seguro que desea rechazar esta solicitud?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Trabajador: ${widget.solicitud.nombreTrabajador ?? widget.solicitud.codigoTrabajador}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Días: ${widget.solicitud.diasSolicitados?.toStringAsFixed(1) ?? '0'} días',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacionController,
                decoration: InputDecoration(
                  labelText: widget.esAprobar
                      ? 'Observaciones (Opcional)'
                      : 'Motivo del Rechazo *',
                  hintText: widget.esAprobar
                      ? 'Ingrese comentarios adicionales...'
                      : 'Ingrese el motivo por el cual rechaza esta solicitud...',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 500,
                validator: (value) {
                  if (!widget.esAprobar && (value == null || value.trim().isEmpty)) {
                    return 'Debe ingresar un motivo para rechazar';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _procesarAccion,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.esAprobar ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(widget.esAprobar ? 'Aprobar' : 'Rechazar'),
        ),
      ],
    );
  }
}

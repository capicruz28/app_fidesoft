// lib/features/vacaciones/presentation/anular_solicitud_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/solicitud_model.dart';
import '../../../../data/services/vacaciones_permisos_service.dart';

class AnularSolicitudDialog extends StatefulWidget {
  final SolicitudModel solicitud;

  const AnularSolicitudDialog({
    super.key,
    required this.solicitud,
  });

  @override
  State<AnularSolicitudDialog> createState() => _AnularSolicitudDialogState();
}

class _AnularSolicitudDialogState extends State<AnularSolicitudDialog> {
  final _motivoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final VacacionesPermisosService _service = VacacionesPermisosService();
  bool _isLoading = false;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _procesarAnulacion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar un motivo de anulación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final solicitudActualizada = await _service.anularSolicitud(
        idSolicitud: widget.solicitud.idSolicitud!,
        motivoAnulacion: _motivoController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, solicitudActualizada);
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
      title: const Text('Anular Solicitud'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Está seguro que desea anular esta solicitud?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.solicitud.tipoSolicitudTexto}: '
                '${DateFormat('dd/MM/yyyy', 'es').format(widget.solicitud.fechaInicio)} - '
                '${DateFormat('dd/MM/yyyy', 'es').format(widget.solicitud.fechaFin)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Días: ${widget.solicitud.diasSolicitados?.toStringAsFixed(1) ?? '0'} días',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo de Anulación *',
                  hintText:
                      'Ingrese el motivo por el cual anula esta solicitud...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 200,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Debe ingresar un motivo de anulación';
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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _procesarAnulacion,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
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
              : const Text('Anular'),
        ),
      ],
    );
  }
}

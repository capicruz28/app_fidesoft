// lib/features/vacaciones/presentation/solicitar_vacaciones_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/vacaciones_permisos_service.dart';
import '../../../../data/models/saldo_vacaciones_model.dart';
import '../../../../core/providers/user_provider.dart';

class SolicitarVacacionesScreen extends StatefulWidget {
  const SolicitarVacacionesScreen({super.key});

  @override
  State<SolicitarVacacionesScreen> createState() => _SolicitarVacacionesScreenState();
}

class _SolicitarVacacionesScreenState extends State<SolicitarVacacionesScreen> {
  final _formKey = GlobalKey<FormState>();
  final VacacionesPermisosService _service = VacacionesPermisosService();
  
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  double? _diasSolicitados;
  final _observacionController = TextEditingController();
  bool _isLoading = false;
  SaldoVacacionesModel? _saldo;

  @override
  void initState() {
    super.initState();
    _cargarSaldo();
  }

  Future<void> _cargarSaldo() async {
    try {
      final saldo = await _service.obtenerMiSaldo();
      setState(() {
        _saldo = saldo;
      });
    } catch (e) {
      // Si hay error, continuamos sin mostrar el saldo
      print('Error al cargar saldo: $e');
    }
  }

  Future<void> _selectFechaInicio() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _fechaInicio = picked;
        if (_fechaFin != null && _fechaFin!.isBefore(_fechaInicio!)) {
          _fechaFin = null;
          _diasSolicitados = null;
        }
        _calcularDias();
      });
    }
  }

  Future<void> _selectFechaFin() async {
    if (_fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero seleccione la fecha de inicio')),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _fechaFin = picked;
        _calcularDias();
      });
    }
  }

  void _calcularDias() {
    if (_fechaInicio != null && _fechaFin != null) {
      final diferencia = _fechaFin!.difference(_fechaInicio!);
      setState(() {
        _diasSolicitados = diferencia.inDays + 1; // +1 para incluir ambos días
      });
    }
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaInicio == null || _fechaFin == null || _diasSolicitados == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todas las fechas')),
      );
      return;
    }

    // Validar saldo disponible
    if (_saldo != null && _diasSolicitados! > _saldo!.saldoDisponible) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Saldo insuficiente'),
          content: Text(
            'Está solicitando $_diasSolicitados días, pero solo tiene ${_saldo!.saldoDisponible.toStringAsFixed(1)} días disponibles.\n\n¿Desea continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final codigoTrabajador = userProvider.currentUser?.strDato1 ?? '';

      if (codigoTrabajador.isEmpty) {
        throw Exception('No se pudo obtener el código de trabajador');
      }

      await _service.solicitarVacaciones(
        codigoTrabajador: codigoTrabajador,
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
        diasSolicitados: _diasSolicitados!,
        observacion: _observacionController.text.isEmpty ? null : _observacionController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud de vacaciones enviada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Retornar true para indicar éxito
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Vacaciones'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card de Saldo Disponible
              if (_saldo != null)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo de Vacaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Días disponibles:'),
                            Text(
                              '${_saldo!.saldoDisponible.toStringAsFixed(1)} días',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total asignado: ${_saldo!.diasAsignadosTotales.toStringAsFixed(1)} días',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        Text(
                          'Días usados: ${_saldo!.diasUsados.toStringAsFixed(1)} días',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Fecha de Inicio
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Fecha de Inicio *',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.event),
                    onPressed: _selectFechaInicio,
                  ),
                ),
                controller: TextEditingController(
                  text: _fechaInicio != null
                      ? DateFormat('dd/MM/yyyy', 'es').format(_fechaInicio!)
                      : '',
                ),
                validator: (value) {
                  if (_fechaInicio == null) {
                    return 'Seleccione la fecha de inicio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fecha de Fin
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Fecha de Fin *',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.event),
                    onPressed: _selectFechaFin,
                  ),
                ),
                controller: TextEditingController(
                  text: _fechaFin != null
                      ? DateFormat('dd/MM/yyyy', 'es').format(_fechaFin!)
                      : '',
                ),
                validator: (value) {
                  if (_fechaFin == null) {
                    return 'Seleccione la fecha de fin';
                  }
                  if (_fechaInicio != null && _fechaFin!.isBefore(_fechaInicio!)) {
                    return 'La fecha de fin debe ser posterior a la fecha de inicio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Días Solicitados (calculado automáticamente)
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Días Solicitados',
                  prefixIcon: Icon(Icons.calculate),
                ),
                controller: TextEditingController(
                  text: _diasSolicitados != null
                      ? '${_diasSolicitados!.toStringAsFixed(1)} días'
                      : '',
                ),
              ),
              const SizedBox(height: 16),

              // Observaciones
              TextFormField(
                controller: _observacionController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (Opcional)',
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Ingrese cualquier comentario adicional...',
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 32),

              // Botón Enviar
              ElevatedButton(
                onPressed: _isLoading ? null : _enviarSolicitud,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'ENVIAR SOLICITUD',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

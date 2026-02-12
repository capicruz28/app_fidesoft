// lib/features/permisos/presentation/solicitar_permiso_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/vacaciones_permisos_service.dart';
import '../../../../data/models/catalogo_model.dart';
import '../../../../core/providers/user_provider.dart';

class SolicitarPermisoScreen extends StatefulWidget {
  const SolicitarPermisoScreen({super.key});

  @override
  State<SolicitarPermisoScreen> createState() => _SolicitarPermisoScreenState();
}

class _SolicitarPermisoScreenState extends State<SolicitarPermisoScreen> {
  final _formKey = GlobalKey<FormState>();
  final VacacionesPermisosService _service = VacacionesPermisosService();
  
  TipoPermisoModel? _tipoPermisoSeleccionado;
  List<TipoPermisoModel> _tiposPermiso = [];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  double? _diasSolicitados;
  final _observacionController = TextEditingController();
  final _motivoController = TextEditingController();
  bool _isLoading = false;
  bool _cargandoCatalogos = true;

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final catalogos = await _service.obtenerCatalogos();
      if (catalogos['tipos_permiso'] != null) {
        setState(() {
          _tiposPermiso = (catalogos['tipos_permiso'] as List)
              .map((json) => TipoPermisoModel.fromJson(json))
              .toList();
          _cargandoCatalogos = false;
        });
      } else {
        // Si no hay catálogo, usar valores por defecto
        setState(() {
          _tiposPermiso = [
            TipoPermisoModel(codigo: '03', descripcion: 'Permiso por enfermedad'),
            TipoPermisoModel(codigo: '04', descripcion: 'Permiso médico'),
            TipoPermisoModel(codigo: '07', descripcion: 'Permiso personal'),
            TipoPermisoModel(codigo: '08', descripcion: 'Permiso sin goce de haber'),
            TipoPermisoModel(codigo: '10', descripcion: 'Permiso por duelo'),
            TipoPermisoModel(codigo: '11', descripcion: 'Otro permiso'),
          ];
          _cargandoCatalogos = false;
        });
      }
    } catch (e) {
      // Si hay error, usar valores por defecto
      setState(() {
        _tiposPermiso = [
          TipoPermisoModel(codigo: '03', descripcion: 'Permiso por enfermedad'),
          TipoPermisoModel(codigo: '04', descripcion: 'Permiso médico'),
          TipoPermisoModel(codigo: '07', descripcion: 'Permiso personal'),
          TipoPermisoModel(codigo: '08', descripcion: 'Permiso sin goce de haber'),
          TipoPermisoModel(codigo: '10', descripcion: 'Permiso por duelo'),
          TipoPermisoModel(codigo: '11', descripcion: 'Otro permiso'),
        ];
        _cargandoCatalogos = false;
      });
      print('Error al cargar catálogos: $e');
    }
  }

  Future<void> _selectFechaInicio() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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

    if (_tipoPermisoSeleccionado == null ||
        _fechaInicio == null ||
        _fechaFin == null ||
        _diasSolicitados == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos requeridos')),
      );
      return;
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

      await _service.solicitarPermiso(
        codigoTrabajador: codigoTrabajador,
        codigoPermiso: _tipoPermisoSeleccionado!.codigo,
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
        diasSolicitados: _diasSolicitados!,
        observacion: _observacionController.text.isEmpty ? null : _observacionController.text,
        motivo: _motivoController.text.isEmpty ? null : _motivoController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud de permiso enviada exitosamente'),
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
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Permiso'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _cargandoCatalogos
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tipo de Permiso
                    DropdownButtonFormField<TipoPermisoModel>(
                      value: _tipoPermisoSeleccionado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Permiso *',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _tiposPermiso.map((tipo) {
                        return DropdownMenuItem<TipoPermisoModel>(
                          value: tipo,
                          child: Text(
                            tipo.descripcion,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return _tiposPermiso.map((tipo) {
                          return Text(
                            tipo.descripcion,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (value) {
                        setState(() {
                          _tipoPermisoSeleccionado = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un tipo de permiso';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

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

                    // Días Solicitados
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

                    // Motivo
                    TextFormField(
                      controller: _motivoController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo (Opcional)',
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Ingrese el motivo del permiso...',
                      ),
                      maxLines: 2,
                      maxLength: 200,
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

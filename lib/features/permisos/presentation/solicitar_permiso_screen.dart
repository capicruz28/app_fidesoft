// lib/features/permisos/presentation/solicitar_permiso_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/module_theme.dart';
import '../../../../data/services/vacaciones_permisos_service.dart';
import '../../../../data/models/catalogo_model.dart';
import '../../../../core/providers/user_provider.dart';

class SolicitarPermisoScreen extends StatefulWidget {
  final Color primaryColor;
  final String title;

  const SolicitarPermisoScreen({
    super.key,
    this.primaryColor = ModuleTheme.permisosPrimary,
    this.title = 'Solicitar Permiso',
  });

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
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  double? _horasSolicitadas;
  final _observacionController = TextEditingController();
  bool _isLoading = false;
  bool _cargandoCatalogos = true;
  String _errorCatalogo = '';

  bool get _esPorHoras => _tipoPermisoSeleccionado?.esPorHoras ?? false;

  String _formatearHora(TimeOfDay hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatearHoraDisplay(TimeOfDay hora) => _formatearHora(hora);

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargandoCatalogos = true;
      _errorCatalogo = '';
    });

    try {
      final catalogos = await _service.obtenerCatalogos();
      final tiposRaw = catalogos['tipos_permiso'];

      if (tiposRaw is! List || tiposRaw.isEmpty) {
        setState(() {
          _tiposPermiso = [];
          _cargandoCatalogos = false;
          _errorCatalogo =
              'No se encontraron tipos de permiso disponibles en el catálogo.';
        });
        return;
      }

      setState(() {
        _tiposPermiso = tiposRaw
            .map((json) => TipoPermisoModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _cargandoCatalogos = false;
      });
    } catch (e) {
      setState(() {
        _tiposPermiso = [];
        _cargandoCatalogos = false;
        _errorCatalogo = 'Error al cargar catálogo de permisos: $e';
      });
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
        if (_esPorHoras) {
          _fechaFin = picked;
        } else if (_fechaFin != null && _fechaFin!.isBefore(_fechaInicio!)) {
          _fechaFin = null;
          _diasSolicitados = null;
        }
        if (_esPorHoras) {
          _diasSolicitados = null;
        } else {
          _calcularDias();
        }
      });
    }
  }

  Future<void> _selectHoraInicio() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _horaInicio = picked;
        if (_horaFin != null) {
          final inicioMin = picked.hour * 60 + picked.minute;
          final finMin = _horaFin!.hour * 60 + _horaFin!.minute;
          if (finMin <= inicioMin) {
            _horaFin = null;
            _horasSolicitadas = null;
          }
        }
        _calcularHoras();
      });
    }
  }

  Future<void> _selectHoraFin() async {
    if (_horaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero seleccione la hora de inicio')),
      );
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _horaFin = picked;
        _calcularHoras();
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
    if (!_esPorHoras && _fechaInicio != null && _fechaFin != null) {
      final diferencia = _fechaFin!.difference(_fechaInicio!);
      setState(() {
        _diasSolicitados = diferencia.inDays + 1;
      });
    }
  }

  void _calcularHoras() {
    if (_horaInicio != null && _horaFin != null) {
      final inicioMin = _horaInicio!.hour * 60 + _horaInicio!.minute;
      final finMin = _horaFin!.hour * 60 + _horaFin!.minute;
      if (finMin <= inicioMin) {
        setState(() {
          _horasSolicitadas = null;
        });
        return;
      }
      setState(() {
        _horasSolicitadas = (finMin - inicioMin) / 60.0;
      });
    }
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tipoPermisoSeleccionado == null || _fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos requeridos')),
      );
      return;
    }

    if (_esPorHoras) {
      if (_horaInicio == null || _horaFin == null || _horasSolicitadas == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor complete las horas de inicio y fin')),
        );
        return;
      }
    } else {
      if (_fechaFin == null || _diasSolicitados == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor complete todos los campos requeridos')),
        );
        return;
      }
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

      if (_esPorHoras) {
        await _service.solicitarPermiso(
          codigoTrabajador: codigoTrabajador,
          codigoPermiso: _tipoPermisoSeleccionado!.codigo,
          fechaInicio: _fechaInicio!,
          fechaFin: _fechaInicio!,
          horaInicio: _formatearHora(_horaInicio!),
          horaFin: _formatearHora(_horaFin!),
          horasSolicitadas: _horasSolicitadas!,
          diasSolicitados: 0,
          observacion: _observacionController.text.isEmpty
              ? null
              : _observacionController.text,
        );
      } else {
        await _service.solicitarPermiso(
          codigoTrabajador: codigoTrabajador,
          codigoPermiso: _tipoPermisoSeleccionado!.codigo,
          fechaInicio: _fechaInicio!,
          fechaFin: _fechaFin!,
          diasSolicitados: _diasSolicitados!,
          observacion: _observacionController.text.isEmpty
              ? null
              : _observacionController.text,
        );
      }

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
      final errorMsg = e.toString().toLowerCase();
      final esSolapamiento = errorMsg.contains('solicitud_fechas_solapadas') ||
          errorMsg.contains('ya existe una solicitud pendiente o aprobada');
      if (esSolapamiento) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No se pudo registrar la solicitud. Ya cuentas con una solicitud '
              'en curso (Pendiente o Aprobada) que se cruza con las fechas '
              'seleccionadas. Si deseas modificar tus días, por favor anula '
              'primero la solicitud anterior desde tu historial.',
              style: TextStyle(color: Colors.white, height: 1.35),
            ),
            backgroundColor: widget.primaryColor,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    final primaryColor = ModuleTheme.resolvePrimaryColor(
      context,
      fallback: widget.primaryColor,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _cargandoCatalogos
          ? const Center(child: CircularProgressIndicator())
          : _errorCatalogo.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          _errorCatalogo,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarCatalogos,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
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
                      onChanged: _tiposPermiso.isEmpty
                          ? null
                          : (value) {
                              setState(() {
                                _tipoPermisoSeleccionado = value;
                                _fechaInicio = null;
                                _fechaFin = null;
                                _diasSolicitados = null;
                                _horaInicio = null;
                                _horaFin = null;
                                _horasSolicitadas = null;
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
                        labelText: _esPorHoras ? 'Fecha *' : 'Fecha de Inicio *',
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
                          return _esPorHoras
                              ? 'Seleccione la fecha'
                              : 'Seleccione la fecha de inicio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    if (!_esPorHoras) ...[
                      // Fecha de Fin (solo modo días)
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
                          if (_fechaInicio != null &&
                              _fechaFin!.isBefore(_fechaInicio!)) {
                            return 'La fecha de fin debe ser posterior a la fecha de inicio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Días Solicitados (solo modo días)
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
                    ],

                    if (_esPorHoras) ...[
                      // Hora de Inicio (modo horas)
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Hora de Inicio *',
                          prefixIcon: const Icon(Icons.access_time),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.schedule),
                            onPressed: _selectHoraInicio,
                          ),
                        ),
                        controller: TextEditingController(
                          text: _horaInicio != null
                              ? _formatearHoraDisplay(_horaInicio!)
                              : '',
                        ),
                        validator: (value) {
                          if (_horaInicio == null) {
                            return 'Seleccione la hora de inicio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Hora de Fin (modo horas)
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Hora de Fin *',
                          prefixIcon: const Icon(Icons.access_time_filled),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.schedule),
                            onPressed: _selectHoraFin,
                          ),
                        ),
                        controller: TextEditingController(
                          text: _horaFin != null
                              ? _formatearHoraDisplay(_horaFin!)
                              : '',
                        ),
                        validator: (value) {
                          if (_horaFin == null) {
                            return 'Seleccione la hora de fin';
                          }
                          if (_horaInicio != null && _horaFin != null) {
                            final inicioMin =
                                _horaInicio!.hour * 60 + _horaInicio!.minute;
                            final finMin = _horaFin!.hour * 60 + _horaFin!.minute;
                            if (finMin <= inicioMin) {
                              return 'La hora de fin debe ser posterior a la de inicio';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Horas Solicitadas (modo horas)
                      TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Horas Solicitadas',
                          prefixIcon: Icon(Icons.timelapse),
                        ),
                        controller: TextEditingController(
                          text: _horasSolicitadas != null
                              ? '${_horasSolicitadas!.toStringAsFixed(1)} horas'
                              : '',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                        backgroundColor: primaryColor,
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

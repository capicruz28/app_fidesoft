// lib/data/models/solicitud_model.dart
import 'dart:convert';

SolicitudModel solicitudModelFromJson(String str) => SolicitudModel.fromJson(json.decode(str));
String solicitudModelToJson(SolicitudModel data) => json.encode(data.toJson());

class SolicitudModel {
  final int? idSolicitud;
  final String tipoSolicitud; // 'V' = Vacaciones, 'P' = Permiso
  final String? codigoPermiso; // NULL si es vacación
  final String codigoTrabajador;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double? diasSolicitados;
  final String? observacion;
  final String? motivo;
  final String estado; // 'P' = Pendiente, 'A' = Aprobado, 'R' = Rechazado, 'N' = Anulado
  final DateTime? fechaRegistro;
  final String? usuarioRegistro;
  final DateTime? fechaModificacion;
  final String? usuarioModificacion;
  final DateTime? fechaAnulacion;
  final String? usuarioAnulacion;
  final String? motivoAnulacion;
  
  // Campos adicionales para la UI
  final String? nombreTrabajador;
  final String? nombrePermiso; // Descripción del permiso
  final List<AprobacionModel>? aprobaciones; // Lista de aprobaciones

  SolicitudModel({
    this.idSolicitud,
    required this.tipoSolicitud,
    this.codigoPermiso,
    required this.codigoTrabajador,
    required this.fechaInicio,
    required this.fechaFin,
    this.diasSolicitados,
    this.observacion,
    this.motivo,
    required this.estado,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.fechaModificacion,
    this.usuarioModificacion,
    this.fechaAnulacion,
    this.usuarioAnulacion,
    this.motivoAnulacion,
    this.nombreTrabajador,
    this.nombrePermiso,
    this.aprobaciones,
  });

  factory SolicitudModel.fromJson(Map<String, dynamic> json) => SolicitudModel(
        idSolicitud: json["id_solicitud"] ?? json["idSolicitud"],
        tipoSolicitud: json["tipo_solicitud"] ?? json["tipoSolicitud"] ?? "",
        codigoPermiso: json["codigo_permiso"] ?? json["codigoPermiso"],
        codigoTrabajador: json["codigo_trabajador"] ?? json["codigoTrabajador"] ?? "",
        fechaInicio: json["fecha_inicio"] != null
            ? DateTime.parse(json["fecha_inicio"])
            : json["fechaInicio"] != null
                ? DateTime.parse(json["fechaInicio"])
                : DateTime.now(),
        fechaFin: json["fecha_fin"] != null
            ? DateTime.parse(json["fecha_fin"])
            : json["fechaFin"] != null
                ? DateTime.parse(json["fechaFin"])
                : DateTime.now(),
        diasSolicitados: json["dias_solicitados"]?.toDouble() ?? json["diasSolicitados"]?.toDouble(),
        observacion: json["observacion"],
        motivo: json["motivo"],
        estado: json["estado"] ?? "P",
        fechaRegistro: json["fecha_registro"] != null
            ? DateTime.parse(json["fecha_registro"])
            : json["fechaRegistro"] != null
                ? DateTime.parse(json["fechaRegistro"])
                : null,
        usuarioRegistro: json["usuario_registro"] ?? json["usuarioRegistro"],
        fechaModificacion: json["fecha_modificacion"] != null
            ? DateTime.parse(json["fecha_modificacion"])
            : json["fechaModificacion"] != null
                ? DateTime.parse(json["fechaModificacion"])
                : null,
        usuarioModificacion: json["usuario_modificacion"] ?? json["usuarioModificacion"],
        fechaAnulacion: json["fecha_anulacion"] != null
            ? DateTime.parse(json["fecha_anulacion"])
            : json["fechaAnulacion"] != null
                ? DateTime.parse(json["fechaAnulacion"])
                : null,
        usuarioAnulacion: json["usuario_anulacion"] ?? json["usuarioAnulacion"],
        motivoAnulacion: json["motivo_anulacion"] ?? json["motivoAnulacion"],
        nombreTrabajador: json["nombre_trabajador"] ?? json["nombreTrabajador"],
        nombrePermiso: json["nombre_permiso"] ?? json["nombrePermiso"],
        aprobaciones: json["aprobaciones"] != null
            ? List<AprobacionModel>.from(
                json["aprobaciones"].map((x) => AprobacionModel.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        "tipo_solicitud": tipoSolicitud,
        "codigo_permiso": codigoPermiso,
        "codigo_trabajador": codigoTrabajador,
        "fecha_inicio": fechaInicio.toIso8601String().split('T')[0],
        "fecha_fin": fechaFin.toIso8601String().split('T')[0],
        "dias_solicitados": diasSolicitados,
        "observacion": observacion,
        "motivo": motivo,
      };

  // Getters útiles para la UI
  String get estadoTexto {
    switch (estado) {
      case 'P':
        return 'Pendiente';
      case 'A':
        return 'Aprobado';
      case 'R':
        return 'Rechazado';
      case 'N':
        return 'Anulado';
      default:
        return 'Desconocido';
    }
  }

  String get tipoSolicitudTexto {
    return tipoSolicitud == 'V' ? 'Vacaciones' : 'Permiso';
  }

  bool get estaPendiente => estado == 'P';
  bool get estaAprobado => estado == 'A';
  bool get estaRechazado => estado == 'R';
  bool get estaAnulado => estado == 'N';
}

// Modelo para Aprobación
class AprobacionModel {
  final int? idAprobacion;
  final int idSolicitud;
  final int nivel;
  final String codigoTrabajadorAprueba;
  final String estado; // 'P' = Pendiente, 'A' = Aprobado, 'R' = Rechazado
  final String? observacion;
  final DateTime? fecha;
  final String? usuario;
  final String? nombreAprobador; // Campo adicional para UI

  AprobacionModel({
    this.idAprobacion,
    required this.idSolicitud,
    required this.nivel,
    required this.codigoTrabajadorAprueba,
    required this.estado,
    this.observacion,
    this.fecha,
    this.usuario,
    this.nombreAprobador,
  });

  factory AprobacionModel.fromJson(Map<String, dynamic> json) => AprobacionModel(
        idAprobacion: json["id_aprobacion"] ?? json["idAprobacion"],
        idSolicitud: json["id_solicitud"] ?? json["idSolicitud"] ?? 0,
        nivel: json["nivel"] ?? 0,
        codigoTrabajadorAprueba: json["codigo_trabajador_aprueba"] ?? json["codigoTrabajadorAprueba"] ?? "",
        estado: json["estado"] ?? "P",
        observacion: json["observacion"],
        fecha: json["fecha"] != null ? DateTime.parse(json["fecha"]) : null,
        usuario: json["usuario"],
        nombreAprobador: json["nombre_aprobador"] ?? json["nombreAprobador"],
      );

  Map<String, dynamic> toJson() => {
        "id_solicitud": idSolicitud,
        "nivel": nivel,
        "codigo_trabajador_aprueba": codigoTrabajadorAprueba,
        "estado": estado,
        "observacion": observacion,
      };

  String get estadoTexto {
    switch (estado) {
      case 'P':
        return 'Pendiente';
      case 'A':
        return 'Aprobado';
      case 'R':
        return 'Rechazado';
      default:
        return 'Desconocido';
    }
  }

  bool get estaPendiente => estado == 'P';
  bool get estaAprobado => estado == 'A';
  bool get estaRechazado => estado == 'R';
}

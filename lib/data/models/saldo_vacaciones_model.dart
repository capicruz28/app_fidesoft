// lib/data/models/saldo_vacaciones_model.dart
import 'dart:convert';

SaldoVacacionesModel saldoVacacionesModelFromJson(String str) => SaldoVacacionesModel.fromJson(json.decode(str));

class SaldoVacacionesModel {
  final String codigoTrabajador;
  final double diasAsignadosTotales;
  final double diasUsados;
  final double diasPendientes;
  final double saldoDisponible;

  SaldoVacacionesModel({
    required this.codigoTrabajador,
    required this.diasAsignadosTotales,
    required this.diasUsados,
    required this.diasPendientes,
    required this.saldoDisponible,
  });

  factory SaldoVacacionesModel.fromJson(Map<String, dynamic> json) => SaldoVacacionesModel(
        codigoTrabajador: json["codigo_trabajador"] ?? json["codigoTrabajador"] ?? "",
        diasAsignadosTotales: (json["dias_asignados_totales"] ?? json["diasAsignadosTotales"] ?? 0.0).toDouble(),
        diasUsados: (json["dias_usados"] ?? json["diasUsados"] ?? 0.0).toDouble(),
        diasPendientes: (json["dias_pendientes"] ?? json["diasPendientes"] ?? 0.0).toDouble(),
        saldoDisponible: (json["saldo_disponible"] ?? json["saldoDisponible"] ?? 0.0).toDouble(),
      );
}

// lib/data/models/document_model.dart
import 'dart:convert';

List<DocumentModel> documentModelListFromJson(String str) =>
    List<DocumentModel>.from(json.decode(str).map((x) => DocumentModel.fromJson(x)));

class DocumentModel {
  final String creguc;
  final String cannos;
  final String cmeses;
  final String ctraba;
  final String ctpref;
  final String dtpref;
  final String ctpdoc;
  final String? strBase64Doc;
  final String nseman;
  /// Número de semana (1-5) cuando la boleta es semanal; null si es boleta del mes.
  final int? semana;
  /// Tipo de documento (para agrupar certificados y otros documentos)
  final String? tipoDocumento;

  // Campo que usaremos para mostrar en el listado
  String get monthName {
    const Map<String, String> months = {
      '01': 'Enero', '02': 'Febrero', '03': 'Marzo', '04': 'Abril',
      '05': 'Mayo', '06': 'Junio', '07': 'Julio', '08': 'Agosto',
      '09': 'Septiembre', '10': 'Octubre', '11': 'Noviembre', '12': 'Diciembre',
    };
    return months[cmeses] ?? 'Mes Desconocido';
  }

  /// Título para listado de boletas: si nseman==0 es del mes; si no, "Semana X, Mes Año".
  String get boletaDisplayTitle {
    if (nseman == '0' || nseman.isEmpty) {
      return 'Boleta - $monthName $cannos';
    }
    final numSemana = semana ?? int.tryParse(nseman) ?? 0;
    return 'Boleta - Semana $numSemana, $monthName $cannos';
  }

  /// Título para listado de certificados CTS: nseman 1=Mayo, 2=Noviembre.
  String get certificadoCtsDisplayTitle {
    if (nseman == '1') return 'Certificado CTS Mayo $cannos';
    if (nseman == '2') return 'Certificado CTS Noviembre $cannos';
    return 'Certificado CTS $cannos';
  }

  DocumentModel({
    required this.creguc,
    required this.cannos,
    required this.cmeses,
    required this.ctraba,
    required this.ctpref,
    required this.dtpref,
    required this.ctpdoc,
    this.strBase64Doc,
    required this.nseman,
    this.semana,
    this.tipoDocumento,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        creguc: json["creguc"]?.trim() ?? "",
        cannos: json["cannos"] ?? "",
        cmeses: json["cmeses"] ?? "",
        ctraba: json["ctraba"] ?? "",
        ctpref: json["ctpref"] ?? "",
        dtpref: json["dtpref"] ?? "",
        ctpdoc: json["ctpdoc"] ?? "",
        strBase64Doc: json["strBase64Doc"],
        nseman: json["nseman"]?.toString() ?? "0",
        semana: json["semana"] is int ? json["semana"] as int : (json["semana"] != null ? int.tryParse(json["semana"].toString()) : null),
        tipoDocumento: json["tipo_documento"]?.toString(),
      );
}
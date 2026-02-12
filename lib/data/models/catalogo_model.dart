// lib/data/models/catalogo_model.dart
import 'dart:convert';

CatalogoModel catalogoModelFromJson(String str) => CatalogoModel.fromJson(json.decode(str));

class CatalogoModel {
  final String codigo;
  final String descripcion;

  CatalogoModel({
    required this.codigo,
    required this.descripcion,
  });

  factory CatalogoModel.fromJson(Map<String, dynamic> json) => CatalogoModel(
        codigo: json["codigo"] ?? json["codigo"] ?? "",
        descripcion: json["descripcion"] ?? json["descripcion"] ?? "",
      );
}

// Modelo para tipos de permiso
class TipoPermisoModel extends CatalogoModel {
  TipoPermisoModel({required super.codigo, required super.descripcion});
  
  factory TipoPermisoModel.fromJson(Map<String, dynamic> json) => TipoPermisoModel(
        codigo: json["codigo"] ?? json["codigo_permiso"] ?? "",
        descripcion: json["descripcion"] ?? json["nombre_permiso"] ?? "",
      );
}

// lib/data/models/user_model.dart
import 'dart:convert';

// Función auxiliar para parsear JSON
UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

// Modelo para la respuesta de Acceso_Usuario
class UserModel {
  final String strMensaje;
  final String strDato1; // cusuar
  final String strDato2; // Nombre del usuario
  final String strDato3; // Algún código/flag (0)
  final int intDato4;    // Algún entero (0)

  UserModel({
    required this.strMensaje,
    required this.strDato1,
    required this.strDato2,
    required this.strDato3,
    required this.intDato4,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        strMensaje: json["strMensaje"] ?? "",
        strDato1: json["strDato1"] ?? "",
        strDato2: json["strDato2"] ?? "",
        strDato3: json["strDato3"] ?? "",
        intDato4: json["intDato4"] ?? 0,
      );
}
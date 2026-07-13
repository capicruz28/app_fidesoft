import 'package:flutter/material.dart';

/// Colores y utilidades de tema por módulo (Vacaciones / Permisos).
abstract final class ModuleTheme {
  static const Color vacacionesPrimary = Color(0xFFFF8282);
  static const Color permisosPrimary = Color(0xFF6A7EFF);

  static Color primaryForTipo(String tipo) =>
      tipo == 'P' ? permisosPrimary : vacacionesPrimary;

  static Color resolvePrimaryColor(
    BuildContext context, {
    required Color fallback,
  }) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['primaryColor'] as Color? ?? fallback;
  }

  static Map<String, dynamic> navigationArgs({
    required Color primaryColor,
    required String title,
  }) =>
      {'primaryColor': primaryColor, 'title': title};
}

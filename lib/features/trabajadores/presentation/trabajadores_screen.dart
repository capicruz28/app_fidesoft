// lib/features/trabajadores/presentation/trabajadores_screen.dart
import 'package:flutter/material.dart';

class TrabajadoresScreen extends StatelessWidget {
  const TrabajadoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recibir los argumentos pasados por la ruta (color y título)
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    final String moduleTitle = args?['title'] as String? ?? 'Trabajadores';
    final Color primaryColor =
        args?['primaryColor'] as Color? ?? const Color(0xFF4CCB9E);
    const Color appBarForeground = Colors.white;

    final Color accentColor = Color.lerp(primaryColor, Colors.black, 0.45)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(moduleTitle),
        backgroundColor: primaryColor,
        foregroundColor: appBarForeground,
        iconTheme: const IconThemeData(color: appBarForeground),
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.5),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Text(
              'Gestión de $moduleTitle',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),

          // Opción: Lista de Trabajadores
          _buildSubmoduleTile(
            context,
            title: 'Trabajadores',
            subtitle:
                'Consulta y gestiona la información de todos los trabajadores.',
            icon: Icons.people_outline,
            route: '/trabajadores/lista',
            color: primaryColor,
            accentColor: accentColor,
          ),
          const SizedBox(height: 15),

          // Opción: Lista de Cumpleaños
          _buildSubmoduleTile(
            context,
            title: 'Cumpleaños',
            subtitle: 'Visualiza los trabajadores que cumplen años hoy.',
            icon: Icons.cake,
            route: '/trabajadores/cumpleanos',
            color: primaryColor,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmoduleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
    required Color color,
    required Color accentColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Icon(icon, size: 28, color: accentColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: accentColor),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}

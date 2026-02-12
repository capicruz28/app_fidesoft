// lib/features/documentos/presentation/documentos_empresa_screen.dart
import 'package:flutter/material.dart';

class DocumentosEmpresaScreen extends StatelessWidget {
  const DocumentosEmpresaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Recibir los argumentos pasados por la ruta (color y título)
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    
    final String moduleTitle = args?['title'] as String? ?? 'Documentos Empresa';
    final Color primaryColor = args?['primaryColor'] as Color? ?? const Color(0xFF9B59B6);
    const Color appBarForeground = Colors.white; 
    
    // Calculamos un color de acento contrastante para el cuerpo
    final Color accentColor = Color.lerp(primaryColor, Colors.black, 0.45)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(moduleTitle),
        backgroundColor: primaryColor, // COLOR DINÁMICO
        foregroundColor: appBarForeground, 
        iconTheme: const IconThemeData(color: appBarForeground), 
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.5),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // Submódulo 1: Reglamentos
          _buildSubmoduleTile(
            context,
            title: 'Reglamentos',
            subtitle: 'Consulta los reglamentos internos y políticas de la empresa.',
            icon: Icons.rule_folder,
            route: '/documentos-empresa/reglamentos',
            color: primaryColor,
            accentColor: accentColor,
            arguments: {
              'primaryColor': primaryColor,
              'title': 'Reglamentos',
            }
          ),
          const SizedBox(height: 15),

          // Submódulo 2: Avisos
          _buildSubmoduleTile(
            context,
            title: 'Avisos',
            subtitle: 'Revisa los avisos y comunicados importantes de la empresa.',
            icon: Icons.announcement,
            route: '/documentos-empresa/avisos',
            color: primaryColor,
            accentColor: accentColor,
            arguments: {
              'primaryColor': primaryColor,
              'title': 'Avisos',
            }
          ),
        ],
      ),
    );
  }

  // Helper para los Sub-módulos (Se mantiene el estilo para consistencia)
  Widget _buildSubmoduleTile(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required String route, 
    required Color color,
    required Color accentColor,
    Map<String, dynamic>? arguments, // Nuevo parámetro para argumentos
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
          )
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: accentColor),
        onTap: () {
          // Pasamos los argumentos a la ruta
          Navigator.pushNamed(context, route, arguments: arguments);
        },
      ),
    );
  }
}

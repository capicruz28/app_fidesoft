// lib/features/documentos/presentation/documentos_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DocumentosScreen extends StatelessWidget {
  const DocumentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Recibir los argumentos pasados por la ruta (color y título)
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    
    final String moduleTitle = args['title'] as String;
    final Color primaryColor = args['primaryColor'] as Color;
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
          /*
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Text(
              'Consulta de $moduleTitle',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          */
          // Submódulo 1: Boletas de pago
          _buildSubmoduleTile(
            context,
            title: 'Boletas de Pago',
            subtitle: 'Visualiza y descarga tus boletas de los últimos periodos.',
            icon: FontAwesomeIcons.fileInvoiceDollar,
            route: '/documentos/boletas', // RUTA DE NIVEL 2
            color: primaryColor,
            accentColor: accentColor,
             // AGREGADO: Pasamos los argumentos necesarios a la siguiente pantalla
            arguments: {
              'primaryColor': primaryColor,
              'title': 'Boletas de Pago',
            }
          ),
          const SizedBox(height: 15),

          // Submódulo 2: Certificados
          _buildSubmoduleTile(
            context,
            title: 'Certificados',
            subtitle: 'Solicita y descarga certificados de trabajo y retenciones.',
            icon: Icons.verified_user_rounded,
            route: '/documentos/certificados', // RUTA DE NIVEL 2
            color: primaryColor,
            accentColor: accentColor,
            arguments: {
              'primaryColor': primaryColor,
              'title': 'Certificados',
            }
          ),
          const SizedBox(height: 15),

          // Submódulo 3: Otros Documentos
          _buildSubmoduleTile(
            context,
            title: 'Otros Documentos',
            subtitle: 'Accede a políticas internas y documentos generales de la empresa.',
            icon: Icons.folder_open_rounded,
            route: '/documentos/otros', // RUTA DE NIVEL 2
            color: primaryColor,
            accentColor: accentColor,
            arguments: {
              'primaryColor': primaryColor,
              'title': 'Otros Documentos',
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
          // MODIFICADO: Pasamos los argumentos a la ruta
          Navigator.pushNamed(context, route, arguments: arguments);
        },
      ),
    );
  }
}
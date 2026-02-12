// lib/features/permisos/presentation/permisos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/services/vacaciones_permisos_service.dart';

class PermisosScreen extends StatefulWidget {
  const PermisosScreen({super.key});

  @override
  State<PermisosScreen> createState() => _PermisosScreenState();
}

class _PermisosScreenState extends State<PermisosScreen> {
  int _pendientesCount = 0;

  @override
  void initState() {
    super.initState();
    _cargarPendientes();
  }

  Future<void> _cargarPendientes() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final esAprobador = await userProvider.esAprobador();
      
      if (esAprobador) {
        final service = VacacionesPermisosService();
        final count = await service.obtenerConteoPendientesPermisos();
        if (mounted) {
          setState(() {
            _pendientesCount = count;
          });
        }
      }
    } catch (e) {
      // Silenciar errores, no mostrar badge si falla
    }
  }

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

          // Submódulo 1: Solicitar Permiso
          _buildSubmoduleTile(
            context,
            title: 'Solicitar Permiso',
            subtitle: 'Registra una nueva solicitud de ausencia o permiso.',
            icon: Icons.edit_calendar_rounded,
            route: '/permisos/solicitar', // RUTA DE NIVEL 2
            color: primaryColor,
            accentColor: accentColor,
          ),
          const SizedBox(height: 15),

          // Submódulo 2: Mis Solicitudes
          _buildSubmoduleTile(
            context,
            title: 'Mis Solicitudes',
            subtitle: 'Consulta el estado y registro de todos tus permisos.',
            icon: Icons.list_alt_rounded,
            route: '/permisos/reporte', // RUTA DE NIVEL 2
            color: primaryColor,
            accentColor: accentColor,
          ),
          const SizedBox(height: 15),

          // Submódulo: Pendientes de Aprobar (solo para aprobadores)
          FutureBuilder<bool>(
            future: Provider.of<UserProvider>(context, listen: false).esAprobador(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return _buildSubmoduleTile(
                  context,
                  title: 'Pendientes de Aprobar',
                  subtitle: 'Revisa y aprueba las solicitudes de permisos pendientes.',
                  icon: Icons.pending_actions,
                  route: '/permisos/pendientes-aprobar',
                  color: primaryColor,
                  accentColor: accentColor,
                  badgeCount: _pendientesCount > 0 ? _pendientesCount : null,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // Helper para los Sub-módulos (Se mantiene igual que VacacionesScreen)
  Widget _buildSubmoduleTile(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required String route, 
    required Color color,
    required Color accentColor,
    int? badgeCount,
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
        trailing: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.arrow_forward_ios, size: 16, color: accentColor),
            // Badge de notificación
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        onTap: () async {
          await Navigator.pushNamed(context, route);
          // Recargar pendientes al volver
          _cargarPendientes();
        },
      ),
    );
  }
}
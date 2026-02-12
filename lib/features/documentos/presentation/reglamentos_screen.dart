// lib/features/documentos/presentation/reglamentos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/services/document_service.dart';
import '../../../data/services/auth_service.dart';
import 'pdf_viewer_screen.dart';

class ReglamentosScreen extends StatefulWidget {
  final Color primaryColor;
  final String title;
  
  const ReglamentosScreen({
    super.key, 
    this.primaryColor = const Color(0xFF9B59B6),
    this.title = 'Reglamentos',
  });

  @override
  State<ReglamentosScreen> createState() => _ReglamentosScreenState();
}

class _ReglamentosScreenState extends State<ReglamentosScreen> {
  final DocumentService _documentService = DocumentService();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _reglamentos = [];
  Map<String, List<Map<String, dynamic>>> _reglamentosByType = {};

  @override
  void initState() {
    super.initState();
    _loadReglamentos();
  }

  Future<void> _loadReglamentos() async {
    setState(() {
      _isLoading = true;
      _reglamentos = [];
      _reglamentosByType = {};
    });

    try {
      final resultados = await _documentService.obtenerReglamentos();
      final Map<String, List<Map<String, dynamic>>> groupedByType = {};
      
      for (final item in resultados) {
        final tipoDoc = (item['tipo_documento'] ?? '').toString();
        final tipoKey = tipoDoc.isEmpty ? 'Sin tipo' : tipoDoc;
        if (!groupedByType.containsKey(tipoKey)) {
          groupedByType[tipoKey] = [];
        }
        groupedByType[tipoKey]!.add(item);
      }

      setState(() {
        _reglamentos = resultados;
        _reglamentosByType = groupedByType;
      });
      
    } catch (e) {
      final errMsg = e.toString();
      if (errMsg.contains('SESSION_EXPIRED')) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.logout();
        final authService = AuthService();
        await authService.logout();
        await authService.clearSavedCredentials();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }
      _showSnackBar('Error: ${errMsg.replaceAll("Exception: ", "")}', Colors.red);
      _reglamentos = [];
      _reglamentosByType = {};
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _viewReglamentoPdf(Map<String, dynamic> reglamento, Color primaryColor) async {
    final base64 = reglamento['archivo_pdf_base64'] as String?;
    if (base64 == null || base64.isEmpty) {
      _showSnackBar('El documento no tiene archivo PDF disponible.', Colors.red);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          base64Pdf: base64,
          title: reglamento['descripcion'] ?? reglamento['nombre_archivo'] ?? 'Reglamento',
          primaryColor: primaryColor,
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final dynamicAppBarColor = arguments?['primaryColor'] as Color? ?? widget.primaryColor;
    final String screenTitle = arguments?['title'] as String? ?? widget.title;
    final primaryColor = dynamicAppBarColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadReglamentos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildReglamentosList(primaryColor),
    );
  }
  
  Widget _buildReglamentosList(Color primaryColor) {
    if (_isLoading && _reglamentos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reglamentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rule_folder, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No se encontraron reglamentos.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    if (_reglamentosByType.isNotEmpty && _reglamentosByType.length > 1) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        itemCount: _reglamentosByType.length,
        itemBuilder: (context, groupIndex) {
          final tipoKey = _reglamentosByType.keys.elementAt(groupIndex);
          final items = _reglamentosByType[tipoKey]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Text(
                  tipoKey,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              ...items.map((item) => Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    radius: 24,
                    child: Icon(Icons.rule_folder, color: primaryColor, size: 18),
                  ),
                  title: Text(
                    item['descripcion'] ?? item['nombre_archivo'] ?? 'Reglamento',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: item['nombre_archivo'] != null && item['nombre_archivo'] != item['descripcion']
                      ? Text(
                          item['nombre_archivo'],
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: _isLoading ? null : () => _viewReglamentoPdf(item, primaryColor),
                ),
              )),
            ],
          );
        },
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      itemCount: _reglamentos.length,
      itemBuilder: (context, index) {
        final item = _reglamentos[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            leading: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              radius: 24,
              child: Icon(Icons.rule_folder, color: primaryColor, size: 18),
            ),
            title: Text(
              item['descripcion'] ?? item['nombre_archivo'] ?? 'Reglamento',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: item['nombre_archivo'] != null && item['nombre_archivo'] != item['descripcion']
                ? Text(
                    item['nombre_archivo'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: _isLoading ? null : () => _viewReglamentoPdf(item, primaryColor),
          ),
        );
      },
    );
  }
}

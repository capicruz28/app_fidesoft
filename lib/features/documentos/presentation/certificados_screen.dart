// lib/features/documentos/presentation/certificados_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/document_model.dart';
import '../../../data/services/document_service.dart';
import '../../../data/services/auth_service.dart';
import 'pdf_viewer_screen.dart';

class CertificadosScreen extends StatefulWidget {
  final Color primaryColor;
  final String title;
  
  const CertificadosScreen({
    super.key, 
    this.primaryColor = const Color(0xFF0D47A1),
    this.title = 'Certificados',
  });

  @override
  State<CertificadosScreen> createState() => _CertificadosScreenState();
}

class _CertificadosScreenState extends State<CertificadosScreen> {
  final DocumentService _documentService = DocumentService();
  
  String? _selectedYear;
  bool _isLoading = false;
  List<DocumentModel> _certificates = [];
  // Mapa para agrupar certificados por tipo_documento
  Map<String, List<DocumentModel>> _certificatesByType = {};

  @override
  void initState() {
    super.initState();
    // Inicializar con el año más reciente de las opciones
    _selectedYear = _yearOptions.first;
  }

  // Genera opciones de año (últimos 5 años)
  List<String> get _yearOptions {
    final currentYear = DateTime.now().year;
    return List<String>.generate(5, (i) => (currentYear - i).toString());
  }

  // Función de búsqueda de certificados CTS usando el nuevo endpoint
  Future<void> _searchCertificates() async {
    if (_selectedYear == null) {
      _showSnackBar('Debe seleccionar un Año.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
      _certificates = [];
    });

    try {
      // Usar el nuevo endpoint (devuelve lista en "items": Mayo y/o Noviembre)
      final resultados = await _documentService.obtenerCertificadosCTS(
        anio: _selectedYear!,
      );

      final List<DocumentModel> docs = [];
      final Map<String, List<DocumentModel>> groupedByType = {};
      
      for (final resultado in resultados) {
        final nseman = resultado['nseman'] as String? ?? '0';
        final tipoDoc = (resultado['tipo_documento'] ?? '').toString();
        final mesCts = nseman == '1' ? '05' : (nseman == '2' ? '11' : (resultado['mes'] ?? '12'));
        final tituloCts = nseman == '1' ? 'Certificado CTS Mayo $_selectedYear' : (nseman == '2' ? 'Certificado CTS Noviembre $_selectedYear' : 'Certificado CTS $_selectedYear');
        final doc = DocumentModel(
          creguc: '',
          cannos: _selectedYear!,
          cmeses: mesCts,
          ctraba: resultado['codigo_trabajador'] ?? '',
          ctpref: 'CTS',
          dtpref: tituloCts,
          ctpdoc: 'C',
          strBase64Doc: resultado['archivo_pdf_base64'] as String?,
          nseman: nseman,
          tipoDocumento: tipoDoc,
        );
        docs.add(doc);
        
        // Agrupar por tipo_documento
        final tipoKey = tipoDoc.isEmpty ? 'Sin tipo' : tipoDoc;
        if (!groupedByType.containsKey(tipoKey)) {
          groupedByType[tipoKey] = [];
        }
        groupedByType[tipoKey]!.add(doc);
      }

      setState(() {
        _certificates = docs;
        _certificatesByType = groupedByType;
      });

      _showSnackBar('Certificados CTS de $_selectedYear: ${docs.length} obtenido(s).', Colors.green);
      
    } catch (e) {
      final errMsg = e.toString();
      if (errMsg.contains('SESSION_EXPIRED')) {
        // Manejar sesión expirada
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
      _certificates = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Función para ver el PDF del certificado
  Future<void> _viewCertificatePdf(DocumentModel doc, Color primaryColor) async {
    DocumentModel docToShow = doc;
    if (doc.strBase64Doc == null || doc.strBase64Doc!.isEmpty) {
      setState(() => _isLoading = true);
      try {
        final resultados = await _documentService.obtenerCertificadosCTS(anio: doc.cannos);
        Map<String, dynamic>? match;
        for (final m in resultados) {
          if ((m['nseman']?.toString() ?? '0') == doc.nseman) {
            match = m;
            break;
          }
        }
        match ??= resultados.isNotEmpty ? resultados.first : null;
        if (match != null) {
          final nseman = match['nseman'] as String? ?? '0';
          final tipoDoc = (match['tipo_documento'] ?? '').toString();
          final mesCts = nseman == '1' ? '05' : (nseman == '2' ? '11' : doc.cmeses);
          final tituloCts = nseman == '1' ? 'Certificado CTS Mayo ${doc.cannos}' : (nseman == '2' ? 'Certificado CTS Noviembre ${doc.cannos}' : 'Certificado CTS ${doc.cannos}');
          docToShow = DocumentModel(
            creguc: doc.creguc,
            cannos: doc.cannos,
            cmeses: mesCts,
            ctraba: doc.ctraba,
            ctpref: doc.ctpref,
            dtpref: tituloCts,
            ctpdoc: doc.ctpdoc,
            strBase64Doc: match['archivo_pdf_base64'] as String?,
            nseman: nseman,
            tipoDocumento: tipoDoc,
          );
        }
      } catch (e) {
        _showSnackBar('No se pudo obtener el PDF: ${e.toString().replaceAll("Exception: ", "")}', Colors.red);
        setState(() => _isLoading = false);
        return;
      } finally {
        setState(() => _isLoading = false);
      }
    }

    if (!mounted || docToShow.strBase64Doc == null || docToShow.strBase64Doc!.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          base64Pdf: docToShow.strBase64Doc!,
          title: docToShow.certificadoCtsDisplayTitle,
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
    // Obtener color y título de los argumentos de navegación si existen
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final dynamicAppBarColor = arguments?['primaryColor'] as Color? ?? widget.primaryColor;
    final String screenTitle = arguments?['title'] as String? ?? widget.title;

    final primaryColor = dynamicAppBarColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- Controles de Búsqueda ---
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                // Dropdown Año
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Año',
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    isDense: false,
                  ),
                  value: _selectedYear,
                  items: _yearOptions.map((year) => DropdownMenuItem(
                    value: year,
                    child: Text(year, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value;
                      _certificates = []; // Limpiar resultados anteriores
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Botón de búsqueda a ancho completo
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading || _selectedYear == null ? null : _searchCertificates,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 3,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.search, size: 22),
                              SizedBox(width: 8),
                              Text('Buscar Certificados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          
          // --- Listado de Certificados ---
          Expanded(
            child: _buildCertificateList(primaryColor),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCertificateList(Color primaryColor) {
    if (_isLoading && _certificates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_certificates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              _selectedYear == null 
                  ? 'Seleccione un año para buscar.'
                  : 'No se encontraron certificados para el año $_selectedYear.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Si hay agrupación por tipo, mostrar agrupados
    if (_certificatesByType.isNotEmpty && _certificatesByType.length > 1) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        itemCount: _certificatesByType.length,
        itemBuilder: (context, groupIndex) {
          final tipoKey = _certificatesByType.keys.elementAt(groupIndex);
          final docs = _certificatesByType[tipoKey]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado del grupo
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
              // Lista de certificados del grupo
              ...docs.map((doc) => Card(
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
                    child: Icon(Icons.description, color: primaryColor, size: 18),
                  ),
                  title: Text(
                    doc.certificadoCtsDisplayTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    doc.nseman == '1' ? 'Mayo ${doc.cannos}' : (doc.nseman == '2' ? 'Noviembre ${doc.cannos}' : 'Año ${doc.cannos}'),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: _isLoading ? null : () => _viewCertificatePdf(doc, primaryColor),
                ),
              )),
            ],
          );
        },
      );
    }
    
    // Si no hay agrupación o solo hay un tipo, mostrar lista simple
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      itemCount: _certificates.length,
      itemBuilder: (context, index) {
        final doc = _certificates[index];
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
              child: Icon(Icons.description, color: primaryColor, size: 18),
            ),
            title: Text(
              doc.certificadoCtsDisplayTitle,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              doc.nseman == '1' ? 'Mayo ${doc.cannos}' : (doc.nseman == '2' ? 'Noviembre ${doc.cannos}' : 'Año ${doc.cannos}'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: _isLoading ? null : () => _viewCertificatePdf(doc, primaryColor),
          ),
        );
      },
    );
  }
}
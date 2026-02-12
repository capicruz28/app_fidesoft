// lib/features/documentos/presentation/otros_documentos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/document_model.dart';
import '../../../data/services/document_service.dart';
import '../../../data/services/auth_service.dart';
import 'pdf_viewer_screen.dart';

class OtrosDocumentosScreen extends StatefulWidget {
  final Color primaryColor;
  final String title;
  
  const OtrosDocumentosScreen({
    super.key, 
    this.primaryColor = const Color(0xFF0D47A1),
    this.title = 'Otros Documentos',
  });

  @override
  State<OtrosDocumentosScreen> createState() => _OtrosDocumentosScreenState();
}

class _OtrosDocumentosScreenState extends State<OtrosDocumentosScreen> {
  final DocumentService _documentService = DocumentService();
  
  String? _selectedYear;
  String? _selectedMonth;
  bool _isLoading = false;
  List<DocumentModel> _documentos = [];
  Map<String, List<DocumentModel>> _documentosByType = {};

  @override
  void initState() {
    super.initState();
    _selectedYear = _yearOptions.first;
  }

  List<String> get _yearOptions {
    final currentYear = DateTime.now().year;
    return List<String>.generate(5, (i) => (currentYear - i).toString());
  }

  final List<String> _monthOptions = const [
    '01', '02', '03', '04', '05', '06', 
    '07', '08', '09', '10', '11', '12',
  ];

  String _getMonthName(String monthNumber) {
    final doc = DocumentModel(
      creguc: '', cannos: '', cmeses: monthNumber, ctraba: '', 
      ctpref: '', dtpref: '', ctpdoc: '', nseman: '0',
    );
    return doc.monthName;
  }

  Future<void> _searchDocumentos() async {
    if (_selectedYear == null) {
      _showSnackBar('Debe seleccionar un Año.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
      _documentos = [];
      _documentosByType = {};
    });

    try {
      final resultados = await _documentService.obtenerOtrosDocumentos(
        anio: _selectedYear!,
        mes: _selectedMonth,
      );

      final List<DocumentModel> docs = [];
      final Map<String, List<DocumentModel>> groupedByType = {};
      
      for (final resultado in resultados) {
        final itemMes = (resultado['mes'] ?? '').toString();
        final nseman = resultado['nseman'] as String? ?? '0';
        final semana = resultado['semana'] as int?;
        final tipoDoc = (resultado['tipo_documento'] ?? '').toString();
        final mesNombre = itemMes.isEmpty ? '' : _getMonthName(itemMes);
        final titulo = nseman == '0'
            ? tipoDoc.isEmpty ? 'Documento - $mesNombre $_selectedYear' : '$tipoDoc - $mesNombre $_selectedYear'
            : tipoDoc.isEmpty ? 'Documento - Semana ${semana ?? nseman}, $mesNombre $_selectedYear' : '$tipoDoc - Semana ${semana ?? nseman}, $mesNombre $_selectedYear';
        final doc = DocumentModel(
          creguc: '',
          cannos: _selectedYear!,
          cmeses: itemMes.isEmpty ? (_selectedMonth ?? '') : itemMes,
          ctraba: resultado['codigo_trabajador'] ?? '',
          ctpref: 'OD',
          dtpref: titulo,
          ctpdoc: 'O',
          strBase64Doc: resultado['archivo_pdf_base64'] as String?,
          nseman: nseman,
          semana: semana,
          tipoDocumento: tipoDoc,
        );
        docs.add(doc);
        
        final tipoKey = tipoDoc.isEmpty ? 'Sin tipo' : tipoDoc;
        if (!groupedByType.containsKey(tipoKey)) {
          groupedByType[tipoKey] = [];
        }
        groupedByType[tipoKey]!.add(doc);
      }

      setState(() {
        _documentos = docs;
        _documentosByType = groupedByType;
      });

      final msg = _selectedMonth == null || _selectedMonth!.isEmpty
          ? 'Documentos de $_selectedYear (año completo): ${docs.length} obtenido(s).'
          : 'Documentos de ${_getMonthName(_selectedMonth!)} $_selectedYear: ${docs.length} obtenido(s).';
      _showSnackBar(msg, Colors.green);
      
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
      _documentos = [];
      _documentosByType = {};
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _viewDocumentoPdf(DocumentModel doc, Color primaryColor) async {
    DocumentModel docToShow = doc;
    if (doc.strBase64Doc == null || doc.strBase64Doc!.isEmpty) {
      setState(() => _isLoading = true);
      try {
        final resultados = await _documentService.obtenerOtrosDocumentos(
          anio: doc.cannos,
          mes: doc.cmeses.isEmpty ? null : doc.cmeses,
        );
        Map<String, dynamic>? match;
        for (final m in resultados) {
          final mNseman = m['nseman']?.toString() ?? '0';
          final mSemana = m['semana'] is int ? m['semana'] as int : (m['semana'] != null ? int.tryParse(m['semana'].toString()) : null);
          final mTipoDoc = (m['tipo_documento'] ?? '').toString();
          if (mNseman == doc.nseman && 
              (doc.semana == null || mSemana == doc.semana) &&
              (doc.tipoDocumento == null || mTipoDoc == doc.tipoDocumento)) {
            match = m;
            break;
          }
        }
        match ??= resultados.isNotEmpty ? resultados.first : null;
        if (match != null) {
          final nseman = match['nseman'] as String? ?? '0';
          final semana = match['semana'] as int?;
          final tipoDoc = (match['tipo_documento'] ?? '').toString();
          docToShow = DocumentModel(
            creguc: doc.creguc,
            cannos: doc.cannos,
            cmeses: doc.cmeses,
            ctraba: doc.ctraba,
            ctpref: doc.ctpref,
            dtpref: doc.dtpref,
            ctpdoc: doc.ctpdoc,
            strBase64Doc: match['archivo_pdf_base64'] as String?,
            nseman: nseman,
            semana: semana,
            tipoDocumento: tipoDoc,
          );
        } else {
          _showSnackBar('No se encontró el PDF de este documento.', Colors.red);
        }
      } catch (e) {
        _showSnackBar('No se pudo obtener el PDF: ${e.toString().replaceAll("Exception: ", "")}', Colors.red);
        setState(() => _isLoading = false);
        return;
      } finally {
        setState(() => _isLoading = false);
      }
    }

    if (!mounted || docToShow.strBase64Doc == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          base64Pdf: docToShow.strBase64Doc!,
          title: docToShow.dtpref,
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
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
                            _selectedMonth = null; 
                            _documentos = [];
                            _documentosByType = {};
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Mes',
                          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.calendar_view_month, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          isDense: false,
                        ),
                        value: _selectedMonth,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todo el año', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          ..._monthOptions.map((month) => DropdownMenuItem<String?>(
                            value: month,
                            child: Text(
                              _getMonthName(month),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                        ],
                        onChanged: (_selectedYear == null) ? null : (value) {
                          setState(() {
                            _selectedMonth = value;
                            _documentos = [];
                            _documentosByType = {};
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading || _selectedYear == null ? null : _searchDocumentos,
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
                              Text('Buscar Documentos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildDocumentosList(primaryColor),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDocumentosList(Color primaryColor) {
    if (_isLoading && _documentos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_documentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              _selectedYear == null 
                  ? 'Seleccione un año para buscar.'
                  : 'No se encontraron documentos.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    if (_documentosByType.isNotEmpty && _documentosByType.length > 1) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        itemCount: _documentosByType.length,
        itemBuilder: (context, groupIndex) {
          final tipoKey = _documentosByType.keys.elementAt(groupIndex);
          final docs = _documentosByType[tipoKey]!;
          
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
                    doc.dtpref,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: _isLoading ? null : () => _viewDocumentoPdf(doc, primaryColor),
                ),
              )),
            ],
          );
        },
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      itemCount: _documentos.length,
      itemBuilder: (context, index) {
        final doc = _documentos[index];
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
              doc.dtpref,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: _isLoading ? null : () => _viewDocumentoPdf(doc, primaryColor),
          ),
        );
      },
    );
  }
}

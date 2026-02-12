// lib/features/documents/presentation/boletas_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/document_model.dart';
import '../../../data/services/document_service.dart';
import '../../../data/services/auth_service.dart';
import 'pdf_viewer_screen.dart';

class PayslipsScreen extends StatefulWidget {
  final Color primaryColor;
  final String title;
  
  const PayslipsScreen({
    super.key, 
    this.primaryColor = const Color(0xFF0D47A1),
    this.title = 'Boletas de Pago',
  });

  @override
  State<PayslipsScreen> createState() => _PayslipsScreenState();
}

class _PayslipsScreenState extends State<PayslipsScreen> {
  final DocumentService _documentService = DocumentService();
  
  String? _selectedYear;
  String? _selectedMonth;
  bool _isLoading = false;
  List<DocumentModel> _payslips = [];

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

  // Opciones de mes en formato de dos dígitos
  final List<String> _monthOptions = const [
    '01', '02', '03', '04', '05', '06', 
    '07', '08', '09', '10', '11', '12',
  ];

  // Obtiene el nombre del mes usando el getter del modelo
  String _getMonthName(String monthNumber) {
    final doc = DocumentModel(
      creguc: '', cannos: '', cmeses: monthNumber, ctraba: '', 
      ctpref: '', dtpref: '', ctpdoc: '', nseman: '0',
    );
    return doc.monthName;
  }

  // Función de búsqueda usando el nuevo endpoint (por año solo o año + mes)
  Future<void> _searchPayslips() async {
    if (_selectedYear == null) {
      _showSnackBar('Debe seleccionar un Año.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
      _payslips = [];
    });

    try {
      // Sin mes = todo el año (GET ?anio=2025); con mes = GET ?anio=2025&mes=07
      final resultados = await _documentService.obtenerBoletasPago(
        anio: _selectedYear!,
        mes: _selectedMonth,
      );

      final List<DocumentModel> docs = [];
      for (final resultado in resultados) {
        final itemMes = (resultado['mes'] ?? '').toString();
        final nseman = resultado['nseman'] as String? ?? '0';
        final semana = resultado['semana'] as int?;
        final mesNombre = itemMes.isEmpty ? '' : _getMonthName(itemMes);
        final titulo = nseman == '0'
            ? 'Boleta - $mesNombre $_selectedYear'
            : 'Boleta - Semana ${semana ?? nseman}, $mesNombre $_selectedYear';
        docs.add(DocumentModel(
          creguc: '',
          cannos: _selectedYear!,
          cmeses: itemMes.isEmpty ? (_selectedMonth ?? '') : itemMes,
          ctraba: resultado['codigo_trabajador'] ?? '',
          ctpref: 'BO',
          dtpref: titulo,
          ctpdoc: 'B',
          strBase64Doc: resultado['archivo_pdf_base64'] as String?,
          nseman: nseman,
          semana: semana,
        ));
      }

      setState(() {
        _payslips = docs;
      });

      final msg = _selectedMonth == null || _selectedMonth!.isEmpty
          ? 'Boletas de $_selectedYear (año completo): ${docs.length} obtenida(s).'
          : 'Boletas de ${_getMonthName(_selectedMonth!)} $_selectedYear: ${docs.length} obtenida(s).';
      _showSnackBar(msg, Colors.green);
      
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
      _payslips = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- FUNCIÓN CLAVE: Obtiene el PDF y Navega ---
  Future<void> _viewPayslipPdf(DocumentModel doc, Color primaryColor) async {
    DocumentModel docToShow = doc;
    if (doc.strBase64Doc == null || doc.strBase64Doc!.isEmpty) {
      setState(() => _isLoading = true);
      try {
        final resultados = await _documentService.obtenerBoletasPago(
          anio: doc.cannos,
          mes: doc.cmeses,
        );
        Map<String, dynamic>? match;
        for (final m in resultados) {
          final mNseman = m['nseman']?.toString() ?? '0';
          final mSemana = m['semana'] is int ? m['semana'] as int : (m['semana'] != null ? int.tryParse(m['semana'].toString()) : null);
          if (mNseman == doc.nseman && (doc.semana == null || mSemana == doc.semana)) {
            match = m;
            break;
          }
        }
        match ??= resultados.isNotEmpty ? resultados.first : null;
        if (match != null) {
          final nseman = match['nseman'] as String? ?? '0';
          final semana = match['semana'] as int?;
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
          );
        } else {
          _showSnackBar('No se encontró el PDF de esta boleta.', Colors.red);
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
          title: docToShow.boletaDisplayTitle,
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
                // Primera fila: Año y Mes
                Row(
                  children: [
                    // Dropdown Año
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
                            _payslips = []; 
                          });
                        },
                        validator: (value) => value == null ? 'Año' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Dropdown Mes (opcional: "Todo el año" o un mes concreto)
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
                            _payslips = [];
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Segunda fila: Botón de búsqueda a ancho completo
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading || _selectedYear == null ? null : _searchPayslips,
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
                              Text('Buscar Boletas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          
          // --- Listado de Boletas ---
          Expanded(
            child: _buildPayslipList(primaryColor),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPayslipList(Color primaryColor) {
    if (_isLoading && _payslips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_payslips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              _selectedYear == null 
                  ? 'Seleccione un año para buscar.'
                  : 'No se encontraron boletas para la búsqueda actual.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      itemCount: _payslips.length,
      itemBuilder: (context, index) {
        final doc = _payslips[index];
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
              child: Icon(Icons.picture_as_pdf, color: primaryColor, size: 18),
            ),
            title: Text(
              doc.boletaDisplayTitle,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              doc.nseman == '0' ? '${doc.monthName} ${doc.cannos}' : 'Semana ${doc.semana ?? doc.nseman} · ${doc.monthName} ${doc.cannos}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            // --- Conexión a la función de visualización del PDF ---
            onTap: _isLoading ? null : () => _viewPayslipPdf(doc, primaryColor),
          ),
        );
      },
    );
  }
}

import 'dart:async'; // Importamos Future, etc.
import 'dart:convert';
import 'dart:io'; // Para manejar archivos
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // PAQUETE REQUERIDO: services (Para SystemUiOverlayStyle)
import 'package:pdfx/pdfx.dart'; 
import 'package:path_provider/path_provider.dart'; // PAQUETE REQUERIDO: path_provider
import 'package:share_plus/share_plus.dart';         // PAQUETE REQUERIDO: share_plus

class PdfViewerScreen extends StatefulWidget {
  final String base64Pdf;
  final String title;
  final Color primaryColor;

  const PdfViewerScreen({
    super.key,
    required this.base64Pdf,
    required this.title,
    this.primaryColor = const Color(0xFF0D47A1),
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late Future<PdfControllerPinch> _pdfControllerFuture;
  late Uint8List _pdfBytes; // Almacenamos los bytes decodificados aquí
  bool _isSavingOrSharing = false;

  @override
  void initState() {
    super.initState();
    _pdfControllerFuture = _initializePdfController();
  }

  Future<PdfControllerPinch> _initializePdfController() async {
    try {
      if (widget.base64Pdf.isEmpty) {
        throw Exception("La cadena Base64 está vacía.");
      }
      
      // Decodificar Base64 a bytes y guardarlos en el estado
      _pdfBytes = base64Decode(widget.base64Pdf);
      
      if (_pdfBytes.isEmpty) {
        throw Exception("Los datos decodificados están vacíos.");
      }

      // Usar openData que funciona bien con la arquitectura Future/Async
      final Future<PdfDocument> pdfDocumentFuture = PdfDocument.openData(_pdfBytes);
      
      // Retornar el controlador con el Future
      return PdfControllerPinch(
        document: pdfDocumentFuture,
      );

    } on FormatException catch (e) {
      print('Error de formato Base64: ${e.message}');
      throw Exception('Error de formato Base64: Asegúrese de que la cadena sea válida.');
    } catch (e) {
      print('Error al cargar PDF: ${e.toString()}');
      throw Exception('Error al cargar PDF: Verifique la conexión o el formato.');
    }
  }

  // --- Lógica de Guardar y Compartir ---

  Future<void> _savePdfToDevice() async {
    if (_isSavingOrSharing || _pdfBytes.isEmpty) return;

    setState(() => _isSavingOrSharing = true);
    try {
      // 1. Obtener el directorio de almacenamiento temporal o de documentos
      final directory = await getTemporaryDirectory(); 
      // Creamos un nombre de archivo único o basado en el título
      final fileName = '${widget.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      // 2. Escribir los bytes decodificados en el archivo
      await file.writeAsBytes(_pdfBytes, flush: true);

      if (!mounted) return;

      // 3. Mostrar confirmación (se puede usar un paquete como fluttertoast si lo prefieres)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Documento guardado temporalmente en: ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
      // Nota: Para guardado permanente visible por el usuario (Galería/Descargas),
      // se recomienda el paquete 'image_gallery_saver' o 'permission_handler' y 'path_provider'
      // para manejar los permisos y rutas específicos de la plataforma.

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSavingOrSharing = false);
    }
  }

  Future<void> _sharePdf() async {
    if (_isSavingOrSharing || _pdfBytes.isEmpty) return;
    
    setState(() => _isSavingOrSharing = true);
    try {
      // 1. Guardar el archivo en una ubicación temporal (necesario para Share.shareXFiles)
      final directory = await getTemporaryDirectory();
      final fileName = '${widget.title.replaceAll(' ', '_')}_share.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(_pdfBytes, flush: true);

      // 2. Usar share_plus para compartir el archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: widget.title,
        text: 'Compartiendo el documento: ${widget.title}',
      );      

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al compartir: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Importante: No borramos el archivo de inmediato, Share_plus lo necesita
      setState(() => _isSavingOrSharing = false);
    }
  }

  // --- Widgets Auxiliares ---

  Widget _buildErrorWidget(Color color, String errorMessage) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el documento',
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage.contains('Exception:') ? errorMessage.split('Exception: ')[1].trim() : errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  // Reiniciar el Future para reintentar la carga
                  _pdfControllerFuture = _initializePdfController();
                });
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: color,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando documento...',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer(PdfControllerPinch controller) {
    return PdfViewPinch(
      controller: controller,
      scrollDirection: Axis.vertical,
    );
  }

  // --- Build Principal ---

  @override
  Widget build(BuildContext context) {
    final Color color = widget.primaryColor;
    
    // 1. Determinar si el color de fondo es oscuro o claro para la barra de estado
    final Brightness brightness = ThemeData.estimateBrightnessForColor(color);
    
    // NUEVO: Determinar el color del texto/iconos (blanco o negro) en la AppBar
    final Color appBarContentColor = brightness == Brightness.dark ? Colors.white : Colors.black;

    // 2. Configurar el SystemUiOverlayStyle para que los íconos del sistema contrasten con el color de la AppBar
    final SystemUiOverlayStyle systemStyle = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light.copyWith(statusBarColor: color)
        : SystemUiOverlayStyle.dark.copyWith(statusBarColor: color);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: color, // Aplica el primaryColor al fondo de la AppBar
        foregroundColor: appBarContentColor, // AHORA DINÁMICO: Asegura contraste
        elevation: 0,
        systemOverlayStyle: systemStyle, // Aplica el estilo del sistema para la consistencia
        actions: [
          // Botón de Compartir
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _pdfBytes.isEmpty ? null : _sharePdf,
            tooltip: 'Compartir Documento',
          ),
          // Botón de Descargar
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _pdfBytes.isEmpty ? null : _savePdfToDevice,
            tooltip: 'Guardar Documento',
          ),
          // Indicador de actividad
          if (_isSavingOrSharing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<PdfControllerPinch>(
        future: _pdfControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget(color);
          }
          
          if (snapshot.hasError) {
            return _buildErrorWidget(
              color,
              snapshot.error.toString(),
            );
          }
          
          if (snapshot.hasData) {
            return _buildPdfViewer(snapshot.data!);
          }
          
          return _buildErrorWidget(color, 'Estado desconocido');
        },
      ),
    );
  }
}

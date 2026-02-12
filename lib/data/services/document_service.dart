// lib/data/services/document_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DocumentService {
  // Base URL del nuevo API
  final String baseUrlNuevo = 'http://170.231.171.118:9096/api/v1';
  
  /// Obtener token de autenticación
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Obtener Boletas de Pago (puede devolver varias: por mes y/o por semana).
  /// Sin mes: GET .../boleta-pago?anio=2025 (todas las boletas del año).
  /// Con mes: GET .../boleta-pago?anio=2025&mes=07.
  /// La API puede devolver { "items": [ {...}, {...} ] } o un solo objeto.
  Future<List<Map<String, dynamic>>> obtenerBoletasPago({
    required String anio,
    String? mes,
  }) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación');
    }

    final queryParams = <String, String>{'anio': anio};
    if (mes != null && mes.isNotEmpty) queryParams['mes'] = mes;
    final url = Uri.parse('$baseUrlNuevo/vacaciones/boleta-pago')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        List<dynamic> rawItems = jsonResponse['items'] as List<dynamic>? ?? [];
        if (rawItems.isEmpty) {
          final base64 = jsonResponse['archivo_pdf_base64'];
          if (base64 == null || base64 is! String) {
            throw Exception('La respuesta no contiene el archivo PDF');
          }
          final nseman = jsonResponse['nseman']?.toString() ?? '0';
          final semana = jsonResponse['semana'];
          return [
            {
              'archivo_pdf_base64': base64,
              'nombre_archivo': (jsonResponse['nombre_archivo'] ?? '').toString(),
              'codigo_trabajador': jsonResponse['codigo_trabajador']?.toString(),
              'anio': (jsonResponse['anio'] ?? anio).toString(),
              'mes': (jsonResponse['mes'] ?? mes ?? '').toString(),
              'nseman': nseman,
              'semana': semana is int ? semana : (semana != null ? int.tryParse(semana.toString()) : null),
            },
          ];
        }
        List<Map<String, dynamic>> list = [];
        for (final item in rawItems) {
          final map = item as Map<String, dynamic>;
          final base64 = map['archivo_pdf_base64'];
          if (base64 == null || base64 is! String) continue;
          final semana = map['semana'];
          list.add({
            'archivo_pdf_base64': base64,
            'nombre_archivo': (map['nombre_archivo'] ?? '').toString(),
            'codigo_trabajador': map['codigo_trabajador']?.toString(),
            'anio': (map['anio'] ?? anio).toString(),
            'mes': (map['mes'] ?? mes ?? '').toString(),
            'nseman': map['nseman']?.toString() ?? '0',
            'semana': semana is int ? semana : (semana != null ? int.tryParse(semana.toString()) : null),
          });
        }
        if (list.isEmpty) {
          throw Exception('La respuesta no contiene el archivo PDF');
        }
        return list;
      } else if (response.statusCode == 404) {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        final errorCode = errorBody?['error_code'] as String?;
        if (errorCode == 'BOLETA_NOT_FOUND') {
          throw Exception(mes != null && mes.isNotEmpty
              ? 'Boleta no encontrada para el año $anio y mes $mes'
              : 'Boleta no encontrada para el año $anio');
        } else if (errorCode == 'BOLETA_SIN_ARCHIVO') {
          throw Exception('La boleta no tiene archivo PDF disponible');
        }
        throw Exception(errorBody?['detail'] ?? 'Boleta no encontrada');
      } else if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      } else if (response.statusCode == 500) {
        throw Exception('Error de procesamiento en el servidor');
      } else {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        throw Exception(errorBody?['detail']?.toString() ?? 'Error al obtener boleta. Código: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SESSION_EXPIRED')) {
        rethrow;
      }
      throw Exception('Error al obtener boleta de pago: $e');
    }
  }

  /// Obtener Certificados CTS (puede devolver varios: Mayo y Noviembre)
  /// GET /api/v1/vacaciones/certificado-cts?anio=2024
  /// La API puede devolver { "items": [ {...}, {...} ] } o un solo objeto.
  Future<List<Map<String, dynamic>>> obtenerCertificadosCTS({
    required String anio,
  }) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación');
    }

    final url = Uri.parse('$baseUrlNuevo/vacaciones/certificado-cts')
        .replace(queryParameters: {
      'anio': anio,
    });

    try {
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        List<dynamic> rawItems = jsonResponse['items'] as List<dynamic>? ?? [];
        if (rawItems.isEmpty) {
          // Respuesta en formato objeto único (sin "items")
          final base64 = jsonResponse['archivo_pdf_base64'];
          if (base64 == null || base64 is! String) {
            throw Exception('La respuesta no contiene el archivo PDF');
          }
          final nseman = jsonResponse['nseman']?.toString() ?? '0';
          return [
            {
              'archivo_pdf_base64': base64,
              'nombre_archivo': (jsonResponse['nombre_archivo'] ?? '').toString(),
              'codigo_trabajador': jsonResponse['codigo_trabajador']?.toString(),
              'anio': (jsonResponse['anio'] ?? anio).toString(),
              'mes': jsonResponse['mes']?.toString(),
              'nseman': nseman,
              'tipo_documento': (jsonResponse['tipo_documento'] ?? '').toString(),
            },
          ];
        }
        List<Map<String, dynamic>> list = [];
        for (final item in rawItems) {
          final map = item as Map<String, dynamic>;
          final base64 = map['archivo_pdf_base64'];
          if (base64 == null || base64 is! String) continue;
          final semana = map['semana'];
          list.add({
            'archivo_pdf_base64': base64,
            'nombre_archivo': (map['nombre_archivo'] ?? '').toString(),
            'codigo_trabajador': map['codigo_trabajador']?.toString(),
            'anio': (map['anio'] ?? anio).toString(),
            'mes': map['mes']?.toString(),
            'nseman': map['nseman']?.toString() ?? '0',
            'semana': semana is int ? semana : (semana != null ? int.tryParse(semana.toString()) : null),
            'tipo_documento': (map['tipo_documento'] ?? '').toString(),
          });
        }
        if (list.isEmpty) {
          throw Exception('La respuesta no contiene el archivo PDF');
        }
        return list;
      } else if (response.statusCode == 404) {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        final errorCode = errorBody?['error_code'] as String?;
        if (errorCode == 'CERTIFICADO_CTS_NOT_FOUND') {
          throw Exception('Certificado CTS no encontrado para el año $anio');
        } else if (errorCode == 'CERTIFICADO_SIN_ARCHIVO') {
          throw Exception('El certificado no tiene archivo PDF disponible');
        }
        throw Exception(errorBody?['detail'] ?? 'Certificado no encontrado');
      } else if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      } else if (response.statusCode == 500) {
        throw Exception('Error de procesamiento en el servidor');
      } else {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        throw Exception(errorBody?['detail']?.toString() ?? 'Error al obtener certificado. Código: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SESSION_EXPIRED')) {
        rethrow;
      }
      throw Exception('Error al obtener certificado CTS: $e');
    }
  }

  /// Obtener Otros Documentos (similar a boletas, con año y mes opcional)
  /// Sin mes: GET .../documento-pago?anio=2025 (todos los documentos del año).
  /// Con mes: GET .../documento-pago?anio=2025&mes=07.
  /// La API devuelve { "items": [ {...}, {...} ] }.
  Future<List<Map<String, dynamic>>> obtenerOtrosDocumentos({
    required String anio,
    String? mes,
  }) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación');
    }

    final queryParams = <String, String>{'anio': anio};
    if (mes != null && mes.isNotEmpty) queryParams['mes'] = mes;
    final url = Uri.parse('$baseUrlNuevo/vacaciones/documento-pago')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        List<dynamic> rawItems = jsonResponse['items'] as List<dynamic>? ?? [];
        if (rawItems.isEmpty) {
          throw Exception('No se encontraron documentos');
        }
        List<Map<String, dynamic>> list = [];
        for (final item in rawItems) {
          final map = item as Map<String, dynamic>;
          final base64 = map['archivo_pdf_base64'];
          if (base64 == null || base64 is! String) continue;
          final semana = map['semana'];
          list.add({
            'archivo_pdf_base64': base64,
            'nombre_archivo': (map['nombre_archivo'] ?? '').toString(),
            'codigo_trabajador': map['codigo_trabajador']?.toString(),
            'anio': (map['anio'] ?? anio).toString(),
            'mes': (map['mes'] ?? mes ?? '').toString(),
            'nseman': map['nseman']?.toString() ?? '0',
            'semana': semana is int ? semana : (semana != null ? int.tryParse(semana.toString()) : null),
            'tipo_documento': (map['tipo_documento'] ?? '').toString(),
          });
        }
        if (list.isEmpty) {
          throw Exception('La respuesta no contiene documentos PDF');
        }
        return list;
      } else if (response.statusCode == 404) {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        throw Exception(errorBody?['detail']?.toString() ?? 'Documentos no encontrados');
      } else if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      } else if (response.statusCode == 500) {
        throw Exception('Error de procesamiento en el servidor');
      } else {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        throw Exception(errorBody?['detail']?.toString() ?? 'Error al obtener documentos. Código: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SESSION_EXPIRED')) {
        rethrow;
      }
      throw Exception('Error al obtener otros documentos: $e');
    }
  }

  /// Obtener Reglamentos de la empresa
  /// GET /api/v1/vacaciones/documentos-empresa
  /// La API devuelve { "items": [ {...}, {...} ] }.
  Future<List<Map<String, dynamic>>> obtenerReglamentos() async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación');
    }

    final url = Uri.parse('$baseUrlNuevo/vacaciones/documentos-empresa');

    try {
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        List<dynamic> rawItems = jsonResponse['items'] as List<dynamic>? ?? [];
        if (rawItems.isEmpty) {
          throw Exception('No se encontraron reglamentos');
        }
        List<Map<String, dynamic>> list = [];
        for (final item in rawItems) {
          final map = item as Map<String, dynamic>;
          final base64 = map['archivo_pdf_base64'];
          if (base64 == null || base64 is! String) continue;
          list.add({
            'archivo_pdf_base64': base64,
            'nombre_archivo': (map['nombre_archivo'] ?? '').toString(),
            'descripcion': (map['descripcion'] ?? '').toString(),
            'tipo_documento': (map['tipo_documento'] ?? '').toString(),
          });
        }
        if (list.isEmpty) {
          throw Exception('La respuesta no contiene documentos PDF');
        }
        return list;
      } else if (response.statusCode == 404) {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        throw Exception(errorBody?['detail']?.toString() ?? 'Reglamentos no encontrados');
      } else if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      } else if (response.statusCode == 500) {
        throw Exception('Error de procesamiento en el servidor');
      } else {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        throw Exception(errorBody?['detail']?.toString() ?? 'Error al obtener reglamentos. Código: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SESSION_EXPIRED')) {
        rethrow;
      }
      throw Exception('Error al obtener reglamentos: $e');
    }
  }

  /// Obtener Avisos de la empresa
  /// GET /api/v1/vacaciones/avisos-empresa
  /// La API devuelve { "items": [ {...}, {...} ] }.
  Future<List<Map<String, dynamic>>> obtenerAvisos() async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación');
    }

    final url = Uri.parse('$baseUrlNuevo/vacaciones/avisos-empresa');

    try {
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        List<dynamic> rawItems = jsonResponse['items'] as List<dynamic>? ?? [];
        if (rawItems.isEmpty) {
          throw Exception('No se encontraron avisos');
        }
        List<Map<String, dynamic>> list = [];
        for (final item in rawItems) {
          final map = item as Map<String, dynamic>;
          final base64 = map['archivo_pdf_base64'];
          if (base64 == null || base64 is! String) continue;
          list.add({
            'archivo_pdf_base64': base64,
            'nombre_archivo': (map['nombre_archivo'] ?? '').toString(),
            'descripcion': (map['descripcion'] ?? '').toString(),
            'tipo_documento': (map['tipo_documento'] ?? '').toString(),
          });
        }
        if (list.isEmpty) {
          throw Exception('La respuesta no contiene documentos PDF');
        }
        return list;
      } else if (response.statusCode == 404) {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        throw Exception(errorBody?['detail']?.toString() ?? 'Avisos no encontrados');
      } else if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      } else if (response.statusCode == 500) {
        throw Exception('Error de procesamiento en el servidor');
      } else {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        throw Exception(errorBody?['detail']?.toString() ?? 'Error al obtener avisos. Código: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SESSION_EXPIRED')) {
        rethrow;
      }
      throw Exception('Error al obtener avisos: $e');
    }
  }
}

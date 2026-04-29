import 'dart:convert';
import '../models/aviso_pendiente_model.dart';
import '../../core/network/api_client.dart';

class AvisosService {
  Future<AvisoPendienteResponse> obtenerAvisoPendiente() async {
    try {
      final response = await ApiClient.get(
        '/avisos/ap/pendiente',
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return AvisoPendienteResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      }

      final body = json.decode(response.body);
      throw Exception(
        body is Map<String, dynamic> && body['detail'] != null
            ? body['detail']
            : 'Error al obtener aviso pendiente',
      );
    } catch (e) {
      throw Exception('Error al obtener aviso pendiente: $e');
    }
  }

  Future<Map<String, dynamic>> marcarVisualizado() async {
    try {
      final response = await ApiClient.post(
        '/avisos/ap/visualizado',
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      }

      final body = json.decode(response.body);
      throw Exception(
        body is Map<String, dynamic> && body['detail'] != null
            ? body['detail']
            : 'Error al marcar visualizado',
      );
    } catch (e) {
      throw Exception('Error al marcar visualizado: $e');
    }
  }

  Future<Map<String, dynamic>> aceptarConforme() async {
    try {
      final response = await ApiClient.post(
        '/avisos/ap/aceptar',
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'conforme': true}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      }

      final body = json.decode(response.body);
      throw Exception(
        body is Map<String, dynamic> && body['detail'] != null
            ? body['detail']
            : 'Error al aceptar el aviso',
      );
    } catch (e) {
      throw Exception('Error al aceptar el aviso: $e');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String defaultBaseUrl =
      'https://ad-mock-saas.saaserver.duckdns.org';

  /// Obtiene entradas con paginación y filtros opcionales.
  /// [endpoint] puede personalizarse para reutilizar el servicio con otros recursos.
  /// [filters] admite: tipo, modo, restaurada, created_from, created_to
  static Future<List<dynamic>> fetchEntries({
    String endpoint = defaultBaseUrl,
    required int limit,
    required int offset,
    Map<String, dynamic>? filters,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    final f = filters ?? {};
    void addIfPresent(String key, dynamic value) {
      if (value == null) return;
      final s = value.toString();
      if (s.isEmpty) return;
      query[key] = s;
    }
    addIfPresent('tipo', f['tipo']);
    addIfPresent('modo', f['modo']);
    addIfPresent('restaurada', f['restaurada']);
    addIfPresent('created_from', f['created_from']);
    addIfPresent('created_to', f['created_to']);

    final uri = Uri.parse(endpoint).replace(queryParameters: query);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body) as List;
    } else {
      throw Exception('Error al cargar datos');
    }
  }
}

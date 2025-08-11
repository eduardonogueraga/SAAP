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
    // Accept any provided filters. Explicitly avoid overriding limit/offset here.
    for (final entry in f.entries) {
      final key = entry.key;
      if (key == 'limit' || key == 'offset') continue;
      final value = entry.value;
      if (value == null) continue;
      final s = value.toString();
      if (s.isEmpty) continue;
      query[key] = s;
    }

    final uri = Uri.parse(endpoint).replace(queryParameters: query);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body) as List;
    } else {
      throw Exception('Error al cargar datos');
    }
  }
}

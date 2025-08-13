import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? latestEntry;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final entries = await ApiService.fetchEntries(
        endpoint: '${ApiService.defaultBaseUrl}/entries',
        limit: 1,
        offset: 0,
      );

      if (entries.isNotEmpty) {
        setState(() {
          latestEntry = entries.first;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => isLoading = false);
    }
  }

  String formatId(int id) => id.toString().padLeft(9, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Estado de la Alarma'),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : latestEntry == null
              ? const Center(
                  child: Text(
                    'No hay datos disponibles',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bloque 1: Estado de la alarma
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          latestEntry!['tipo'] == 'activacion'
                              ? 'La alarma está ACTIVADA'
                              : 'La alarma está DESACTIVADA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: latestEntry!['tipo'] == 'activacion'
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bloque 2: Botón de detalles
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AlarmDetailsScreen(entryId: latestEntry!['id']),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[800],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Ver detalles de la alarma',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  color: Colors.white54, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class AlarmDetailsScreen extends StatefulWidget {
  final int entryId;
  const AlarmDetailsScreen({super.key, required this.entryId});

  @override
  State<AlarmDetailsScreen> createState() => _AlarmDetailsScreenState();
}

class _AlarmDetailsScreenState extends State<AlarmDetailsScreen> {
  Map<String, dynamic>? entryDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiService.defaultBaseUrl}/entries/${widget.entryId}/details'),
      );

      if (response.statusCode == 200) {
        setState(() {
          entryDetails = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando detalles: $e');
      setState(() => isLoading = false);
    }
  }

  String formatId(int id) => id.toString().padLeft(9, '0');

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Detalles de la Alarma'),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : entryDetails == null
              ? const Center(
                  child: Text(
                    'No se pudieron cargar los detalles',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información general
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('ID', formatId(entryDetails!['entry']['id'])),
                            _buildInfoRow('Tipo', entryDetails!['entry']['tipo']),
                            _buildInfoRow('Modo', entryDetails!['entry']['modo']),
                            _buildInfoRow('Fecha', entryDetails!['entry']['fecha']),
                            _buildInfoRow('Restaurada',
                                entryDetails!['entry']['restaurada'].toString()),
                            _buildInfoRow(
                                'Intentos reactivación',
                                entryDetails!['entry']['intentos_reactivacion']
                                    .toString()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Conteos
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[800],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Detecciones',
                                entryDetails!['counts']['detections'].toString()),
                            _buildInfoRow('Avisos',
                                entryDetails!['counts']['notices'].toString()),
                            _buildInfoRow('Logs',
                                entryDetails!['counts']['logs'].toString()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Listas
                      if (entryDetails!['detections'].isNotEmpty)
                        _buildListSection(
                            'Detecciones', entryDetails!['detections']),
                      if (entryDetails!['notices'].isNotEmpty)
                        _buildListSection('Avisos', entryDetails!['notices']),
                      if (entryDetails!['logs'].isNotEmpty)
                        _buildListSection('Logs', entryDetails!['logs']),
                    ],
                  ),
                ),
    );
  }

  Widget _buildListSection(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                json.encode(item),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

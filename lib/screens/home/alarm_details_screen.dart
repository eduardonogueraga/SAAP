import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  String formatId(dynamic id) =>
      (id ?? 0).toString().padLeft(9, '0');

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: item.entries.map((entry) {
              return _buildInfoRow(
                entry.key,
                entry.value?.toString() ?? '',
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection(
      String title, List<dynamic> items, String idKey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: Colors.white70,
          colorScheme: ColorScheme.dark(primary: Colors.blueAccent),
        ),
        child: ExpansionTile(
          title: Text(
            "$title (${items.length})",
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
          children: items.isNotEmpty
              ? items.map((item) {
                  final idValue = item[idKey] ?? item['id'];
                  return ListTile(
                    title: Text(
                      "ID: ${formatId(idValue)}",
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    subtitle: Text(
                      item['fecha'] ?? '',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios,
                        size: 16, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                    onTap: () => _showItemDetails(context, item),
                  );
                }).toList()
              : [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "No hay elementos",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  )
                ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detalles de la Alarma', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : entryDetails == null
              ? Center(
                  child: Text(
                    'No se pudieron cargar los detalles',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)),
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
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                                'ID', formatId(entryDetails!['entry']['id'])),
                            _buildInfoRow(
                                'Tipo', entryDetails!['entry']['tipo']),
                            _buildInfoRow(
                                'Modo', entryDetails!['entry']['modo']),
                            _buildInfoRow(
                                'Fecha', entryDetails!['entry']['fecha']),
                            _buildInfoRow(
                                'Restaurada',
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
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                                'Detecciones',
                                entryDetails!['counts']['detections']
                                    .toString()),
                            _buildInfoRow(
                                'Avisos',
                                entryDetails!['counts']['notices'].toString()),
                            _buildInfoRow(
                                'Logs', entryDetails!['counts']['logs'].toString()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Secciones expandibles con listado clicable
                      _buildExpandableSection(
                          'Detecciones', entryDetails!['detections'], 'detection_id'),
                      _buildExpandableSection(
                          'Avisos', entryDetails!['notices'], 'id'),
                      _buildExpandableSection(
                          'Logs', entryDetails!['logs'], 'id'),
                    ],
                  ),
                ),
    );
  }
}

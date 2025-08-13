import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/detail_info.dart';
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
    // Determine the item type for the title
    String itemType = 'Detalles';
    IconData itemIcon = Icons.info_outline;
    Color itemColor = Theme.of(context).primaryColor;
    
    // Determine type based on available fields
    if (item.containsKey('detection_id')) {
      itemType = 'Detección';
      itemIcon = Icons.sensors;
      itemColor = Colors.orange;
    } else if (item.containsKey('notice_id')) {
      itemType = 'Aviso';
      itemIcon = Icons.notifications;
      itemColor = Colors.blue;
    } else if (item.containsKey('log_id')) {
      itemType = 'Log del sistema';
      itemIcon = Icons.article;
      itemColor = Colors.grey;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Just the handle for the bottom sheet
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Content
            Expanded(
              child: DetailInfo(
                title: '',
                data: item,
                dateKeys: {'fecha', 'created_at', 'updated_at'},
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get title and icon for each item type
  (String, IconData, Color) _getItemTypeInfo(String sectionTitle, Map<String, dynamic> item) {
    switch (sectionTitle.toLowerCase()) {
      case 'detecciones':
        return ('Detección', Icons.sensors, Colors.orange);
      case 'avisos':
        return ('Aviso', Icons.notifications, Colors.blue);
      case 'logs':
        return ('Log', Icons.article, Colors.grey);
      default:
        return ('Elemento', Icons.info, Theme.of(context).primaryColor);
    }
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
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        child: ExpansionTile(
          leading: _getItemTypeInfo(title, {}).$2 != null
              ? Icon(_getItemTypeInfo(title, {}).$2, 
                    color: _getItemTypeInfo(title, {}).$3)
              : null,
          title: Text(
            "$title (${items.length})",
            style: TextStyle(
              color: Theme.of(context).textTheme.titleMedium?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: items.isNotEmpty
              ? items.map((item) {
                  final idValue = item[idKey] ?? item['id'];
                  final (typeName, icon, color) = _getItemTypeInfo(title, item);
                  
                  return ListTile(
                    leading: Icon(icon, color: color),
                    title: Text(
                      "$typeName ${formatId(idValue)}",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      item['fecha'] ?? 'Sin fecha',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16, 
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7)
                    ),
                    onTap: () => _showItemDetails(context, item),
                  );
                }).toList()
              : [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "No hay elementos",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
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

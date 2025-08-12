import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../widgets/detail_info.dart';

class PackageScreen extends StatefulWidget {
  const PackageScreen({super.key});

  @override
  State<PackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen> {
  final List<dynamic> _packages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  final Map<int, dynamic> _packageDetails = {};
  int? _expandedPackageId;

  @override
  void initState() {
    super.initState();
    _fetchPackages();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchPackages();
      }
    });
  }

  Future<void> _fetchPackages() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchEntries(
        endpoint: '${ApiService.defaultBaseUrl}/packages',
        limit: _limit,
        offset: _offset,
      );
      setState(() {
        _packages.addAll(data);
        _offset += _limit;
        if (data.length < _limit) _hasMore = false;
      });
    } catch (e) {
      debugPrint("Error cargando paquetes: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchPackageDetails(int id) async {
    if (_packageDetails.containsKey(id)) {
      setState(() {
        _expandedPackageId = _expandedPackageId == id ? null : id;
      });
      return;
    }
    setState(() => _expandedPackageId = id);

    final url =
        Uri.parse('${ApiService.defaultBaseUrl}/packages/$id/details');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      setState(() {
        _packageDetails[id] = jsonDecode(res.body);
      });
    } else {
      setState(() {
        _packageDetails[id] = {"error": "No se pudieron cargar los detalles"};
      });
    }
  }

  Widget _buildCounts(Map<String, dynamic> counts) {
    // Mapa de traducciones de claves a español
    final translations = <String, String>{
      'entries': 'Entradas',
      'logs': 'Logs',
      'detections': 'Detecciones',
      'notices': 'Avisos',
    };

    return Wrap(
      spacing: 8,
      children: counts.entries.map((e) {
        // Usar la traducción si existe, o la clave original
        final displayName = translations[e.key.toLowerCase()] ?? e.key;
        return Chip(
          label: Text('$displayName: ${e.value}'),
          backgroundColor: Colors.blue.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          labelStyle: const TextStyle(fontSize: 13),
        );
      }).toList(),
    );
  }

  Widget _buildSection({
    required String title,
    required List<dynamic> data,
  }) {
    // Don't show empty sections at all
    if (data.isEmpty) return const SizedBox.shrink();
    
    final sectionColor = _getSectionColor(title);
    
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: sectionColor.withOpacity(0.2),
        child: Icon(_getSectionIcon(title), color: sectionColor, size: 20),
      ),
      title: Text("$title (${data.length})", style: TextStyle(fontWeight: FontWeight.w500)),
      children: data.map((itemData) {
        final Map<String, dynamic> item = itemData is Map<String, dynamic> 
            ? itemData 
            : {'Detalle': itemData.toString()};
            
        // Format title as 'Type: 000000123' (e.g., 'Detection: 000000123')
        final itemId = item['id']?.toString() ?? '';
        final formattedId = itemId.isNotEmpty 
            ? itemId.padLeft(9, '0')
            : '';
        final displayTitle = itemId.isNotEmpty 
            ? '${title.replaceAll(RegExp(r's$'), '')}: $formattedId' 
            : title;
            
        final itemColor = _getSectionColor(title);
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: itemColor.withOpacity(0.1),
            radius: 18,
            child: Icon(_getSectionIcon(title), color: itemColor, size: 16),
          ),
          title: Text(displayTitle, style: const TextStyle(fontSize: 15)),
          trailing: CircleAvatar(
            backgroundColor: itemColor.withOpacity(0.1),
            radius: 14,
            child: Icon(Icons.chevron_right, color: itemColor, size: 18),
          ),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => DetailInfo(
                title: displayTitle,
                data: item,
                dateKeys: {'fecha', 'created_at', 'updated_at', 'fecha_creacion'},
              ),
            );
          },
        );
      }).toList(),
    );
  }

  // Helper method to get icon for each section type
  IconData _getSectionIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('entrada')) return Icons.input;
    if (lowerTitle.contains('log')) return Icons.assignment;
    if (lowerTitle.contains('deteccion')) return Icons.warning_amber_rounded;
    if (lowerTitle.contains('aviso')) return Icons.notifications;
    if (lowerTitle.contains('paquete')) return Icons.window;
    return Icons.info_outline;
  }

  // Helper method to get color for each section type
  Color _getSectionColor(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('entrada')) return Colors.blue;
    if (lowerTitle.contains('log')) return Colors.orange;
    if (lowerTitle.contains('deteccion')) return Colors.red;
    if (lowerTitle.contains('aviso')) return Colors.amber;
    if (lowerTitle.contains('paquete')) return Colors.green;
    return Colors.grey;
  }

  Widget _buildPackageDetails(Map<String, dynamic> details) {
    final List<Widget> children = [];
    
    // Add counts if available
    if (details.containsKey('counts') && details['counts'] is Map) {
      children.add(_buildCounts(details['counts']));
      children.add(const SizedBox(height: 8));
    }
    
    // Add package details if available
    if (details.containsKey('package') && details['package'] is Map) {
      final packageSection = _buildSection(
        title: "Paquete", 
        data: [details['package']]
      );
      if (packageSection is! SizedBox) children.add(packageSection);
    }
    
    // Add other sections only if they have data
    final sections = [
      {"key": "entries", "title": "Entradas"},
      {"key": "logs", "title": "Logs"},
      {"key": "detections", "title": "Detecciones"},
      {"key": "notices", "title": "Avisos"},
    ];
    
    for (var section in sections) {
      if (details[section['key']] is List && (details[section['key']] as List).isNotEmpty) {
        final sectionWidget = _buildSection(
          title: section['title']!,
          data: List.from(details[section['key']])
        );
        if (sectionWidget is! SizedBox) {
          children.add(sectionWidget);
        }
      }
    }
    
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial de paquetes")),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _packages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _packages.length) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final pkg = _packages[index];
          final pkgId = pkg['id'] as int;
          final isExpanded = _expandedPackageId == pkgId;
          final details = _packageDetails[pkgId];

          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: pkg['implantado'] == 0 
                      ? Colors.red.shade100 
                      : (pkg['vacio'] == 1 ? Colors.blueGrey.shade100 : Colors.green.withOpacity(0.2)),
                  child: Icon(
                    Icons.window, 
                    color: pkg['implantado'] == 0 
                        ? Colors.red.shade700 
                        : (pkg['vacio'] == 1 ? Colors.blueGrey.shade700 : Colors.green.shade700),
                  ),
                ),
                title: Text(
                  'Paquete ${pkgId.toString().padLeft(9, '0')}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: pkg['vacio'] == 1 ? Colors.blueGrey.shade700 : null,
                  ),
                ),
                subtitle: Text(
                  pkg['fecha'] ?? 'Sin fecha',
                  style: pkg['vacio'] == 1 
                      ? TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontSize: 13,
                        ) 
                      : null,
                ),
                trailing: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 16,
                  child: Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: pkg['vacio'] == 1 ? Colors.blueGrey.shade500 : Colors.green.shade700,
                  ),
                ),
                onTap: () => _fetchPackageDetails(pkgId),
              ),
              if (isExpanded)
                details == null
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _buildPackageDetails(details),
              const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }
}

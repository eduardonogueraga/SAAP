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
    return Wrap(
      spacing: 8,
      children: counts.entries.map((e) {
        return Chip(
          label: Text("${e.key}: ${e.value}"),
          backgroundColor: Colors.blue.shade100,
        );
      }).toList(),
    );
  }

  Widget _buildSection({
    required String title,
    required List<dynamic> data,
  }) {
    if (data.isEmpty) {
      return ListTile(
        title: Text(title),
        subtitle: const Text("⚠ Vacío", style: TextStyle(color: Colors.red)),
      );
    }
    return ExpansionTile(
      title: Text("$title (${data.length})"),
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final dynamic itemData = entry.value;
        final Map<String, dynamic> item = itemData is Map<String, dynamic> 
            ? itemData 
            : {'Detalle': itemData.toString()};
            
        return ListTile(
          title: Text("$title #${index + 1}"),
          trailing: const Icon(Icons.info_outline),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => DetailInfo(
                title: '$title #${index + 1}',
                data: item,
                dateKeys: {'fecha', 'created_at', 'updated_at', 'fecha_creacion'},
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildPackageDetails(Map<String, dynamic> details) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (details.containsKey('counts') && details['counts'] is Map)
            _buildCounts(details['counts']),
          const SizedBox(height: 8),
          if (details.containsKey('package') && details['package'] is Map)
            _buildSection(title: "Paquete", data: [details['package']]),
          if (details.containsKey('entries'))
            _buildSection(title: "Entradas", data: List.from(details['entries'])),
          if (details.containsKey('logs'))
            _buildSection(title: "Logs", data: List.from(details['logs'])),
          if (details.containsKey('detections'))
            _buildSection(title: "Detecciones", data: List.from(details['detections'] ?? [])),
          if (details.containsKey('notices'))
            _buildSection(title: "Avisos", data: List.from(details['notices'])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paquetes")),
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
                leading: const Icon(Icons.window),
                title: Text('Paquete ${pkgId.toString().padLeft(9, '0')}'),
                subtitle: Text(pkg['fecha'] ?? 'Sin fecha'),
                trailing: Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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

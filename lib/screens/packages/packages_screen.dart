import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../widgets/detail_info.dart';

class PackagesScreen extends StatefulWidget {
  final String? endpoint; // base domain
  final Map<String, dynamic>? initialFilters;
  const PackagesScreen({super.key, this.endpoint, this.initialFilters});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final ScrollController _scrollController = ScrollController();
  final int _limit = 12;
  int _offset = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  late final DateFormat _dfList = DateFormat('d MMM HH:mm', 'es_ES');

  late String _endpoint; // full packages endpoint
  Map<String, dynamic> _filters = {};
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    final base = widget.endpoint ?? ApiService.defaultBaseUrl;
    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    _endpoint = normalizedBase.endsWith('/packages') ? normalizedBase : '$normalizedBase/packages';
    _filters = {...?widget.initialFilters};
    _fetchData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchData();
      }
    });
  }

  Future<void> _fetchData() async {
    if (_isLoading || !_hasMore) return;
    if (mounted) setState(() => _isLoading = true);
    try {
      final List<dynamic> result = await ApiService.fetchEntries(
        endpoint: _endpoint,
        limit: _limit,
        offset: _offset,
        filters: _filters,
      );
      final List<Map<String, dynamic>> newItems = result
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .map((e) {
        final fechaRaw = (e['fecha'] ?? e['created_at'] ?? '').toString();
        final implantado = _toInt(e['implantado']);
        e['_fecha_fmt'] = fechaRaw.isNotEmpty ? _formatDate(fechaRaw) : '';
        e['_isImplantado'] = implantado == 1;
        return e;
      }).toList();

      final bool more = newItems.length >= _limit;
      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _offset += _limit;
          _hasMore = more;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error packages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    final s = v.toString();
    return int.tryParse(s) ?? 0;
  }

  String _pad9(int n) => n.toString().padLeft(9, '0');

  String _formatDate(String raw) {
    try {
      DateTime? parsed = DateTime.tryParse(raw);
      parsed ??= HttpDate.parse(raw);
      final dt = parsed.toLocal();
      return _dfList.format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _prettyJson(String input) {
    try {
      final decoded = json.decode(input);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return input; // fallback
    }
  }

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: initial != null
          ? TimeOfDay(hour: initial.hour, minute: initial.minute)
          : const TimeOfDay(hour: 0, minute: 0),
    );
    if (time == null) return DateTime(date.year, date.month, date.day);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _openFilters() {
    // Selectables only: implantado (dropdown 3 estados) & saa_version (dropdown), plus date range
    String implantadoSel = _filters.containsKey('implantado')
        ? (_filters['implantado'].toString() == '1' ? 'Implantados' : 'No implantados')
        : 'Todos';
    final Set<String> versions = _items
        .map((e) => (e['saa_version'] ?? '').toString())
        .where((s) => s.isNotEmpty && s.toLowerCase() != 'null')
        .toSet();
    String? versionSel = (_filters['saa_version']?.toString());

    DateTime? from = _filters['created_from'] is String
        ? DateTime.tryParse(_filters['created_from'])
        : null;
    DateTime? to = _filters['created_to'] is String
        ? DateTime.tryParse(_filters['created_to'])
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              String fmt(DateTime? d) => d == null
                  ? ''
                  : DateFormat('yyyy-MM-ddTHH:mm:ss').format(d);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Filtros',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    value: implantadoSel,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Implantado'),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'Implantados', child: Text('Implantados')),
                      DropdownMenuItem(value: 'No implantados', child: Text('No implantados')),
                    ],
                    onChanged: (v) => setModalState(() => implantadoSel = v ?? 'Todos'),
                  ),
                  if (versions.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: versionSel,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Versión SAA'),
                      hint: const Text('Todas'),
                      items: versions
                          .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) => setModalState(() => versionSel = v),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(from == null
                              ? 'Desde'
                              : DateFormat('d MMM y HH:mm', 'es_ES')
                                  .format(from!)),
                          onPressed: () async {
                            final picked = await _pickDateTime(context, from);
                            if (picked != null) setModalState(() => from = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(to == null
                              ? 'Hasta'
                              : DateFormat('d MMM y HH:mm', 'es_ES')
                                  .format(to!)),
                          onPressed: () async {
                            final picked = await _pickDateTime(context, to);
                            if (picked != null) setModalState(() => to = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _filters = {};
                              _offset = 0;
                              _items.clear();
                              _hasMore = true;
                            });
                            Navigator.of(context).pop();
                            _fetchData();
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final newFilters = <String, dynamic>{};
                            if (implantadoSel == 'Implantados') newFilters['implantado'] = '1';
                            if (implantadoSel == 'No implantados') newFilters['implantado'] = '0';
                            if (versionSel != null && versionSel!.isNotEmpty) {
                              newFilters['saa_version'] = versionSel;
                            }
                            if (from != null) newFilters['created_from'] = fmt(from);
                            if (to != null) newFilters['created_to'] = fmt(to);
                            setState(() {
                              _filters = newFilters;
                              _offset = 0;
                              _items.clear();
                              _hasMore = true;
                            });
                            Navigator.of(context).pop();
                            _fetchData();
                          },
                          child: const Text('Aplicar filtros'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paquetes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilters,
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        cacheExtent: 1000,
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index < _items.length) {
            final p = _items[index];
            final String fechaFmt = (p['_fecha_fmt'] as String?) ?? _formatDate((p['fecha'] ?? '').toString());
            final bool isImplantado = (p['_isImplantado'] as bool?) ?? false;
            final int intentos = _toInt(p['intentos']);

            final IconData icon = Icons.window;
            final Color color = isImplantado ? Colors.green : Colors.grey;

            return Card(
              key: ValueKey(p['id'] ?? index),
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color),
                ),
                title: Text(
                  'Paquete ${_pad9(_toInt(p['id']))}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Fecha: $fechaFmt',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.restart_alt, size: 16),
                          label: Text('Intentos: $intentos'),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                isThreeLine: true,
                onTap: () {
                  final Map<String, dynamic> data = {
                    'id': p['id'],
                    'implantado': p['implantado'],
                    'intentos': p['intentos'],
                    'saa_version': p['saa_version'],
                    'contenido_peticion': _prettyJson((p['contenido_peticion'] ?? '').toString()),
                    'fecha': p['fecha'],
                    'created_at': p['created_at'],
                    'updated_at': p['updated_at'],
                  };

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: DetailInfo(
                          title: 'Detalle del paquete',
                          data: data,
                          labels: const {
                            'id': 'ID',
                            'implantado': 'Implantado',
                            'intentos': 'Intentos',
                            'saa_version': 'Versión SAA',
                            'contenido_peticion': 'Contenido (JSON)',
                            'fecha': 'Fecha',
                            'created_at': 'Creado',
                            'updated_at': 'Actualizado',
                          },
                          dateKeys: const {'fecha', 'created_at', 'updated_at'},
                          timeKey: 'fecha',
                        ),
                      );
                    },
                  );
                },
              ),
            );
          } else {
            return _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

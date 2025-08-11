import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../widgets/detail_info.dart';

class AppLogsScreen extends StatefulWidget {
  final String? endpoint;
  final Map<String, dynamic>? initialFilters;
  const AppLogsScreen({super.key, this.endpoint, this.initialFilters});

  @override
  State<AppLogsScreen> createState() => _AppLogsScreenState();
}

class _AppLogsScreenState extends State<AppLogsScreen> {
  final ScrollController _scrollController = ScrollController();
  final int _limit = 12;
  int _offset = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  late final DateFormat _dfList = DateFormat('d MMM HH:mm', 'es_ES');

  late String _endpoint; // full /applogs
  Map<String, dynamic> _filters = {};
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    final base = widget.endpoint ?? ApiService.defaultBaseUrl;
    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    _endpoint = normalizedBase.endsWith('/applogs') ? normalizedBase : '$normalizedBase/applogs';
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
        final fechaRaw = (e['created_at'] ?? e['fecha'] ?? '').toString();
        e['_fecha_fmt'] = fechaRaw.isNotEmpty ? _formatDate(fechaRaw) : '';
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
      debugPrint('Error applogs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  String _prettyJson(String? input) {
    if (input == null || input.isEmpty) return '';
    try {
      final decoded = json.decode(input);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return input; // already string or invalid JSON, show raw
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
    // Selectables: tipo (from data), date range
    final Set<String> tipos = _items
        .map((e) => (e['tipo'] ?? '').toString())
        .where((s) => s.isNotEmpty && s.toLowerCase() != 'null')
        .toSet();
    String? tipoSel = (_filters['tipo']?.toString());

    // Removed description filter

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
                  if (tipos.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: tipoSel,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      hint: const Text('Todos'),
                      items: tipos
                          .map((v) {
                            final low = v.toLowerCase();
                            final label = low == 'api'
                                ? 'JOB'
                                : (low == 'alarm' ? 'API' : v.toUpperCase());
                            return DropdownMenuItem<String>(
                              value: v,
                              child: Text(label),
                            );
                          })
                          .toList(),
                      onChanged: (v) => setModalState(() => tipoSel = v),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Description filter removed
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(from == null
                              ? 'Desde'
                              : DateFormat('d MMM y HH:mm', 'es_ES').format(from!)),
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
                              : DateFormat('d MMM y HH:mm', 'es_ES').format(to!)),
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
                            if (tipoSel != null && tipoSel!.isNotEmpty) newFilters['tipo'] = tipoSel;
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
        title: const Text('SAAS Logs'),
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
            final a = _items[index];
            final String fechaFmt = (a['_fecha_fmt'] as String?) ?? _formatDate((a['created_at'] ?? a['fecha'] ?? '').toString());
            final String tipo = (a['tipo'] ?? '').toString();
            final String desc = (a['desc'] ?? '').toString();
            final String? contenido = (a['contenido_peticion'] as String?);
            final String error = (a['error'] ?? '').toString();
            final String respuesta = (a['respuesta_http'] ?? '').toString();

            final String tLower = tipo.toLowerCase();
            final bool isAlarm = tLower == 'alarm';
            final IconData icon = tLower == 'api' ? Icons.work_outline : Icons.http;
            final Color color = isAlarm ? const Color.fromARGB(255, 244, 158, 54) : Colors.indigo;
            final String displayTitle = tLower == 'alarm'
                ? '[API]  Entrada de datos'
                : tLower == 'api'
                    ? '[JOB] Log de alarmado'
                    : tipo.toUpperCase();

            return Card(
              key: ValueKey(a['id'] ?? index),
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color),
                ),
                title: Text(
                  displayTitle,
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
                    if (desc.isNotEmpty)
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (error.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.error_outline, size: 16),
                            label: Text('Error'),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                          ),
                        if (respuesta.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.check_circle_outline, size: 16),
                            label: Text('HTTP'),
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
                    'id': a['id'],
                    'tipo': a['tipo'],
                    'desc': a['desc'],
                    'error': a['error'],
                    'respuesta_http': a['respuesta_http'],
                    'contenido_peticion': _prettyJson(contenido),
                    'fecha': a['fecha'] ?? a['created_at'],
                    'created_at': a['created_at'],
                    'updated_at': a['updated_at'],
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
                          title: 'Detalle del log',
                          data: data,
                          labels: const {
                            'id': 'ID',
                            'tipo': 'Tipo',
                            'desc': 'Descripción',
                            'error': 'Error',
                            'respuesta_http': 'Respuesta HTTP',
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

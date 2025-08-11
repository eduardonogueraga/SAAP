import 'dart:io' show HttpDate;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../widgets/detail_info.dart';

class DetectionsScreen extends StatefulWidget {
  final String? endpoint; // base domain, e.g., https://ad-mock-saas.saaserver.duckdns.org
  final Map<String, dynamic>? initialFilters;
  const DetectionsScreen({super.key, this.endpoint, this.initialFilters});

  @override
  State<DetectionsScreen> createState() => _DetectionsScreenState();
}

class _DetectionsScreenState extends State<DetectionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final int _limit = 12;
  int _offset = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  late final DateFormat _dfList = DateFormat('d MMM HH:mm', 'es_ES');

  late String _endpoint; // full detections endpoint
  Map<String, dynamic> _filters = {};
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    final base = widget.endpoint ?? ApiService.defaultBaseUrl;
    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    _endpoint = normalizedBase.endsWith('/detections') ? normalizedBase : '$normalizedBase/detections';
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
        // Precompute derived fields
        final estado = (e['sensor_estado'] ?? '').toString().toUpperCase();
        final intrusismo = _toInt(e['intrusismo']);
        final restaurado = _toInt(e['restaurado']);
        final fechaRaw = (e['fecha'] ?? e['created_at'] ?? '').toString();
        e['_isAlert'] = intrusismo == 1;
        e['_isRestored'] = restaurado == 1;
        e['_isOnline'] = estado == 'ONLINE';
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
      debugPrint('Error detections: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    final s = v.toString();
    return int.tryParse(s) ?? 0;
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
    // Prefer selectors/switches where possible. Some fields are open-ended; keeping text for now.
    bool intrusismo = (_filters['intrusismo']?.toString() == '1');
    bool restaurado = (_filters['restaurado']?.toString() == '1');
    String? sensorEstado = (_filters['sensor_estado'] as String?)?.toUpperCase();
    // Build selectable options from current items
    final Set<String> sensorTipos = _items
        .map((e) => (e['sensor_tipo'] ?? '').toString())
        .where((s) => s.isNotEmpty && s.toLowerCase() != 'null')
        .toSet();
    final Set<String> umbrales = _items
        .map((e) => (e['umbral'] ?? '').toString())
        .where((s) => s.isNotEmpty && s.toLowerCase() != 'null')
        .toSet();
    final Set<String> terminalNombres = _items
        .map((e) => (e['nombre_terminal'] ?? '').toString())
        .where((s) => s.isNotEmpty && s.toLowerCase() != 'null')
        .toSet();

    String? sensorTipoSel = (_filters['sensor_tipo']?.toString());
    String? umbralSel = (_filters['umbral']?.toString());
    String? terminalNombreSel = (_filters['terminal_nombre'] as String?);

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
              return SingleChildScrollView(
                child: Column(
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
                    SwitchListTile(
                      value: intrusismo,
                      onChanged: (v) => setModalState(() => intrusismo = v),
                      title: const Text('Intrusismo'),
                    ),
                    SwitchListTile(
                      value: restaurado,
                      onChanged: (v) => setModalState(() => restaurado = v),
                      title: const Text('Restaurado'),
                    ),
                    DropdownButtonFormField<String>(
                      value: sensorEstado,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Sensor estado'),
                      hint: const Text('Todos'),
                      items: const [
                        DropdownMenuItem(value: 'ONLINE', child: Text('ONLINE')),
                        DropdownMenuItem(value: 'OFFLINE', child: Text('OFFLINE')),
                      ],
                      onChanged: (v) => setModalState(() => sensorEstado = v),
                    ),
                    // Campos de selección únicamente (dropdowns a partir de valores existentes).
                    if (sensorTipos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: sensorTipoSel,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Sensor tipo'),
                        hint: const Text('Todos'),
                        items: sensorTipos
                            .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                            .toList(),
                        // Items must be DropdownMenuItem list; map below
                        onChanged: (v) => setModalState(() => sensorTipoSel = v),
                      ),
                    ],
                    if (umbrales.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: umbralSel,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Umbral'),
                        hint: const Text('Todos'),
                        items: umbrales
                            .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                            .toList(),
                        onChanged: (v) => setModalState(() => umbralSel = v),
                      ),
                    ],
                    if (terminalNombres.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: terminalNombreSel,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Terminal nombre'),
                        hint: const Text('Todos'),
                        items: terminalNombres
                            .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                            .toList(),
                        onChanged: (v) => setModalState(() => terminalNombreSel = v),
                      ),
                    ],
                    const SizedBox(height: 8),
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
                              if (intrusismo) newFilters['intrusismo'] = '1';
                              if (restaurado) newFilters['restaurado'] = '1';
                              if (sensorEstado != null && sensorEstado!.isNotEmpty) {
                                newFilters['sensor_estado'] = sensorEstado;
                              }
                              // Solo filtros seleccionables añadidos.
                              if (sensorTipoSel != null && sensorTipoSel!.isNotEmpty) {
                                newFilters['sensor_tipo'] = sensorTipoSel;
                              }
                              if (umbralSel != null && umbralSel!.isNotEmpty) {
                                newFilters['umbral'] = umbralSel;
                              }
                              if (terminalNombreSel != null && terminalNombreSel!.isNotEmpty) {
                                newFilters['terminal_nombre'] = terminalNombreSel;
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
                ),
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
        title: const Text('Detecciones'),
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
            final d = _items[index];
            final String fechaFmt = (d['_fecha_fmt'] as String?) ?? _formatDate((d['fecha'] ?? '').toString());
            final bool isAlert = (d['_isAlert'] as bool?) ?? false;
            final bool isOnline = (d['_isOnline'] as bool?) ?? false;

            final String sensorEstado = (d['sensor_estado'] ?? '').toString();
            final String sensorTipo = (d['sensor_tipo'] ?? '').toString();
            final String modoDet = (d['modo_deteccion'] ?? '').toString();

            final IconData icon = isAlert
                ? Icons.warning_amber_rounded
                : isOnline
                    ? Icons.sensors
                    : Icons.sensors_off;
            final Color color = isAlert
                ? Colors.red
                : isOnline
                    ? Colors.green
                    : Colors.grey;

            return Card(
              key: ValueKey(d['detection_id'] ?? index),
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color),
                ),
                title: Text(
                  (() {
                    final base = sensorTipo.isNotEmpty
                        ? 'Detección en $sensorTipo'
                        : 'Detección';
                    return isAlert ? '$base (Intrusismo)' : base;
                  })(),
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
                        if (sensorEstado.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.power_settings_new, size: 16),
                            label: Text(sensorEstado),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                          ),
                        if (modoDet.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.settings_suggest, size: 16),
                            label: Text(modoDet),
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
                    'detection_id': d['detection_id'],
                    'entry_id': d['entry_id'],
                    'package_id': d['package_id'],
                    'fecha': d['fecha'],
                    'intrusismo': d['intrusismo'],
                    'restaurado': d['restaurado'],
                    'sensor_estado': d['sensor_estado'],
                    'sensor_id': d['sensor_id'],
                    'sensor_tipo': d['sensor_tipo'],
                    'valor_sensor': d['valor_sensor'],
                    'umbral': d['umbral'],
                    'modo_deteccion': d['modo_deteccion'],
                    'nombre_terminal': d['nombre_terminal'],
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
                          title: 'Detalle de la detección',
                          data: data,
                          labels: const {
                            'detection_id': 'ID detección',
                            'entry_id': 'Entrada',
                            'package_id': 'Paquete',
                            'fecha': 'Fecha',
                            'intrusismo': 'Intrusismo',
                            'restaurado': 'Restaurado',
                            'sensor_estado': 'Estado',
                            'sensor_id': 'Sensor ID',
                            'sensor_tipo': 'Tipo de sensor',
                            'valor_sensor': 'Valor sensor',
                            'umbral': 'Umbral',
                            'modo_deteccion': 'Modo detección',
                            'nombre_terminal': 'Terminal',
                          },
                          dateKeys: const {'fecha'},
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

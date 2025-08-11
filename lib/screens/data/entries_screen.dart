import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/detail_info.dart';
import 'dart:io' show HttpDate;

class EntriesScreen extends StatefulWidget {
  final String? endpoint;
  final Map<String, dynamic>? initialFilters;
  const EntriesScreen({super.key, this.endpoint, this.initialFilters});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 12;
  late final DateFormat _dfList = DateFormat('d MMM HH:mm', 'es_ES');
  late String _endpoint;
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    final base = widget.endpoint ?? ApiService.defaultBaseUrl;
    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    _endpoint = normalizedBase.endsWith('/entries') ? normalizedBase : '$normalizedBase/entries';
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
    String? selectedTipo = (_filters['tipo'] as String?)?.toLowerCase();
    String? selectedModo = (_filters['modo'] as String?)?.toLowerCase();
    bool restaurada = (_filters['restaurada']?.toString() ?? '').isEmpty
        ? false
        : _filters['restaurada'].toString() == '1' || _filters['restaurada'] == true;
    DateTime? from = _filters['created_from'] is String ? DateTime.tryParse(_filters['created_from']) : null;
    DateTime? to = _filters['created_to'] is String ? DateTime.tryParse(_filters['created_to']) : null;

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
              String fmt(DateTime? d) => d == null ? '' : DateFormat('yyyy-MM-ddTHH:mm:ss').format(d);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Filtros', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedTipo,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    hint: const Text('Todos'),
                    items: const [
                      DropdownMenuItem(value: 'activacion', child: Text('Activación')),
                      DropdownMenuItem(value: 'desactivacion', child: Text('Desactivación')),
                    ],
                    onChanged: (v) => setModalState(() => selectedTipo = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedModo,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Modo'),
                    hint: const Text('Todos'),
                    items: const [
                      DropdownMenuItem(value: 'manual', child: Text('Manual')),
                      DropdownMenuItem(value: 'automatica', child: Text('Automática')),
                    ],
                    onChanged: (v) => setModalState(() => selectedModo = v),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: restaurada,
                    onChanged: (v) => setModalState(() => restaurada = v),
                    title: const Text('Restaurada'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(from == null ? 'Desde' : DateFormat('d MMM y HH:mm', 'es_ES').format(from!)),
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
                          label: Text(to == null ? 'Hasta' : DateFormat('d MMM y HH:mm', 'es_ES').format(to!)),
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
                              _entries.clear();
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
                            if (selectedTipo != null && selectedTipo!.isNotEmpty) newFilters['tipo'] = selectedTipo;
                            if (selectedModo != null && selectedModo!.isNotEmpty) newFilters['modo'] = selectedModo;
                            if (restaurada) newFilters['restaurada'] = '1';
                            if (from != null) newFilters['created_from'] = fmt(from);
                            if (to != null) newFilters['created_to'] = fmt(to);
                            setState(() {
                              _filters = newFilters;
                              _offset = 0;
                              _entries.clear();
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
      final List<Map<String, dynamic>> newEntries = result
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .map((e) {
        // Precompute derived fields to reduce work in build.
        final tipo = (e['tipo'] ?? '').toString();
        final lower = tipo.toLowerCase();
        final isAct = lower.contains('activ') && !lower.contains('desactiv');
        final isDeact = lower.contains('desactiv');
        final creado = (e['created_at'] ?? e['fecha'] ?? '').toString();
        final creadoFmt = creado.isNotEmpty ? _formatDate(creado) : '';
        e['_isActivation'] = isAct;
        e['_isDeactivation'] = isDeact;
        e['_created_fmt'] = creadoFmt;
        return e;
      }).toList();
      final bool more = newEntries.length >= _limit;
      if (mounted) {
        setState(() {
          _entries.addAll(newEntries);
          _offset += _limit;
          _hasMore = more;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entradas'),
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
        itemCount: _entries.length + 1,
        itemBuilder: (context, index) {
          if (index < _entries.length) {
            final entry = _entries[index];
            final String tipo = (entry['tipo'] ?? 'Sin tipo').toString();
            final String modo = (entry['modo'] ?? 'Desconocido').toString();
            final String creado = (entry['created_at'] ?? 'Sin fecha').toString();
            final bool isActivation = (entry['_isActivation'] as bool?) ?? false;
            final bool isDeactivation = (entry['_isDeactivation'] as bool?) ?? false;
            final String creadoFmt = (entry['_created_fmt'] as String?) ?? _formatDate(creado);

            final IconData icon = isActivation
                ? Icons.toggle_on
                : isDeactivation
                    ? Icons.toggle_off
                    : Icons.info_outline;
            final Color color = isActivation
                ? Colors.green
                : isDeactivation
                    ? Colors.red
                    : Colors.blueGrey;

            return Card(
              key: ValueKey(entry['id'] ?? index),
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color),
                ),
                title: Text(
                  tipo.toUpperCase(),
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
                          'Fecha: $creadoFmt',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        Chip(
                          label: Text(modo.toUpperCase()),
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
                    'id': entry['id'],
                    'package_id': entry['package_id'],
                    'tipo': entry['tipo'],
                    'modo': entry['modo'],
                    'restaurada': entry['restaurada'],
                    'intentos_reactivacion': entry['intentos_reactivacion'],
                    'created_at': entry['created_at'],
                    'updated_at': entry['updated_at'],
                    'fecha': entry['fecha'],
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
                          title: 'Detalle de entrada',
                          data: data,
                          labels: const {
                            'id': 'ID',
                            'package_id': 'Paquete',
                            'tipo': 'Tipo',
                            'modo': 'Modo',
                            'restaurada': 'Restaurada',
                            'intentos_reactivacion': 'Intentos reactivación',
                            'fecha': 'Fecha de evento',
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

import 'dart:io' show HttpDate;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class SystemsDashboard extends StatefulWidget {
  final String? endpoint;
  const SystemsDashboard({super.key, this.endpoint});

  @override
  State<SystemsDashboard> createState() => _SystemsDashboardState();
}

class _SystemsDashboardState extends State<SystemsDashboard> {
  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _error;
  late final DateFormat _df = DateFormat('d MMM y HH:mm', 'es_ES');

  late String _endpoint;

  @override
  void initState() {
    super.initState();
    final base = widget.endpoint ?? ApiService.defaultBaseUrl;
    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    _endpoint = normalizedBase.endsWith('/systems') ? normalizedBase : '$normalizedBase/systems';
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<dynamic> result = await ApiService.fetchEntries(
        endpoint: _endpoint,
        limit: 1,
        offset: 0,
        filters: const {},
      );
      Map<String, dynamic>? rec;
      if (result.isNotEmpty) {
        final r0 = result.first;
        if (r0 is Map) {
          rec = Map<String, dynamic>.from(r0);
        }
      }
      setState(() {
        _data = rec;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmtDate(String raw) {
    try {
      DateTime? parsed = DateTime.tryParse(raw);
      parsed ??= HttpDate.parse(raw);
      return _df.format(parsed.toLocal());
    } catch (_) {
      return raw;
    }
  }

  String _fmtUptime(dynamic seconds) {
    final ms = (seconds is num) ? seconds.toInt() : int.tryParse(seconds.toString()) ?? 0;
    final s = ms ~/ 1000; // convert milliseconds to seconds
    final days = s ~/ (24 * 3600);
    final hrs = (s % (24 * 3600)) ~/ 3600;
    final mins = (s % 3600) ~/ 60;
    return '${days}d ${hrs}h ${mins}m';
  }

  String _fmtVoltage(dynamic mv) {
    // Input like 4148 -> 4.148 V
    final n = (mv is num) ? mv.toDouble() : double.tryParse(mv.toString()) ?? 0.0;
    final v = n / 1000.0;
    return '${v.toStringAsFixed(3)} V';
  }

  List<MapEntry<String, String>> _parseSensores(String raw) {
    // e.g. "102;1|103;0|104;1" -> [(102, activo 1), ...]
    final parts = raw.split('|');
    return parts.map((p) {
      final kv = p.split(';');
      final nombre = kv.isNotEmpty ? kv[0] : '';
      final estado = kv.length > 1 ? kv[1] : '';
      return MapEntry(nombre, estado);
    }).toList();
  }

  Widget _metricTile({required IconData icon, required String label, required String value, Color? color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: (color ?? Colors.blueGrey).withOpacity(0.15),
              child: Icon(icon, color: color ?? Colors.blueGrey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAA Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetch,
            tooltip: 'Recargar',
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(_error!),
                      const SizedBox(height: 8),
                      OutlinedButton(onPressed: _fetch, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : _data == null
                  ? const Center(child: Text('Sin datos'))
                  : Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información sobre el sistema SAA',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            // Última actualización
                            Builder(builder: (context) {
                              final pkgId = _data!['package_id'];
                              final updatedRaw = (_data!['updated_at'] ?? '').toString();
                              final updated = updatedRaw.isNotEmpty ? _fmtDate(updatedRaw) : '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'Ultima actualización $updated en el paquete $pkgId',
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                ),
                              );
                            }),

                            // Métricas principales
                            _metricTile(
                              icon: Icons.power,
                              label: 'Tiempo encendido',
                              value: _fmtUptime(_data!['TIEMPO_ENCENDIDO']),
                              color: Colors.green,
                            ),
                            _metricTile(
                              icon: Icons.bolt,
                              label: 'Voltaje en bateria de emergencia',
                              value: _fmtVoltage(_data!['GSM_VOLTAJE']),
                              color: Colors.orange,
                            ),
                            _metricTile(
                              icon: Icons.signal_cellular_alt,
                              label: 'Calidad de red móvil (CSQ)',
                              value: (_data!['GSM_CSQ'] ?? '').toString(),
                              color: Colors.blue,
                            ),
                            _metricTile(
                              icon: Icons.cloud_upload,
                              label: 'Envio FTP',
                              value: (_data!['GSM_FTP'] ?? '').toString(),
                              color: Colors.indigo,
                            ),
                            _metricTile(
                              icon: Icons.security,
                              label: 'Modo de acción',
                              value: ((_data!['MODO_ALARMA'] ?? 0).toString() == '1') ? 'Activada' : 'Desactivada',
                              color: Colors.redAccent,
                            ),
                            _metricTile(
                              icon: Icons.sensors,
                              label: 'Modo sensible',
                              value: ((_data!['MODO_SENSIBLE'] ?? 0).toString() == '1') ? 'Sí' : 'No',
                              color: Colors.purple,
                            ),
                            _metricTile(
                              icon: Icons.notifications_active,
                              label: 'Notificación alarma',
                              value: ((_data!['NOTIFICACION_ALARMA'] ?? 0).toString() == '1') ? 'Sí' : 'No',
                              color: Colors.deepOrange,
                            ),
                            _metricTile(
                              icon: Icons.notifications,
                              label: 'Notificacion alarma (Max. Diario 80)',
                              value: ((_data!['NOTIFICACION_SISTEMA'] ?? 0).toString() == '1') ? 'Sí' : 'No',
                              color: Colors.teal,
                            ),
                            _metricTile(
                              icon: Icons.move_to_inbox,
                              label: 'Paquetes enviados (Max. Diario 200)',
                              value: (_data!['PAQUETES_ENVIADOS'] ?? '').toString(),
                              color: Colors.cyan,
                            ),
                            _metricTile(
                              icon: Icons.sms,
                              label: 'SMS Diarios realizados (Max. 15)',
                              value: (_data!['SMS_DIARIOS'] ?? '').toString(),
                              color: Colors.lightBlue,
                            ),
                            _metricTile(
                              icon: Icons.restart_alt,
                              label: 'Proximo reinicio del sistema',
                              value: _fmtDate((_data!['FECHA_RESET'] ?? '').toString()),
                              color: Colors.brown,
                            ),

                            const SizedBox(height: 8),
                            Text('Módulos', style: Theme.of(context).textTheme.titleMedium),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  avatar: const Icon(Icons.bluetooth, size: 16),
                                  label: Text('Bluetooth: ${((_data!['MODULO_BLUETOOTH'] ?? 0).toString() == '1') ? 'Sí' : 'No'}'),
                                ),
                                Chip(
                                  avatar: const Icon(Icons.sd_card, size: 16),
                                  label: Text('SD: ${((_data!['MODULO_SD'] ?? 0).toString() == '1') ? 'Sí' : 'No'}'),
                                ),
                                Chip(
                                  avatar: const Icon(Icons.access_time, size: 16),
                                  label: Text('RTC: ${((_data!['MODULO_RTC'] ?? 0).toString() == '1') ? 'Sí' : 'No'}'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            Text('Sensores habilitados', style: Theme.of(context).textTheme.titleMedium),
                            Builder(builder: (context) {
                              final raw = (_data!['SENSORES_HABLITADOS'] ?? '').toString();
                              final list = raw.isNotEmpty ? _parseSensores(raw) : <MapEntry<String, String>>[];
                              if (list.isEmpty) return const Text('Sin sensores');
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: list.map((e) {
                                  final activo = e.value == '1';
                                  return Chip(
                                    avatar: Icon(
                                      activo ? Icons.check_circle : Icons.cancel,
                                      size: 16,
                                      color: activo ? Colors.green : Colors.red,
                                    ),
                                    label: Text('${e.key} ${activo ? 'activo' : 'inactivo'} ${e.value}'),
                                  );
                                }).toList(),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

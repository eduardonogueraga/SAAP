import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io' show HttpDate;

/// DetailInfo: Widget reutilizable para mostrar detalles en formato
/// clave-valor. Útil para hojas modales o pantallas de detalle.
class DetailInfo extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final Map<String, String>? labels;
  final Set<String> dateKeys;
  final String timeKey; // clave principal para mostrar en cabecera (hora evento)
  final EdgeInsetsGeometry padding;

  const DetailInfo({
    super.key,
    required this.title,
    required this.data,
    this.labels,
    this.dateKeys = const {},
    this.timeKey = 'fecha',
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
  });

  String _formatValue(String key, dynamic value) {
    if (value == null) return '—';

    if (dateKeys.contains(key)) {
      if (value is String) {
        DateTime? parsed = DateTime.tryParse(value);
        parsed ??= HttpDate.parse(value);
        final dt = parsed.toLocal();
        // Usa el locale por defecto configurado en main.dart (es_ES)
        final df = DateFormat('d MMM y HH:mm');
        return df.format(dt);
      }
    }

    if (key == 'restaurada') {
      if (value is num) return value != 0 ? 'Sí' : 'No';
      if (value is bool) return value ? 'Sí' : 'No';
    }
    if (value is bool) return value ? 'Sí' : 'No';
    return value.toString();
  }

  Iterable<MapEntry<String, dynamic>> _orderedEntries() {
    if (labels != null && labels!.isNotEmpty) {
      // Primero las claves que tengan etiqueta, en ese orden, luego el resto ordenado.
      final labeledKeys = labels!.keys.toList();
      final labeled = labeledKeys
          .where((k) => data.containsKey(k))
          .map((k) => MapEntry(k, data[k]));
      final others = data.entries
          .where((e) => !labeledKeys.contains(e.key))
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return [...labeled, ...others];
    }
    final entries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case 'id':
        return Icons.tag;
      case 'package_id':
        return Icons.inventory_2_outlined;
      case 'modo':
        return Icons.tune;
      case 'restaurada':
        return Icons.settings_backup_restore;
      case 'intentos_reactivacion':
        return Icons.refresh;
      case 'created_at':
        return Icons.event_available;
      case 'updated_at':
        return Icons.update;
      case 'fecha':
        return Icons.event;
      case 'tipo':
        return Icons.flag;
      default:
        return Icons.info_outline;
    }
  }

  (IconData, Color, String) _headerFromTipoAndTime(BuildContext context) {
    // Generic header for all cases
    final icon = Icons.info_outline;
    final color = Theme.of(context).colorScheme.primary;
    final headerTitle = title.isNotEmpty ? title : 'Detalle';
    return (icon, color, headerTitle);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _orderedEntries()
        .where((e) => e.key != 'deleted_at' && e.key != 'tipo' && e.key != timeKey)
        .toList();
    final (icon, color, bigTitle) = _headerFromTipoAndTime(context);
    final timeRaw = data[timeKey];
    String? timeFormatted;
    if (timeRaw is String) {
      try {
        DateTime? parsed = DateTime.tryParse(timeRaw);
        parsed ??= HttpDate.parse(timeRaw);
        final dt = parsed.toLocal();
        timeFormatted = DateFormat('d MMM y HH:mm').format(dt);
      } catch (_) {
        timeFormatted = timeRaw;
      }
    }

    return SafeArea(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado prominente
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bigTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                      ),
                      if (timeFormatted != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              timeFormatted,
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Lista de detalles
            Flexible(
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    final label = labels != null && labels!.containsKey(e.key)
                        ? labels![e.key]!
                        : e.key;
                    final value = _formatValue(e.key, e.value);
                    return ListTile(
                      dense: true,
                      leading: Icon(_iconForKey(e.key)),
                      title: Text(label),
                      subtitle: Text(value),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

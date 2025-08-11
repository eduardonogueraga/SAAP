import 'package:flutter/material.dart';
import '../widgets/data_button.dart';
import 'entries/entries_screen.dart';
import 'notices/notices_screen.dart';
import 'detections/detections_screen.dart';
import 'logs/logs_screen.dart';
import 'packages/packages_screen.dart';
import 'system_notices/system_notices_screen.dart';
import 'applogs/applogs_screen.dart';
import 'systems/systems_dashboard.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de datos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            DataButton(
              icon: Icons.calendar_today,
              label: 'Entradas',
              color: Colors.blue.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EntriesScreen()),
                );
              },
            ),
            DataButton(
              icon: Icons.visibility,
              label: 'Detecciones',
              color: Colors.orange.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DetectionsScreen()),
                );
              },
            ),
            DataButton(
              icon: Icons.mail,
              label: 'Mensajes',
              color: Colors.red.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NoticesScreen()),
                );
              },
            ),
            DataButton(
              icon: Icons.article,
              label: 'Logs',
              color: Colors.purple.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogsScreen()),
                );
              },
            ),
            DataButton(
              icon: Icons.window,
              label: 'Paquetes',
              color: Colors.teal.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PackagesScreen()),
                );
              },
            ),
            DataButton(
              icon: Icons.notifications,
              label: 'Notificaciones',
              color: Colors.amber.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SystemNoticesScreen()),
                );
              },
            ),
            DataButton(
              icon: Icons.info,
              label: 'SAA INFO',
              color: Colors.lightBlue.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SystemsDashboard()),
                );
              },
            ),
            DataButton(
              icon: Icons.list_alt,
              label: 'SAAS LOGS',
              color: Colors.green.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppLogsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

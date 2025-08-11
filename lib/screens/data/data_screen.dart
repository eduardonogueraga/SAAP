import 'package:flutter/material.dart';
import '../../widgets/data_button.dart';
import 'entries_screen.dart';
import 'notices_screen.dart';
import 'detections_screen.dart';
import 'logs_screen.dart';
import 'packages_screen.dart';
import 'system_notices_screen.dart';
import 'applogs_screen.dart';
import 'systems_dashboard.dart';

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
              color: Colors.indigo.shade500,
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
              color: Colors.indigo.shade600,
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
              color: Colors.indigo.shade700,
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
              color: Colors.indigo.shade400,
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
              color: Colors.indigo.shade800,
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
              color: Colors.indigo.shade300,
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
              color: Colors.indigo.shade200,
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
              color: Colors.indigo.shade900,
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

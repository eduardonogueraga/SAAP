import 'package:flutter/material.dart';
import '../widgets/data_button.dart';
import 'entries/entries_screen.dart';

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
              onTap: () {},
            ),
            DataButton(
              icon: Icons.mail,
              label: 'Mensajes',
              color: Colors.red.shade100,
              onTap: () {},
            ),
            DataButton(
              icon: Icons.article,
              label: 'Logs',
              color: Colors.purple.shade100,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

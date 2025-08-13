import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'alarm_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? latestEntry;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final entries = await ApiService.fetchEntries(
        endpoint: '${ApiService.defaultBaseUrl}/entries',
        limit: 1,
        offset: 0,
      );

      if (entries.isNotEmpty) {
        setState(() {
          latestEntry = entries.first;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => isLoading = false);
    }
  }

  String formatId(int id) => id.toString().padLeft(9, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Estado de la Alarma'),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : latestEntry == null
              ? const Center(
                  child: Text(
                    'No hay datos disponibles',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bloque 1: Estado de la alarma
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          latestEntry!['tipo'] == 'activacion'
                              ? 'La alarma está ACTIVADA'
                              : 'La alarma está DESACTIVADA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: latestEntry!['tipo'] == 'activacion'
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bloque 2: Botón de detalles
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AlarmDetailsScreen(entryId: latestEntry!['id']),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[800],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Ver detalles de la alarma',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  color: Colors.white54, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

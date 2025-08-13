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

  Widget buildAlarmStatusCard(bool isActive, double size) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlarmDetailsScreen(entryId: latestEntry!['id']),
          ),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: AssetImage('assets/images/alberquilla_01.jpeg'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            isActive ? "ALARMA ACTIVADA" : "ALARMA DESACTIVADA",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold, // Letra más gruesa
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 5,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String formatId(int id) => id.toString().padLeft(9, '0');

  @override
  Widget build(BuildContext context) {
    double cardSize = MediaQuery.of(context).size.height * 0.5;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: isLoading
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Recuadro de la alarma (mitad de la pantalla)
                        buildAlarmStatusCard(
                          latestEntry!['tipo'] == 'activacion',
                          cardSize,
                        ),
                        const SizedBox(height: 20),

                        // Botón de detalles
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
      ),
    );
  }
}

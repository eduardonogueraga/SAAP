import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
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
    // Add listener for when the app returns to the foreground
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == AppLifecycleState.resumed.toString() && mounted) {
        await _loadData();
      }
      return null;
    });
  }

  Future<void> _navigateToAlarmDetails() async {
    if (latestEntry != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlarmDetailsScreen(entryId: latestEntry!['id']),
        ),
      );
      // Refresh data when returning from details screen
      if (mounted) {
        await _loadData();
      }
    }
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

String _formatDate(String? dateString) {
  if (dateString == null) return '';
  try {
    // Quitar ' GMT' porque DateFormat no lo reconoce
    final cleanedDate = dateString.replaceAll(' GMT', '');
    
    // Parse usando intl
    final parsedDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US')
        .parseUtc(cleanedDate)
        .toLocal();
    
    final day = parsedDate.day.toString().padLeft(2, '0');
    final month = _getMonthName(parsedDate.month);
    return '$day $month';
  } catch (e) {
    print('Error formatting date $dateString: $e');
    return '';
  }
}
  String _getMonthName(int month) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[month - 1];
  }

  Widget buildAlarmStatusCard(bool isActive, double size) {
    final createdAt = latestEntry?['fecha']?.toString() ?? latestEntry?['created_at']?.toString();
    final formattedDate = _formatDate(createdAt);
        
    // Determine alarm status based on 'tipo' field
    final alarmStatus = latestEntry?['tipo']?.toString() ?? '';
    final isAlarmActive = alarmStatus == 'activacion';
    
    // Debug prints
    if (kDebugMode) {
      print('Latest entry: $latestEntry');
      print('Alarm status: $alarmStatus');
      print('Created at: $createdAt');
      print('Formatted date: $formattedDate');
    }

    return GestureDetector(
      onTap: () {
        _navigateToAlarmDetails();
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
        child: Stack(
          children: [
            Center(
              child: Text(
                isAlarmActive ? "ALARMA ACTIVADA" : "ALARMA DESACTIVADA",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 15,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Alberquilla, Librilla',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 5,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                    Text(
                      'Última visita: $formattedDate',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 5,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatId(int id) => id.toString().padLeft(9, '0');

  @override
  Widget build(BuildContext context) {
    double cardSize = MediaQuery.of(context).size.height * 0.5;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

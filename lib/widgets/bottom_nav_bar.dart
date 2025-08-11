import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

@override
Widget build(BuildContext context) {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    onTap: onTap,
    type: BottomNavigationBarType.fixed,
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home), 
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.insert_chart),
        label: 'Datos',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.window), 
        label: 'Paquetes',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.notifications), 
        label: 'Avisos',
      ),
    ],
  );
}
}

import 'package:flutter/material.dart';

class FullScreenSplash extends StatelessWidget {
  final void Function(String selectedLocation) onUpdate;

  const FullScreenSplash({super.key, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final locations = ['Nagercoil', 'Manakudy', 'Marthandam'];

    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEae6de),
        title: const Text(
          'Select Location',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003780)),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          ...locations.map((location) {
            return ListTile(
              title: Text(
                location,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003780)),
              ),
              onTap: () => onUpdate(location),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

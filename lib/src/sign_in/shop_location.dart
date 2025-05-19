import 'package:flutter/material.dart';

class ShopSelectionSplash extends StatelessWidget {
  final Function(String) onSelect;

  const ShopSelectionSplash({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final List<String> shops = [
      'Nagercoil',
      'Manakudy',
      'Marthandam',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEae6de),
        title: const Text(
          'Select Nearest location',
          style: TextStyle(
              color: Color(0xFF003780),
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: shops.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                shops[index],
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.store, color: Color(0xFF003780)),
              trailing:
                  const Icon(Icons.arrow_forward, color: Color(0xFF003780)),
              onTap: () => onSelect(shops[index]),
            ),
          );
        },
      ),
    );
  }
}

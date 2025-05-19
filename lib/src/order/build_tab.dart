import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  final int currentPage;
  final Function(int) onTabChanged;
  final List<String> tabTitles;

  const CustomTabBar({
    super.key,
    required this.currentPage,
    required this.onTabChanged,
    required this.tabTitles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEae6de),
      padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabTitles.length, (index) {
          return GestureDetector(
            onTap: () => onTabChanged(index),
            child: Column(
              children: [
                Text(
                  tabTitles[index],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: currentPage == index
                        ? const Color(0xFF003780)
                        : const Color(0xFF003780),
                  ),
                ),
                const SizedBox(height: 4),
                currentPage == index
                    ? Container(height: 3, width: 100, color: Colors.black)
                    : const SizedBox(height: 3),
              ],
            ),
          );
        }),
      ),
    );
  }
}

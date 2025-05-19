import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/new/favor_shops.dart';
import 'package:sea_shop/new/fish_shop.dart';
import 'package:sea_shop/src/profile/new_profile.dart';

class Nav extends StatefulWidget {
  const Nav({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<Nav> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  User? _user;

  final List<Widget> _pages = [
    const FishShops(),
    const FavShops(),
    const ProfilePages(),
  ];

  @override
  @override
  void initState() {
    super.initState();

    _checkUserAuthentication();
  }

  void _checkUserAuthentication() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/sign_in');
      });
    } else {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        bool? detailsSave = data['detailsSaved'];

        if (detailsSave == false || detailsSave == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/user');
          });
        }
      }
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _user != null
          ? _pages[_currentIndex]
          : const SizedBox(height: double.infinity, width: double.infinity),
      bottomNavigationBar: _user != null
          ? BottomNavigationBar(
              backgroundColor: const Color(0xFFEae6de),
              selectedItemColor: const Color(0xFF003780),
              unselectedItemColor: Colors.grey,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.store),
                  label: LocalizationService().translate('Shops'),
                  backgroundColor: Colors.white,
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'FavShops',
                  backgroundColor: Colors.white,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person),
                  label: LocalizationService().translate('profile'),
                  backgroundColor: Colors.white,
                ),
              ],
            )
          : null,
    );
  }
}

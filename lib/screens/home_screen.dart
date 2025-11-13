import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_router.dart';
import 'profile_screen.dart'; // <-- 1. ADDED THIS IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // This is the list of all the main pages you described
  static final List<Widget> _pages = <Widget>[
    // Page 1: Job Management
    const Center(
      child: Text(
        'Job Management Screen',
        style: TextStyle(fontSize: 24),
      ),
    ),

    // Page 2: Earnings Dashboard
    const Center(
      child: Text(
        'Earnings Screen',
        style: TextStyle(fontSize: 24),
      ),
    ),

    // Page 3: Profile Management
    const ProfileScreen(), // <-- 2. REPLACED THE PLACEHOLDER
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Therapist Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, Routes.signIn, (_) => false);
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          )
        ],
      ),
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
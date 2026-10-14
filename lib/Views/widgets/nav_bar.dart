import 'package:flutter/material.dart';
import 'package:stardy_app/Views/Pages/home.dart';
import 'package:stardy_app/Views/Pages/learn_page.dart';
import 'package:stardy_app/Views/Pages/opportunity_page.dart';
import 'package:stardy_app/Views/Pages/profile.dart';
import '../widgets/chatbot_fab.dart';
import '../widgets/glass_navbar.dart';

class NavbarPage extends StatefulWidget {
  const NavbarPage({super.key});

  @override
  State<NavbarPage> createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    Learnpage(),
    OpportunitiesPage(),
    ProfilePage(),
  ];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_currentIndex],

          const StarbuddyFabButton(),

          GlassNavbar(currentIndex: _currentIndex, onTap: _onTap),
        ],
      ),
    );
  }
}

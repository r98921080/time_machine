import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/nutrition/chat_screen.dart';
import '../screens/goals/goals_screen.dart';
import '../screens/character/character_screen.dart';
import '../screens/vlog/vlog_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    ChatScreen(),
    GoalsScreen(),
    CharacterScreen(),
    VlogScreen(),
  ];

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: '首頁',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.restaurant_outlined),
      activeIcon: Icon(Icons.restaurant),
      label: '飲食',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.track_changes_outlined),
      activeIcon: Icon(Icons.track_changes),
      label: '目標',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: '角色',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.play_circle_outline),
      activeIcon: Icon(Icons.play_circle),
      label: 'Vlog',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _items
            .map((item) => NavigationDestination(
                  icon: item.icon,
                  selectedIcon: item.activeIcon ?? item.icon,
                  label: item.label!,
                ))
            .toList(),
      ),
    );
  }
}

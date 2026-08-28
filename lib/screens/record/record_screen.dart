import 'package:flutter/material.dart';
import '../nutrition/chat_screen.dart';
import '../diary/diary_screen.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('記錄'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.restaurant), text: '飲食'),
              Tab(icon: Icon(Icons.book_outlined), text: '日記'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ChatScreen(embedded: true),
            DiaryScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}

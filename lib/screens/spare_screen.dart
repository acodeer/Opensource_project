// lib/screens/spare_screen.dart

import 'package:flutter/material.dart';
import 'package:untitled/screens/settings_screen.dart'; // 환경설정 화면을 import 합니다.

class SpareScreen extends StatelessWidget {
  const SpareScreen({super.key});

  // 환경설정 화면으로 이동하는 함수
  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('예비화면'),
        actions: [
          // 오른쪽 위에 환경설정 아이콘 버튼 추가
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(context), // 클릭 시 환경설정 화면으로 이동
          ),
        ],
      ),
      body: const Center(
        child: Text('예비화면 내용',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
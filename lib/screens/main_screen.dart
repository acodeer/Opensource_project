// lib/screens/main_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart'; // HomeScreen을 본문으로 사용

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 로그아웃 함수
  Future<void> _logout() async {
    try {
      // 구글 로그아웃 (다음 로그인 시 계정 선택 창이 뜨도록 함)
      await GoogleSignIn().signOut();
      // 파이어베이스 로그아웃
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 중 오류 발생: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.displayName ?? '메인 화면'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout, // 로그아웃 함수 연결
            tooltip: '로그아웃',
          ),
        ],
      ),
      // MainScreen의 본문은 HomeScreen이 담당하도록 구조화
      body: HomeScreen(
        onNavigateToSpare: () {
          // 예비화면 기능이 필요하다면 여기에 로직 추가
        },
      ),
    );
  }
}
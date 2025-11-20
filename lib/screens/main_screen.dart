// lib/screens/main_screen.dart (수정)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'board_screen.dart'; // 탭 0
import 'chat_list_screen.dart'; // 탭 1
import 'settings_screen.dart'; // 탭 2

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 현재 선택된 탭 인덱스

  // 탭에 표시할 화면 리스트
  final List<Widget> _screens = [
    const BoardScreen(),
    ChatListScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 기존 로그아웃 함수는 SettingsScreen으로 이동시키거나,
  // MainScreen에서 관리하고 SettingsScreen에 콜백으로 넘겨줄 수 있습니다.
  // 여기서는 SettingsScreen에서 직접 호출하도록 구조를 단순화합니다.

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? '자유 게시판' : (_selectedIndex == 1 ? '채팅' : '환경 설정')),
        // AppBar의 로그아웃 버튼은 SettingsScreen으로 옮깁니다.
        // actions: [ 기존 로그아웃 버튼 제거 ],
      ),

      // IndexedStack을 사용하여 탭 전환 시 화면 상태를 유지합니다.
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // 하단 탭 바
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '게시판',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '설정',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
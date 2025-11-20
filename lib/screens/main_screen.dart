import 'package:flutter/material.dart';

// ★ 아래 4개의 파일이 lib/screens 폴더 안에 있어야 하며,
// 각 파일 내부의 클래스 이름이 아래와 일치해야 합니다.
import 'home_screen.dart';      // 클래스명: KboSchedulePage
import 'chat_list_screen.dart'; // 클래스명: ChatListScreen
import 'board_screen.dart';     // 클래스명: BoardScreen
import 'settings_screen.dart';  // 클래스명: SettingsScreen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 현재 선택된 탭의 인덱스 (0: 홈, 1: 채팅, 2: 게시판, 3: 설정)
  int _selectedIndex = 0;

  // 탭별로 보여줄 화면 리스트
  // ★ 주의: home_screen.dart 안에 있는 클래스 이름은 'KboSchedulePage'여야 합니다.
  final List<Widget> _pages = [
    const KboSchedulePage(), // 1. 홈 (KBO 일정)
    ChatListScreen(),        // 2. 채팅 목록
    const BoardScreen(),     // 3. 게시판
    const SettingsScreen(),  // 4. 설정
  ];

  // 탭을 눌렀을 때 실행되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 현재 인덱스에 맞는 화면을 body에 표시
      body: _pages[_selectedIndex],

      // 하단 네비게이션 바 설정
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 탭이 4개 이상이므로 fixed 필수
        backgroundColor: Colors.white,       // 바 배경색
        selectedItemColor: Colors.blue[900], // 선택된 아이콘 색상 (KBO 파랑)
        unselectedItemColor: Colors.grey,    // 선택 안 된 아이콘 색상
        showUnselectedLabels: true,          // 선택 안 된 라벨도 보이게 설정
        currentIndex: _selectedIndex,        // 현재 선택된 인덱스
        onTap: _onItemTapped,                // 탭 클릭 시 함수 실행
        elevation: 10,                       // 그림자 효과
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt),
            label: '게시판',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
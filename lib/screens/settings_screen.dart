// lib/screens/settings_screen.dart (수정)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // MainScreen에서 가져온 로그아웃 기능
  Future<void> _logout() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      // main.dart의 StreamBuilder가 로그아웃을 감지하여 LoginScreen으로 자동 전환됩니다.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 중 오류 발생: $e')),
        );
      }
    }
  }

  // 임시 My Post 화면으로 이동하는 함수 (구현 필요)
  void _navigateToMyPosts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: 내가 쓴 글 목록 화면으로 이동')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보 요약
          ListTile(
            leading: CircleAvatar(
              child: Text(user?.displayName?.substring(0, 1) ?? '?', style: const TextStyle(fontSize: 20)),
            ),
            title: Text(user?.displayName ?? '익명 사용자', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user?.email ?? '로그인 정보 없음'),
            contentPadding: const EdgeInsets.all(16.0),
          ),
          const Divider(),
          // 내 활동 메뉴
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('내가 쓴 게시글'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToMyPosts,
          ),
          ListTile(
            leading: const Icon(Icons.comment),
            title: const Text('내가 쓴 댓글'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {/* TODO: 내 댓글 조회 */},
          ),
          const Divider(),
          // 설정 및 기타
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('앱 환경설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {/* TODO: 상세 설정 */},
          ),
          // 로그아웃 버튼
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
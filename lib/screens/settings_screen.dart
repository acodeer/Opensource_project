import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// ★ LoginScreen에서 정의한 WEB_CLIENT_ID를 가져오기 위해 import 합니다.
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // 로그아웃 처리 함수
  Future<void> _logout(BuildContext context) async {
    try {
      // 1. GoogleSignIn 인스턴스를 명시적으로 생성하며, WEB_CLIENT_ID를 전달합니다.
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: WEB_CLIENT_ID, // ★ 웹 환경에서 Assertion 오류 방지
      );

      // 2. Google 세션 상태를 로그아웃 처리
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      }

      // 3. Firebase 인증 상태 로그아웃
      await FirebaseAuth.instance.signOut();

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
        backgroundColor: Colors.white, // 앱바는 깔끔하게 흰색
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // ★ 수정된 프로필 영역 (커스텀 디자인) ★
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.grey[900], // 야간 경기장 컨셉 배경
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 프로필 사진 (가운데 정렬)
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 16),

                // 닉네임 (가운데 정렬)
                Text(
                  user?.displayName ?? '승리요정', // ★ '야구팬' -> '승리요정' 변경
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                // 이메일 (있으면 표시)
                if (user?.email != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    user!.email!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 설정 메뉴 리스트
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // 알림 설정 로직 (추후 구현)
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('프로필 수정'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // 프로필 수정 로직 (추후 구현)
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('앱 정보'),
            trailing: const Text('v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {},
          ),
          const Divider(),

          // 로그아웃 버튼
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('로그아웃', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
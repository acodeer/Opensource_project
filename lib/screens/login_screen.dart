// lib/screens/login_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 의존성 버전에 맞춰 인스턴스를 생성하는 것이 안정적일 수 있습니다.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? "581600224420-7hnolsn2e6f2vv62d2rlor8hjbh218qa.apps.googleusercontent.com"

        : null,
  );
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    // 로딩 중일 때 버튼이 다시 눌리는 것을 방지
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // 사용자가 로그인을 취소한 경우
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      await _auth.signInWithCredential(credential);

      // 로그인 성공 시 main.dart의 StreamBuilder가 화면을 전환하므로
      // 여기서 별도의 화면 이동 코드는 필요 없습니다.
      // 위젯이 unmount될 수 있으므로 이후 코드는 실행되지 않을 수 있습니다.

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 오류: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('내 손안의 게시판',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
            const SizedBox(height: 10),
            Text('구글 계정으로 간편하게 시작하세요',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(250, 50),
                elevation: 1.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // assets 폴더에 로고가 없다면 오류가 발생할 수 있습니다.
                  // Image.asset('assets/google_logo.png', height: 22.0),
                  Icon(Icons.login), // 이미지가 없다면 아이콘으로 대체
                  const SizedBox(width: 12),
                  const Text('Google 계정으로 로그인', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

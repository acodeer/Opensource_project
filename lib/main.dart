// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
// 기존에 오류를 유발했던 웹뷰 관련 import 및 platform.dart import는 모두 제거되었습니다.

// 화면 파일들 import
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ★ 웹뷰 플랫폼 등록 로직 제거됨: Android 빌드 시 웹 코드를 참조하지 않습니다.

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '(직관)갈래말래',
      debugShowCheckedModeBanner: false,
      // 앱 전체 테마 설정
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black, // 앱바 검은색 통일
          foregroundColor: Colors.white,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const MainScreen(); // 로그인 됨 -> 메인 화면
          }
          return const LoginScreen(); // 로그인 안됨 -> 로그인 화면
        },
      ),
    );
  }
}
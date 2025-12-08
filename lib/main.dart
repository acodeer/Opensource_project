// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
// import 'package:flutter/foundation.dart'; // kDebugMode를 사용하기 위해 추가 - 이 import는 더 이상 필요 없습니다.

// 화면 파일들 import
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      // 💡 [수정] kDebugMode 시 로그인 상태와 관계없이 MainScreen으로 바로 이동하는 로직을 제거했습니다.
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
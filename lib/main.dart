// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // firebase_options.dart 파일
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  // Flutter 엔진과 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase 초기화
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
      title: 'Flutter Firebase Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder(
        // 사용자의 인증 상태 변경을 실시간으로 감지
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 연결 중일 때는 로딩 화면 표시
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 로그인된 사용자가 있으면 MainScreen으로 이동
          if (snapshot.hasData) {
            return const MainScreen();
          }
          // 로그인된 사용자가 없으면 LoginScreen으로 이동
          return const LoginScreen();
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // 파이어베이스 설정 파일 (자동생성된 것)

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
      // 앱 전체 테마 설정 (기본적으로 어두운 톤의 앱바 등)
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black, // 앱바 검은색 통일
          foregroundColor: Colors.white,
        ),
      ),
      // 로그인 상태 감지 스트림
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
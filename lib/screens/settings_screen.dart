import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import '../models/user_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 로드된 Firestore 기반 UserModel을 저장할 변수
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Firestore에서 사용자 데이터 로드 및 초기 문서 생성
  Future<void> _loadUserData() async {
    final authUser = _auth.currentUser;
    if (authUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(authUser.uid).get();

      if (doc.exists) {
        // 1. Firestore 데이터가 있을 경우 로드
        _userModel = UserModel.fromFirestore(doc);
      } else {
        // 2. Firestore 데이터가 없을 경우 (첫 로그인 등), Auth 데이터를 기반으로 생성
        _userModel = UserModel.fromFirebaseAuth(authUser);
        // Firestore에 초기 데이터 저장
        await _firestore.collection('users').doc(authUser.uid).set(_userModel!.toFirestore());
      }
    } catch (e) {
      print("사용자 데이터 로드 실패: $e");
      // 실패 시 최소한 Auth 데이터를 기반으로 표시
      _userModel = UserModel.fromFirebaseAuth(authUser);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 닉네임 수정 다이얼로그 표시
  void _showNicknameDialog() {
    final TextEditingController controller = TextEditingController(text: _userModel?.displayName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('닉네임 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '새로운 닉네임을 입력하세요'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final newNickname = controller.text.trim();
              if (newNickname.isNotEmpty && newNickname != _userModel?.displayName) {
                _updateNickname(newNickname);
              }
              Navigator.pop(ctx);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // 닉네임 업데이트 로직 (Auth 및 Firestore 동시 업데이트)
  Future<void> _updateNickname(String newNickname) async {
    final authUser = _auth.currentUser;
    if (authUser == null) return;

    try {
      // 1. Firebase Auth 프로필 업데이트 (displayName)
      await authUser.updateDisplayName(newNickname);

      // 2. Firestore 문서 업데이트
      await _firestore.collection('users').doc(authUser.uid).update({
        'displayName': newNickname,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. UI 상태 업데이트 (데이터 새로고침)
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임이 성공적으로 변경되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('닉네임 변경 실패: $e')));
      }
    }
  }

  // 기존 로그아웃 함수
  Future<void> _logout() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: WEB_CLIENT_ID,
      );

      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      }
      await _auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final userModel = _userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 1. 프로필 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.grey[900],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 프로필 사진
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: userModel?.photoURL != null ? NetworkImage(userModel!.photoURL!) : null,
                  child: userModel?.photoURL == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 16),

                // 닉네임
                Text(
                  userModel?.displayName ?? '승리요정',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                // 이메일
                if (userModel?.email != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    userModel!.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 2. 설정 메뉴 리스트
          const SizedBox(height: 10),

          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {},
          ),

          // ★ '프로필 수정'에 닉네임 수정 기능 통합
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('프로필 수정 (닉네임)'), // 기능을 명확히 표시
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(userModel?.displayName ?? '설정 필요', style: TextStyle(color: Colors.grey[600])),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: _showNicknameDialog, // 닉네임 수정 다이얼로그 호출
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('앱 정보'),
            trailing: const Text('v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {},
          ),
          const Divider(),

          // 3. 로그아웃 버튼
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('로그아웃', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
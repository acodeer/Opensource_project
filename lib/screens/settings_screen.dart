import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  UserModel? _userModel;
  bool _isLoading = true;
  File? _profileImage;

  // 10개 팀 목록 (Dropdown에 사용)
  final List<String> teams = [
    '두산 베어스',
    'LG 트윈스',
    '키움 히어로즈',
    'SSG 랜더스',
    'KIA 타이거즈',
    '삼성 라이온즈',
    '롯데 자이언츠',
    '한화 이글스',
    'NC 다이노스',
    'KT 위즈',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authUser = _auth.currentUser;
    if (authUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(authUser.uid).get();

      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);

        // favoriteTeam 값이 유효하지 않으면 기본값으로 보정
        final fav = _userModel?.favoriteTeam;
        if (fav != null && fav.isNotEmpty && !teams.contains(fav)) {
          await _firestore.collection('users').doc(authUser.uid).update({
            'favoriteTeam': teams.first,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          _userModel = _userModel!.copyWith(favoriteTeam: teams.first);
        }
      } else {
        _userModel = UserModel.fromFirebaseAuth(authUser);
        await _firestore.collection('users').doc(authUser.uid).set(_userModel!.toFirestore());
      }
    } catch (e) {
      print("사용자 데이터 로드 실패: $e");
      _userModel = UserModel.fromFirebaseAuth(authUser);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      await _uploadProfileImage();
    }
  }

  Future<void> _uploadProfileImage() async {
    final authUser = _auth.currentUser;
    if (authUser == null || _profileImage == null) return;

    try {
      final ref = _storage.ref().child('profile_images/${authUser.uid}.jpg');
      await ref.putFile(_profileImage!);
      final downloadUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(authUser.uid).update({
        'photoURL': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await authUser.updatePhotoURL(downloadUrl);

      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 사진이 변경되었습니다.')),
        );
      }
    } catch (e) {
      print("프로필 사진 업로드 실패: $e");
    }
  }

  void _showProfileEditDialog() {
    final nicknameController = TextEditingController(text: _userModel?.displayName);
    final bioController = TextEditingController(text: _userModel?.bio ?? '');
    String selectedTeam = (_userModel?.favoriteTeam != null &&
        teams.contains(_userModel!.favoriteTeam))
        ? _userModel!.favoriteTeam!
        : teams.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('프로필 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nicknameController,
                  decoration: const InputDecoration(labelText: '닉네임'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: '자기소개'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTeam,
                  items: teams.map((team) {
                    return DropdownMenuItem(
                      value: team,
                      child: Text(team),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setLocalState(() => selectedTeam = value);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: '응원팀',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            TextButton(
              onPressed: () async {
                await _updateProfile(
                  nicknameController.text.trim(),
                  bioController.text.trim(),
                  selectedTeam,
                );
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile(String nickname, String bio, String team) async {
    final authUser = _auth.currentUser;
    if (authUser == null) return;

    try {
      if (nickname.isNotEmpty) {
        await authUser.updateDisplayName(nickname);
      }

      await _firestore.collection('users').doc(authUser.uid).update({
        'displayName': nickname,
        'bio': bio,
        'favoriteTeam': team,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 성공적으로 변경되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 변경 실패: $e')),
        );
      }
    }
  }

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

    final ImageProvider<Object>? backgroundImage = _profileImage != null
        ? FileImage(_profileImage!)
        : (userModel?.photoURL != null
        ? NetworkImage(userModel!.photoURL!) as ImageProvider<Object>? // NetworkImage를 ImageProvider로 명시적 캐스팅
        : null);

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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(color: Colors.grey[900]),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      // ★ 수정된 backgroundImage 변수 사용
                      backgroundImage: backgroundImage,
                      child: (_profileImage == null && userModel?.photoURL == null)
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text("프로필 사진 변경", style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userModel?.displayName ?? '익명 팬',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    if (userModel?.bio != null && userModel!.bio!.isNotEmpty) ...[
        const SizedBox(height: 6),
    Text(
    userModel!.bio!,
    style: TextStyle(fontSize: 14, color: Colors.grey[300]),
    textAlign: TextAlign.center,
    ),
    ],
                if (userModel?.favoriteTeam != null && userModel!.favoriteTeam!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    "응원팀: ${userModel!.favoriteTeam!}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
                if (userModel?.email.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    userModel!.email,
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ],
            ),
            ),

              const SizedBox(height: 10),

              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('알림 설정'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {},
              ),

              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('프로필 수정'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: _showProfileEditDialog,
              ),

              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('앱 정보'),
                trailing: const Text('v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {},
              ),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  '로그아웃',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                onTap: _logout,
              ),
            ],
        ),
    );
  }
}
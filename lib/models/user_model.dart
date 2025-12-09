// lib/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  // ★ 향후 추가될 사용자 정의 필드 예시
  final String? preferredTeam;
  final int partyCount;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.preferredTeam,
    this.partyCount = 0,
  });

  // 1. Firebase Auth User 객체로부터 모델 생성
  factory UserModel.fromFirebaseAuth(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '익명 팬',
      photoURL: user.photoURL,
    );
  }

  // 2. Firestore DocumentSnapshot으로부터 모델 생성
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    // Firestore 문서에서 사용자 정의 필드를 안전하게 가져옵니다.
    return UserModel(
      uid: doc.id,
      email: data?['email'] ?? '',
      displayName: data?['displayName'] ?? '익명 팬',
      photoURL: data?['photoURL'],
      preferredTeam: data?['preferredTeam'],
      partyCount: data?['partyCount'] ?? 0,
    );
  }

  // 3. Firestore 저장을 위한 Map 변환
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'preferredTeam': preferredTeam,
      'partyCount': partyCount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
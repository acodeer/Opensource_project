// lib/models/match_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// --- 데이터 모델 ---
class Game {
  final String gameId;
  final String homeTeam;
  final String awayTeam;
  final DateTime date;
  final String stadium;

  Game({
    required this.gameId,
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
    required this.stadium,
  });
}

class MatchParty {
  final String matchId;
  final String gameId;
  final String ownerName;
  final String seatPref;
  final int maxPlayers;
  final List<String> participants;
  final List<String> participantUids;
  final List<String> tags;
  final Timestamp createdAt; // ★ Firestore 정렬을 위해 추가

  MatchParty({
    required this.matchId,
    required this.gameId,
    required this.ownerName,
    required this.seatPref,
    required this.maxPlayers,
    required this.participants,
    required this.participantUids,
    required this.tags,
    required this.createdAt, // ★ 생성자에 추가
  });

  // Firestore DocumentSnapshot으로부터 객체를 생성하는 Factory
  factory MatchParty.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchParty(
      matchId: doc.id,
      gameId: data['gameId'] ?? '',
      ownerName: data['ownerName'] ?? '익명 방장',
      seatPref: data['seatPref'] ?? '상관없음',
      maxPlayers: data['maxPlayers'] ?? 4,
      participants: List<String>.from(data['participants'] ?? []),
      participantUids: List<String>.from(data['participantUids'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(), // ★ 파싱 로직 추가
    );
  }
}
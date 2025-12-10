import 'package:cloud_firestore/cloud_firestore.dart';

// --- 경기 정보 모델 ---
class Game {
  final String gameId;
  final String homeTeam;
  final String awayTeam;
  final DateTime date;
  final String stadium;

  // ★ 추가된 필드들 (경기 결과 및 취소 여부)
  final bool isFinished;  // 경기 종료 여부
  final bool isCancelled; // 경기 취소 여부
  final int? homeScore;   // 홈팀 점수
  final int? awayScore;   // 원정팀 점수
  final String? homePitcher; // 홈팀 투수 (선발/승/패)
  final String? awayPitcher; // 원정팀 투수 (선발/승/패)

  Game({
    required this.gameId,
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
    required this.stadium,
    this.isFinished = false, // 기본값: 진행 전
    this.isCancelled = false, // 기본값: 취소 안됨
    this.homeScore,
    this.awayScore,
    this.homePitcher,
    this.awayPitcher,
  });
}

// --- 파티 정보 모델 ---
class MatchParty {
  final String matchId;
  final String gameId;
  final String ownerUid;
  final String ownerName;
  final String seatPref;
  final int maxPlayers;
  final List<String> participants;
  final List<String> participantUids;
  final List<String> tags;
  final Timestamp createdAt; // 정렬을 위한 생성 시간
  final String status;

  MatchParty({
    required this.matchId,
    required this.gameId,
    required this.ownerUid,
    required this.ownerName,
    required this.seatPref,
    required this.maxPlayers,
    required this.participants,
    required this.participantUids,
    required this.tags,
    required this.createdAt,
    required this.status,
  });

  // Firestore 문서 -> 객체 변환 (Factory Constructor)
  factory MatchParty.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchParty(
      matchId: doc.id,
      gameId: data['gameId'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      ownerName: data['ownerName'] ?? '익명 방장',
      seatPref: data['seatPref'] ?? '상관없음',
      maxPlayers: data['maxPlayers'] ?? 4,
      participants: List<String>.from(data['participants'] ?? []),
      participantUids: List<String>.from(data['participantUids'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      status: data['status'] ?? 'searching',
    );
  }
}
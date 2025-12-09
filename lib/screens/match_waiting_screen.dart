// lib/screens/match_waiting_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ★ Firestore 추가
import 'package:firebase_auth/firebase_auth.dart';
import '../models/match_model.dart'; // ★ 모델 import
import 'chat_room_screen.dart';

class MatchWaitingScreen extends StatefulWidget {
  final String partyId; // ★ 파티 ID로 변경
  final Game game;        // 경기 정보

  const MatchWaitingScreen({
    super.key,
    required this.partyId, // ★ ID로 변경
    required this.game,
  });

  @override
  State<MatchWaitingScreen> createState() => _MatchWaitingScreenState();
}

class _MatchWaitingScreenState extends State<MatchWaitingScreen> {
  final _firestore = FirebaseFirestore.instance;

  void _joinChatRoom(MatchParty party) {
    // 채팅방으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          chatRoomId: party.matchId, // 파티 ID를 채팅방 ID로 사용
          chatRoomTitle: "${widget.game.homeTeam} vs ${widget.game.awayTeam} 팟",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ★ Firestore StreamBuilder로 파티 문서 구독
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('match_parties').doc(widget.partyId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.grey,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // 오류 처리: 문서가 없거나 오류 발생 시
        if (!snapshot.hasData || !snapshot.data!.exists || snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('오류')),
            body: const Center(child: Text('파티를 찾을 수 없습니다.')),
          );
        }

        // 1. 실시간 파티 데이터 추출
        final party = MatchParty.fromFirestore(snapshot.data!);

        // 2. 현재 인원 / 최대 인원
        int currentMemberCount = party.participants.length;
        int maxMemberCount = party.maxPlayers;
        bool isFull = currentMemberCount >= maxMemberCount;

        return Scaffold(
          backgroundColor: Colors.grey[900],
          appBar: AppBar(
            title: const Text('매칭 대기방'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // 1. 경기 정보 카드
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Row(
                    children: [
                      // 팀 로고 (이니셜)
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue[900],
                        child: Text(
                          widget.game.homeTeam.substring(0, 1),
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.game.homeTeam} vs ${widget.game.awayTeam}",
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${widget.game.stadium} | ${party.seatPref}",
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 2. 상태 메시지 (실시간 갱신)
                Text(
                  isFull ? "매칭이 완료되었습니다! 🎉" : "멤버를 기다리고 있어요...",
                  style: TextStyle(
                    color: isFull ? Colors.greenAccent : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "$currentMemberCount / $maxMemberCount 명 참여 중",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 40),

                // 3. 참여자 리스트 (실시간 갱신)
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: List.generate(maxMemberCount, (index) {
                    if (index < currentMemberCount) {
                      // 참여자가 있는 슬롯
                      final participantName = party.participants[index];
                      return Column(
                        children: [
                          const CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.person, color: Colors.white, size: 35),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            participantName,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      );
                    } else {
                      // 빈 슬롯
                      return Column(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.grey[800],
                            child: Icon(Icons.add, color: Colors.grey[600], size: 30),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "대기 중",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      );
                    }
                  }),
                ),

                const Spacer(),

                // 4. 채팅방 입장 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFull ? Colors.green[700] : Colors.blue[900],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble),
                    label: const Text(
                      "채팅방 입장하기",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _joinChatRoom(party), // ★ 파티 객체를 전달
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // 목록으로 돌아가기
                  },
                  child: const Text("목록으로 돌아가기", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
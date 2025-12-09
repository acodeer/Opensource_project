import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'home_screen.dart'; // ★ 기존 import 제거
import '../models/match_model.dart'; // ★ 새 모델 파일 import
import 'chat_room_screen.dart'; // 채팅방으로 이동하기 위해 import

class MatchWaitingScreen extends StatefulWidget {
  final MatchParty party; // 현재 파티 정보
  final Game game;        // 경기 정보

  const MatchWaitingScreen({
    super.key,
    required this.party,
    required this.game,
  });

  @override
  State<MatchWaitingScreen> createState() => _MatchWaitingScreenState();
}

class _MatchWaitingScreenState extends State<MatchWaitingScreen> {
  // (데모용) 내 이름
  final String myName = "나";

  void _joinChatRoom() {
    // 채팅방으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          chatRoomId: widget.party.matchId, // 파티 ID를 채팅방 ID로 사용
          chatRoomTitle: "${widget.game.homeTeam} vs ${widget.game.awayTeam} 팟",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 현재 인원 / 최대 인원
    int currentMemberCount = widget.party.participants.length;
    int maxMemberCount = widget.party.maxPlayers;
    bool isFull = currentMemberCount >= maxMemberCount;

    return Scaffold(
      backgroundColor: Colors.grey[900], // 다크 테마
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
                        "${widget.game.stadium} | ${widget.party.seatPref}",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 2. 상태 메시지
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

            // 3. 참여자 리스트 (아바타)
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: List.generate(maxMemberCount, (index) {
                if (index < currentMemberCount) {
                  // 참여자가 있는 슬롯
                  return Column(
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.person, color: Colors.white, size: 35),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.party.participants[index],
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
                onPressed: _joinChatRoom,
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
  }
}
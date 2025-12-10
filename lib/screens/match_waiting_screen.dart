// lib/screens/match_waiting_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/match_model.dart';
import 'chat_room_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchWaitingScreen extends StatefulWidget {
  final String partyId; // 파티 ID
  final Game game;        // 경기 정보

  const MatchWaitingScreen({
    super.key,
    required this.partyId,
    required this.game,
  });

  @override
  State<MatchWaitingScreen> createState() => _MatchWaitingScreenState();
}

class _MatchWaitingScreenState extends State<MatchWaitingScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  void _joinChatRoom(MatchParty party) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      }
      return;
    }
    final String chatRoomId = party.matchId;
    final String chatRoomTitle = "${widget.game.homeTeam} vs ${widget.game.awayTeam} 팟";

    // Firestore 참조
    final chatRoomsRef = _firestore.collection('chat_rooms');

    try {
      DocumentSnapshot chatDoc = await chatRoomsRef.doc(chatRoomId).get();

      // 1. 채팅방이 없는 경우 새로 생성합니다.
      if (!chatDoc.exists) {
        // 파티 참여자 UID/이름 목록을 채팅방 정보로 변환
        final Map<String, String> userNames = {};
        for (int i = 0; i < party.participantUids.length; i++) {
          userNames[party.participantUids[i]] = party.participants[i];
        }

        await chatRoomsRef.doc(chatRoomId).set({
          'chatRoomId': chatRoomId,
          'users': party.participantUids, // 파티의 모든 참여자 UID
          'userNames': userNames, // UID와 이름 매핑
          'lastMessage': '파티 채팅방이 개설되었습니다.',
          'lastMessageTime': Timestamp.now(),
          'relatedGameId': party.gameId, // 파티방임을 표시
        });
      }
      // 2. 채팅방 화면으로 이동합니다.
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              chatRoomId: chatRoomId,
              chatRoomTitle: chatRoomTitle,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('채팅방 입장 실패: $e')));
      }
    }
  }

  // ★ 파티 나가기 로직 추가
  void _leaveParty(MatchParty party, String currentUserId, String currentUserName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('파티 나가기'),
        content: const Text('파티를 나가시겠습니까? 다시 참여하려면 파티 목록에서 찾아야 합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('나가기', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final partyRef = _firestore.collection('match_parties').doc(party.matchId);

        // Firestore Update: 이름과 UID 배열에서 사용자 정보 제거
        await partyRef.update({
          'participants': FieldValue.arrayRemove([currentUserName]), // 이름 제거
          'participantUids': FieldValue.arrayRemove([currentUserId]), // UID 제거
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('파티에서 나갔습니다.')));
          // 홈 화면으로 돌아가기 (대기방 화면 닫기)
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('파티 나가기 실패: $e')));
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // 현재 로그인된 사용자 정보
    final currentUserId = _auth.currentUser?.uid;
    final currentUserName = _auth.currentUser?.displayName ?? '익명';

    // Firestore StreamBuilder로 파티 문서 구독
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

        // 3. 현재 사용자가 파티 참여자인지 확인
        final isParticipant = party.participantUids.contains(currentUserId);


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
                    onPressed: () => _joinChatRoom(party),
                  ),
                ),
                const SizedBox(height: 10),

                // ★ 5. 파티 나가기/목록으로 돌아가기 버튼
                TextButton(
                  onPressed: () {
                    // 참여자인 경우에만 _leaveParty 호출
                    if (isParticipant && currentUserId != null) {
                      _leaveParty(party, currentUserId, currentUserName);
                    } else {
                      // 참여자가 아니거나, 나가는 로직 실패 시 그냥 pop
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    isParticipant ? "파티 나가기" : "목록으로 돌아가기",
                    style: TextStyle(color: isParticipant ? Colors.redAccent : Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
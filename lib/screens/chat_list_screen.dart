import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_screen.dart';
import '../models/match_model.dart';
// ★ 데이터 파일 import (sampleGames 대신 사용)
import '../data/season_2026.dart';

class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  // 파티 채팅방 나가기 로직
  void _leaveChatRoom(BuildContext context, String chatRoomId, String currentUserId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('채팅방 나가기'),
        content: const Text('채팅방을 나가면 목록에서 사라집니다. 정말 나가시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('나가기', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.update(chatRoomRef, {
            'users': FieldValue.arrayRemove([currentUserId]),
          });
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('채팅방에서 나갔습니다.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('나가기 실패: $e')));
        }
      }
    }
  }

  // 오픈 채팅방 입장 로직
  void _enterOpenChatRoom(BuildContext context, Game game, String currentUserId, String currentUserName) async {
    final String chatRoomId = 'open_${game.gameId}';
    final String chatRoomTitle = '${game.homeTeam} vs ${game.awayTeam} 오픈톡';

    final chatRoomsRef = FirebaseFirestore.instance.collection('chat_rooms');

    try {
      DocumentSnapshot chatDoc = await chatRoomsRef.doc(chatRoomId).get();

      if (!chatDoc.exists) {
        // 방 생성
        await chatRoomsRef.doc(chatRoomId).set({
          'chatRoomId': chatRoomId,
          'type': 'open',
          'users': [currentUserId],
          'userNames': {currentUserId: currentUserName},
          'lastMessage': '오픈 채팅방이 개설되었습니다.',
          'lastMessageTime': Timestamp.now(),
          'relatedGameId': game.gameId,
        });
      } else {
        // 입장 (users 배열에 추가)
        final data = chatDoc.data() as Map<String, dynamic>?;
        final List<dynamic> currentUsers = data?['users'] ?? [];

        if (!currentUsers.contains(currentUserId)) {
          await chatRoomsRef.doc(chatRoomId).update({
            'users': FieldValue.arrayUnion([currentUserId]),
            'userNames.$currentUserId': currentUserName,
          });
        }
      }

      if (context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('입장 실패: $e')));
      }
    }
  }

  Widget _buildOpenChatCard(BuildContext context, Game game, String currentUserId, String currentUserName) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.grey[850], // 다크 테마에 맞춰 색상 조정
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _enterOpenChatRoom(context, game, currentUserId, currentUserName),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[900],
                    child: const Icon(Icons.forum, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${game.homeTeam} vs ${game.awayTeam}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${game.stadium} 오픈 응원방',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? '';
    final currentUserName = currentUser?.displayName ?? '익명';

    // ★ 수정된 부분: season2026 데이터에서 앞 5개 경기만 가져와서 오픈채팅방 목록으로 사용
    // (import '../data/season_2026.dart'; 필요)
    final List<Game> openChatGames = season2026.take(5).toList();

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(title: const Text('내 채팅'), backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: const Center(child: Text('로그인이 필요합니다.', style: TextStyle(color: Colors.white))),
      );
    }

    final chatRoomsStream = FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('users', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('채팅'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. 오픈 채팅방 목록
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text(
                '🔥 실시간 응원방',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            // ★ sampleGames -> openChatGames로 변경
            ...openChatGames.map((game) =>
                _buildOpenChatCard(context, game, currentUserId, currentUserName)
            ).toList(),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Divider(color: Colors.grey),
            ),

            // B. 내 채팅방 목록
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                '💬 나의 채팅',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: chatRoomsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }

                // 오픈 채팅방 제외하고 필터링
                final allChatDocs = snapshot.data?.docs ?? [];
                final myChats = allChatDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['type'] != 'open'; // type이 open이 아닌 것만 (DM/파티)
                }).toList();

                if (myChats.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('참여 중인 채팅방이 없습니다.', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: myChats.length,
                  itemBuilder: (context, index) {
                    final data = myChats[index].data() as Map<String, dynamic>;
                    final String chatRoomId = data['chatRoomId'] ?? myChats[index].id;
                    final String lastMessage = data['lastMessage'] ?? '';
                    final Timestamp? lastTime = data['lastMessageTime'] as Timestamp?;

                    String title = '채팅방';
                    // 파티 채팅방인 경우
                    if (data.containsKey('relatedGameId')) {
                      title = '⚾ 직관 파티';
                    }

                    // 시간 포맷
                    String timeStr = '';
                    if (lastTime != null) {
                      final dt = lastTime.toDate();
                      timeStr = "${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}";
                    }

                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.group, color: Colors.white)),
                      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(lastMessage, style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 4),
                          // 나가기 아이콘 (작게)
                          GestureDetector(
                            onTap: () => _leaveChatRoom(context, chatRoomId, currentUserId),
                            child: const Icon(Icons.exit_to_app, size: 16, color: Colors.redAccent),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomScreen(
                              chatRoomId: chatRoomId,
                              chatRoomTitle: title,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
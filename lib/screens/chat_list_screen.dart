// lib/screens/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_screen.dart';
// MatchGameScheduleScreen에서 정의된 sampleGames와 Game 모델을 사용하기 위해 import
import 'home_screen.dart';
import '../models/match_model.dart'; // Game 모델 import


class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  // [기존 코드 유지] 파티 채팅방 나가기 로직
  void _leaveChatRoom(BuildContext context, String chatRoomId, String currentUserId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('채팅방 나가기'),
        content: const Text('채팅방을 나가면 목록에서 사라집니다. 상대방은 대화를 계속 볼 수 있습니다. 정말 나가시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('나가기', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId);

        // Firestore Update를 배치(Batch)로 처리하여 users 배열과 userNames 맵에서 동시에 제거
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // 1) users 배열에서 현재 사용자 UID 제거
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


  // ★ 새로 추가된 오픈 채팅방 입장 로직
  void _enterOpenChatRoom(BuildContext context, Game game, String currentUserId, String currentUserName) async {
    // 경기 ID를 기반으로 고유한 오픈 채팅방 ID를 생성합니다.
    final String chatRoomId = 'open_${game.gameId}';
    final String chatRoomTitle = '${game.homeTeam} vs ${game.awayTeam} 오픈 채팅방';

    final chatRoomsRef = FirebaseFirestore.instance.collection('chat_rooms');

    try {
      // 1. 문서가 존재하는지 확인
      DocumentSnapshot chatDoc = await chatRoomsRef.doc(chatRoomId).get();

      // 2. 채팅방에 참여자 정보 업데이트 (없으면 생성됨)
      if (!chatDoc.exists) {
        // 방이 없으면 기본 정보를 생성
        await chatRoomsRef.doc(chatRoomId).set({
          'chatRoomId': chatRoomId,
          'type': 'open', // 오픈 채팅방임을 명시
          'users': [currentUserId],
          'userNames': {currentUserId: currentUserName},
          'lastMessage': '오픈 채팅방이 개설되었습니다.',
          'lastMessageTime': Timestamp.now(),
          'relatedGameId': game.gameId,
        });
      } else {
        // 이미 참여 중인지 확인 (Users 배열에 UID가 있는지)
        final data = chatDoc.data() as Map<String, dynamic>?;
        final List<dynamic> currentUsers = data?['users'] ?? [];

        if (!currentUsers.contains(currentUserId)) {
          // 참여 중이 아니면 users 배열과 userNames 맵에 추가합니다.
          await chatRoomsRef.doc(chatRoomId).update({
            'users': FieldValue.arrayUnion([currentUserId]),
            'userNames.$currentUserId': currentUserName, // 맵에 필드 추가
          });
        }
      }

      // 3. 채팅방 화면으로 이동
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오픈 채팅방 입장 실패: $e')));
      }
    }
  }

  // ★ UI 빌드를 위한 내부 함수: 개별 오픈 채팅방 카드
  Widget _buildOpenChatCard(BuildContext context, Game game, String currentUserId, String currentUserName) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[900],
      elevation: 4,
      child: InkWell(
        onTap: () => _enterOpenChatRoom(context, game, currentUserId, currentUserName),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${game.homeTeam} vs ${game.awayTeam}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '오픈 채팅방 - ${game.stadium}',
                    style: TextStyle(color: Colors.blue[100], fontSize: 13),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // 현재 로그인된 사용자 정보를 가져옵니다.
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? '';
    final currentUserName = currentUser?.displayName ?? '익명';

    // 1. 로그인되지 않았다면 안내 메시지 표시
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('내 채팅')),
        body: const Center(
          child: Text('채팅방 목록을 보려면 로그인이 필요합니다.'),
        ),
      );
    }

    // 2. 사용자 ID를 기반으로 채팅방 목록을 실시간으로 가져오는 Stream 설정
    final chatRoomsStream = FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('users', arrayContains: currentUserId) // 내 UID가 포함된 채팅방만 필터링
        .orderBy('lastMessageTime', descending: true) // 최신 메시지 순으로 정렬
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('내 채팅')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ★ A. 오픈 채팅방 목록 섹션
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                '경기 오픈 채팅방 (자유 입장/퇴장)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
              ),
            ),
            ...sampleGames.map((game) =>
                _buildOpenChatCard(context, game, currentUserId, currentUserName)
            ).toList(),

            const Divider(height: 30, thickness: 1),

            // ★ B. 파티/1:1 채팅방 목록 섹션
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '나의 매칭/1:1 채팅방',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: chatRoomsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.only(top: 20), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('데이터 로딩 오류: ${snapshot.error}'));
                }

                // 3. 오픈 채팅방을 제외하고 필터링
                final allChatDocs = snapshot.data!.docs;
                final partyAndDmChats = allChatDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // type이 'open'이 아닌 채팅방만 표시합니다. (type 필드가 없으면 DM이나 파티 채팅으로 간주)
                  return data['type'] != 'open';
                }).toList();


                if (partyAndDmChats.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        '참여 중인 매칭/1:1 채팅방이 없습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  );
                }

                // 4. 리스트 빌드 (파티/DM 채팅)
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: partyAndDmChats.length,
                  itemBuilder: (context, index) {
                    final chatRoomData = partyAndDmChats[index].data() as Map<String, dynamic>;
                    final String chatRoomId = chatRoomData['chatRoomId'] ?? '';
                    final String lastMessage = chatRoomData['lastMessage'] ?? '대화 시작';
                    final Timestamp? lastMessageTime = chatRoomData['lastMessageTime'] as Timestamp?;

                    String chatRoomTitle = '채팅방';
                    final List<dynamic> users = chatRoomData['users'] ?? [];
                    final Map<String, dynamic> userNames = chatRoomData['userNames'] ?? {};

                    final String? otherUserId = users.firstWhere(
                            (uid) => uid != currentUserId,
                        orElse: () => null
                    );

                    if (otherUserId != null && userNames.containsKey(otherUserId)) {
                      String otherUserName = userNames[otherUserId] ?? '익명';
                      chatRoomTitle = '${otherUserName}님과의 채팅';

                      if (chatRoomData.containsKey('relatedPostTitle') && chatRoomData['relatedPostTitle'].isNotEmpty) {
                        chatRoomTitle = '[${chatRoomData['relatedPostTitle']}] ${chatRoomTitle}';
                      }
                    } else if (chatRoomData.containsKey('relatedGameId')) {
                      // 파티 채팅방의 경우 (나만 남았을 때는 파티 정보를 기반으로 제목 생성)
                      chatRoomTitle = '매칭 파티 채팅방';
                    }


                    // 시간 포맷팅
                    String timeStr = '';
                    if (lastMessageTime != null) {
                      final diff = DateTime.now().difference(lastMessageTime.toDate());
                      if (diff.inHours < 1) {
                        timeStr = '${diff.inMinutes}분 전';
                      } else if (diff.inDays < 1) {
                        timeStr = '${diff.inHours}시간 전';
                      } else {
                        timeStr = '${lastMessageTime.toDate().month}/${lastMessageTime.toDate().day}';
                      }
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          // 파티/DM 채팅은 상대방 이름 첫 글자 또는 'P'(파티) 표시
                          chatRoomData.containsKey('relatedGameId') ? 'P' :
                          (otherUserId != null && userNames.containsKey(otherUserId) && userNames[otherUserId].isNotEmpty
                              ? userNames[otherUserId]![0] : '?'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(chatRoomTitle),
                      subtitle: Text(lastMessage),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          IconButton(
                            icon: const Icon(Icons.exit_to_app, color: Colors.grey),
                            onPressed: () => _leaveChatRoom(context, chatRoomId, currentUserId),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomScreen(
                              chatRoomId: chatRoomId,
                              chatRoomTitle: chatRoomTitle,
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
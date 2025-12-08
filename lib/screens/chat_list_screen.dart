import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 사용을 위해 추가
import 'package:firebase_auth/firebase_auth.dart';   // 사용자 인증 정보를 위해 추가
import 'chat_room_screen.dart'; // 상세 채팅방 import

class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

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

          // 2) userNames 맵에서 현재 사용자 이름 제거 (FieldPath 사용)
          // userNames의 필드를 직접 삭제하는 것이 아니라, Map에서 키를 제거하는 방식은
          // Firestore의 `update`에서 FieldPath를 사용하여 키를 null로 설정하는 것이 일반적입니다.
          // 여기서는 users 배열 제거만으로 채팅방 목록에서 사라지므로, 맵 키 삭제는 생략합니다.
          // (상대방 입장에서 내 이름이 필요할 수 있기 때문)

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

  // 이제 더미 데이터 대신 Firestore에서 실시간 데이터를 가져옵니다.

  @override
  Widget build(BuildContext context) {
    // 현재 로그인된 사용자 정보를 가져옵니다.
    final User? currentUser = FirebaseAuth.instance.currentUser;

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
        .where('users', arrayContains: currentUser.uid) // 내 UID가 포함된 채팅방만 필터링
        .orderBy('lastMessageTime', descending: true) // 최신 메시지 순으로 정렬
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('내 채팅')),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatRoomsStream,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('데이터 로딩 오류: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                '참여 중인 채팅방이 없습니다.\n게시글을 통해 새로운 채팅을 시작해 보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final chatDocs = snapshot.data!.docs;
          final currentUserId = currentUser.uid;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatRoomData = chatDocs[index].data() as Map<String, dynamic>;
              final String chatRoomId = chatRoomData['chatRoomId'] ?? '';
              final String lastMessage = chatRoomData['lastMessage'] ?? '대화 시작';
              final Timestamp? lastMessageTime = chatRoomData['lastMessageTime'] as Timestamp?;

              String chatRoomTitle = '채팅방'; // 기본값

              final List<dynamic> users = chatRoomData['users'] ?? [];
              final Map<String, dynamic> userNames = chatRoomData['userNames'] ?? {};

              // 나를 제외한 상대방의 UID를 찾습니다.
              final String? otherUserId = users.firstWhere(
                      (uid) => uid != currentUserId,
                  orElse: () => null // 나만 있는 경우 (일반적으로 발생하지 않음)
              );

              // 3. 채팅방 제목 구성 로직
              if (otherUserId != null && userNames.containsKey(otherUserId)) {
                String otherUserName = userNames[otherUserId] ?? '익명';
                chatRoomTitle = '${otherUserName}님과의 채팅';

                // 게시글을 통해 만들어진 채팅방인 경우 관련 게시글 제목을 앞에 추가
                if (chatRoomData.containsKey('relatedPostTitle') && chatRoomData['relatedPostTitle'].isNotEmpty) {
                  chatRoomTitle = '[${chatRoomData['relatedPostTitle']}] ${chatRoomTitle}';
                }
              }

              // 시간 포맷팅 (간단한 구현)
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
                    // 상대방 이름의 첫 글자 표시
                    userNames[otherUserId] != null && userNames[otherUserId].isNotEmpty
                        ? userNames[otherUserId]![0]
                        : '?',
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
    );
  }
}
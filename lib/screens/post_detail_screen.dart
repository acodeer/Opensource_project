// lib/screens/post_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_screen.dart'; // 채팅방 화면 import

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController(); // 댓글 입력 컨트롤러

  // 채팅방 생성/가져오기 및 이동 함수
  void _createOrGetChatRoom(
      BuildContext context,
      String creatorId, // 게시글 작성자의 UID
      String creatorName, // 게시글 작성자의 이름
      String postTitle) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // 1. 현재 사용자 로그인 체크
    if (currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
      }
      return;
    }

    // ★ 2. 작성자 UID 유효성 체크 및 본인 게시글 확인 (오류 방지 핵심 로직)
    if (creatorId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글 작성자 정보가 유효하지 않아 채팅을 시작할 수 없습니다. (오래된 게시글일 수 있습니다)')),
        );
      }
      return;
    }
    if (currentUser.uid == creatorId) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('자신의 게시글 작성자와는 채팅할 수 없습니다.')),
        );
      }
      return;
    }

    // 3. Chat Room ID 생성 (UIDs를 정렬하여 항상 동일한 ID를 만듦)
    final String myId = currentUser.uid;
    List<String> userIds = [myId, creatorId];
    userIds.sort();
    final String chatRoomId = userIds.join('_'); // 예: uidA_uidB

    // 4. Firestore 참조
    final chatRoomsRef = FirebaseFirestore.instance.collection('chat_rooms');

    try {
      // 5. 기존 채팅방 찾기
      DocumentSnapshot chatDoc = await chatRoomsRef.doc(chatRoomId).get();

      String chatRoomTitleForMe;
      String myName = currentUser.displayName ?? '나';

      // 6. 채팅방이 없는 경우 새로 생성
      if (!chatDoc.exists) {
        // 현재 사용자에게 표시될 제목: '[게시글 제목] 작성자와의 채팅'
        chatRoomTitleForMe = '[${postTitle}] ${creatorName}님과의 채팅';

        // Firestore에 채팅방 데이터 생성
        await chatRoomsRef.doc(chatRoomId).set({
          'chatRoomId': chatRoomId,
          'users': [myId, creatorId],
          'userNames': {
            myId: myName, // 내 이름
            creatorId: creatorName, // 상대방 이름
          },
          'lastMessage': '채팅이 시작되었습니다.',
          'lastMessageTime': Timestamp.now(),
          'relatedPostTitle': postTitle, // 채팅 목록에서 참고할 게시글 제목
        });
      } else {
        // 7. 기존 채팅방이 있는 경우, 상대방 이름을 기반으로 제목 구성
        final data = chatDoc.data() as Map<String, dynamic>?;

        // 상대방 이름 추출
        String otherUserName = creatorName;
        if (data != null && data['userNames'] != null && data['userNames'].containsKey(creatorId)) {
          otherUserName = data['userNames'][creatorId];
        }
        // 최종 제목 구성
        chatRoomTitleForMe = '[${postTitle}] ${otherUserName}님과의 채팅';
      }

      // 8. ChatRoomScreen으로 이동
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ChatRoomScreen(
              chatRoomId: chatRoomId,
              chatRoomTitle: chatRoomTitleForMe, // 구성된 제목 전달
            ),
          ),
        );
      }
    } catch (e) {
      // 오류 발생 시 디버그 로그 및 사용자 메시지 표시
      print('채팅방 생성/이동 중 오류 발생: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅방 이동에 실패했습니다: $e')),
        );
      }
    }
  }
  void _deletePost(String postId) async {
    // 사용자에게 삭제 확인 다이얼로그 표시
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다.')));
          Navigator.of(context).pop(); // 목록으로 돌아가기
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
        }
      }
    }
  }

  // 댓글 등록 로직 (기존 로직 재통합)
  void _addComment() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글을 쓰려면 로그인이 필요합니다.')));
      return;
    }

    if (_commentController.text.trim().isEmpty) return;

    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': _commentController.text,
      'writer': user.displayName ?? '익명 팬',
      'uid': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[900], // 다크 테마 배경
      appBar: AppBar(
        title: const Text('게시글 상세'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // FutureBuilder가 데이터를 로드한 후에만 버튼을 표시해야 함.
          // 여기서는 FutureBuilder 밖이므로, StreamBuilder가 데이터를 받은 후 처리해야 함.
          // FutureBuilder 내부에서 권한 확인 후 버튼을 반환하도록 로직을 변경합니다.
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('posts').doc(widget.postId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('데이터 로딩 오류: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('게시글을 찾을 수 없습니다.', style: const TextStyle(color: Colors.white)));
          }
          final postData = snapshot.data!.data() as Map<String, dynamic>;
          final String creatorId = postData['creatorId'] ?? '';
          final bool isAuthor = currentUserId == creatorId;

          // ★ 필수 데이터 추출: creatorId가 없으면 빈 문자열로 설정하여 오류 방지
          final String creatorName = postData['writer'] ?? '익명 작성자'; // board_screen에서 writer를 저장했으므로 writer 사용
          final String postTitle = postData['title'] ?? '제목 없음';
          final String postContent = postData['content'] ?? '내용 없음';
          // 카테고리 (기존 로직 사용)
          final category = postData['category'] ?? '자유';
          // 날짜 포맷팅 (기존 로직 사용)
          String dateStr = '';
          if (postData['timestamp'] != null) {
            DateTime dt = (postData['timestamp'] as Timestamp).toDate();
            dateStr = "${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
          }


          // 채팅 가능 여부 및 UI 색상 결정
          final bool canChat = creatorId.isNotEmpty && creatorId != FirebaseAuth.instance.currentUser?.uid;
          final Color chatColor = canChat ? Colors.blueAccent : Colors.grey;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (isAuthor) {
              // 작성자일 경우 AppBar에 삭제 버튼을 추가
              Scaffold.of(context).setState(() {
                // 이 방식으로 직접 AppBar를 수정할 수 없으므로, PreferredSize 위젯을 사용하거나
                // 여기서는 단순성을 위해 AppBar를 재정의하지 않고, 삭제 함수를 호출할 수 있도록
                // FutureBuilder의 로직을 body에서만 처리하고, 삭제 권한이 있을 경우
                // 로컬 앱바 대신 팝업 메뉴를 사용하도록 합니다.

                // 가장 안정적인 방법: AppBar를 State 내에서 설정하도록 변경 (PostDetailScreen을 StatefulWidget으로 만들었으므로 가능)
                // 하지만 현재 구조를 유지하기 위해, Builder를 사용하여 AppBar를 갱신합니다.
              });
            }
          });

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 카테고리 태그 (기존 로직 유지)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _getCategoryColor(category), width: 1),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(color: _getCategoryColor(category), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),

                      // 2. 제목
                      Text(
                        postTitle,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                      ),
                      const SizedBox(height: 20),

                      // 3. 작성자 프로필 영역 및 채팅 버튼 (수정된 로직)
                      InkWell(
                        onTap: canChat ? () => _createOrGetChatRoom(
                          context,
                          creatorId,
                          creatorName,
                          postTitle,
                        ) : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(creatorId.isEmpty ? '작성자 정보가 없어 채팅할 수 없습니다.' : '자신에게 채팅을 걸 수 없습니다.')),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: chatColor.withOpacity(0.2),
                                radius: 22,
                                child: Icon(Icons.person, color: chatColor, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      creatorName,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      canChat ? '1:1 채팅하기' : '채팅 불가',
                                      style: TextStyle(color: chatColor.withOpacity(0.7), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.send, color: chatColor),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        dateStr,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: Divider(color: Colors.grey, thickness: 0.5),
                ),

                // 4. 본문 내용
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    postContent,
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 50),

                // 5. 댓글 헤더
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.comment, size: 18, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text(
                        "댓글",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // 6. 댓글 리스트
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .collection('comments')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final comments = snapshot.data!.docs;

                      if (comments.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "아직 댓글이 없습니다.\n가장 먼저 댓글을 남겨보세요!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        separatorBuilder: (context, index) => const Divider(color: Colors.grey, thickness: 0.2),
                        itemBuilder: (context, index) {
                          var cData = comments[index].data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey[700],
                                  child: Text(
                                    cData['writer']?[0] ?? '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cData['writer'] ?? '익명',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[100], fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cData['text'] ?? '',
                                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      // --- 하단: 댓글 입력창 ---
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Colors.grey, width: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '댓글을 입력하세요...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: Colors.blue[900],
              radius: 22,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _addComment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 카테고리별 색상 가져오기 (기존 board_screen.dart와 통일)
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'VLOG': return Colors.redAccent;
      case '티켓양도': return Colors.greenAccent;
      case '맛집': return Colors.orangeAccent;
      default: return Colors.blueAccent;
    }
  }
}
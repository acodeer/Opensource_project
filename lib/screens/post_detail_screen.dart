// lib/screens/post_detail_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_room_screen.dart'; // 💡 채팅 연결을 위한 임포트 추가

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;

  // 💡 [추가된 함수] 작성자에게 1:1 채팅방으로 이동하는 함수
  void _navigateToChatRoom(String writerUid, String postTitle) {
    final currentUserUid = _currentUser?.uid;

    if (currentUserUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 채팅을 시작할 수 있습니다.')),
      );
      return;
    }

    if (currentUserUid == writerUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('본인에게 채팅을 걸 수 없습니다.')),
      );
      return;
    }

    // 두 사용자 ID를 정렬하여 일관된 채팅방 ID를 생성
    final List<String> uids = [currentUserUid, writerUid];
    uids.sort();
    final chatRoomId = 'chat_${uids.join('_')}'; // 예: chat_userA_userB

    Navigator.push(
      context,
      MaterialPageRoute(
        // chatRoomId와 chatRoomTitle을 ChatRoomScreen에 전달
        builder: (context) => ChatRoomScreen(
          chatRoomId: chatRoomId,
          chatRoomTitle: "1:1 채팅: $postTitle", // 게시글 제목을 활용
        ),
      ),
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글을 입력하거나 로그인해야 합니다.')),
      );
      return;
    }
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': _commentController.text,
      'writer': _currentUser!.displayName ?? _currentUser!.email,
      'uid': _currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(), // 서버 시간 기준 타임스탬프
    });
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("게시글 상세")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('posts').doc(
                    widget.postId).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final post = snapshot.data!.data() as Map<String, dynamic>;

                  // 💡 [추가된 로직] 현재 로그인 사용자가 작성자와 동일한지 확인
                  final isMyPost = post['uid'] == _currentUser?.uid;

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post['title'] ?? '제목 없음', style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("작성자: ${post['writer'] ?? '익명'}",
                            style: const TextStyle(color: Colors.grey)),

                        // 💡 [추가된 위젯] 작성자가 아니거나 로그인된 경우에만 버튼 표시
                        if (!isMyPost && _currentUser != null && post.containsKey('uid'))
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _navigateToChatRoom(
                                  post['uid'], // 게시글 문서에 저장된 작성자 UID 사용
                                  post['title'] ?? '제목 없음',
                                ),
                                icon: const Icon(Icons.send, size: 18),
                                label: const Text('작성자에게 채팅하기'),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(post['content'] ?? '내용 없음', style: const TextStyle(
                            fontSize: 16)),
                        const SizedBox(height: 32),
                        const Text("댓글", style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        _buildCommentList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('timestamp') // 오름차순 정렬 (오래된 댓글이 위로)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final comment = snapshot.data!.docs[index];
            return ListTile(
              title: Text(comment['writer'] ?? '익명'),
              subtitle: Text(comment['text'] ?? '내용 없음'),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInputField() {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery
          .of(context)
          .viewInsets
          .bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.grey[200],
        child: Row(
          children: [
            Expanded(child: TextField(controller: _commentController,
                decoration: const InputDecoration(hintText: '댓글을 입력하세요...'))),
            IconButton(icon: const Icon(Icons.send), onPressed: _addComment),
          ],
        ),
      ),
    );
  }
}
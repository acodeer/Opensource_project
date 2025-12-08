import 'package:flutter/material.dart';
// ★ 중요: 프로젝트 이름에 맞게 수정하세요
import '../widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 로그인한 사용자의 ID를 알기 위해 필요합니다.

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  final String chatRoomTitle;

  const ChatRoomScreen({
    super.key,
    required this.chatRoomId,
    required this.chatRoomTitle,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  // 현재 로그인된 사용자 정보를 가져옵니다.
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // 더미 메시지 데이터
  final List<Map<String, dynamic>> _dummyMessages = [
    {"text": "안녕하세요! 직관 같이 가요", "isMe": false, "sender": "한성룡"},
    {"text": "반갑습니다. 저도 혼자라 심심했어요", "isMe": true, "sender": "나"},
    {"text": "혹시 티켓 예매 하셨나요?", "isMe": false, "sender": "이동범"},
  ];

  void _sendMessage() async {
    final text = _controller.text.trim();
    // 1. 내용이 없거나 사용자가 로그인되지 않았다면 중단
    if (text.isEmpty || _currentUser == null) return;
    if (_controller.text.trim().isEmpty) return;


    FocusScope.of(context).unfocus(); // 메시지 전송 후 키보드 닫기


    try {
      // 3. Firestore에 메시지 저장
      await FirebaseFirestore.instance
          .collection('chat_rooms')        // 최상위 채팅방 컬렉션
          .doc(widget.chatRoomId)          // 현재 채팅방 ID (MatchWaitingScreen에서 전달받은 값)
          .collection('messages')          // 메시지 서브컬렉션
          .add({
        'text': text,
        'createdAt': Timestamp.now(),      // 서버 타임스탬프 (정확한 순서 보장)
        'userId': _currentUser!.uid,       // 작성자 식별자
        'sender': _currentUser!.displayName ?? '익명', // 작성자 이름
      });

      // 4. 입력 필드 초기화
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메시지 전송 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... (AppBar 유지)
      appBar: AppBar(
        title: Text(widget.chatRoomTitle),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Column(
        children: [
          Expanded(
            // StreamBuilder로 변경하여 Firestore에서 실시간 데이터를 가져옵니다.
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true) // 최신 메시지를 위로 정렬 (reverse: true와 함께 사용)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 에러 처리 및 데이터 체크
                if (snapshot.hasError) {
                  return Center(child: Text('데이터 로딩 오류: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                        '첫 메시지를 남겨보세요!',
                        style: TextStyle(color: Colors.grey, fontSize: 16)
                    ),
                  );
                }

                final chatDocs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // 최신 메시지가 화면 하단에 보이도록 리스트뷰를 반대로 뒤집습니다.
                  padding: const EdgeInsets.all(10),
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final message = chatDocs[index].data() as Map<String, dynamic>;
                    // 메시지의 userId가 현재 로그인된 사용자의 ID와 같은지 확인하여 'isMe'를 결정합니다.
                    final isMe = message['userId'] == _currentUser?.uid;

                    return MessageBubble(
                      text: message['text'] ?? '',
                      isMe: isMe,
                      senderName: message['sender'] ?? '익명',
                    );
                  },
                );
              },
            ),
          ),
          // 기존 더미 데이터 표시 영역 제거
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              // ★ Enter 키로 메시지 전송 기능 추가
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _sendMessage();
                }
              },
              // ★
              decoration: InputDecoration(
                hintText: '메시지 입력...',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  // 사용하지 않는 _buildInputArea 함수는 제거하거나 그대로 둡니다.
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(left: 14, right: 14, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration.collapsed(
                hintText: '메시지를 입력하세요...',
              ),
              // 💡 [Enter 키 기능 추가] onSubmitted 속성에 _sendMessage 연결
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _sendMessage(); // 입력 값이 있을 때만 전송 함수 호출
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
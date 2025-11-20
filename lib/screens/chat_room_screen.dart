import 'package:flutter/material.dart';
// ★ 중요: 프로젝트 이름에 맞게 수정하세요
import '../widgets/message_bubble.dart';

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

  // 더미 메시지 데이터
  final List<Map<String, dynamic>> _dummyMessages = [
    {"text": "안녕하세요! 직관 같이 가요", "isMe": false, "sender": "한성룡"},
    {"text": "반갑습니다. 저도 혼자라 심심했어요", "isMe": true, "sender": "나"},
    {"text": "혹시 티켓 예매 하셨나요?", "isMe": false, "sender": "이동범"},
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _dummyMessages.add({
        "text": _controller.text,
        "isMe": true,
        "sender": "나",
      });
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoomTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pop(context), // 나가기
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _dummyMessages.length,
              itemBuilder: (context, index) {
                final msg = _dummyMessages[index];
                return MessageBubble(
                  text: msg['text'],
                  isMe: msg['isMe'],
                  senderName: msg['sender'],
                );
              },
            ),
          ),
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
}
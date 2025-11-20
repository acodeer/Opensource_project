// lib/screens/chat_room_screen.dart
import 'package:flutter/material.dart';
import '../widgets/message_bubble.dart'; // 프로젝트 이름에 맞게 경로 수정

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId; // 이전 화면에서 넘겨받을 채팅방 고유 ID
  final String chatRoomTitle; // 이전 화면에서 넘겨받을 채팅방 제목

  const ChatRoomScreen({
    Key? key,
    required this.chatRoomId,
    required this.chatRoomTitle,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();

  // 나중에 서버에서 받아올 실제 메시지 데이터가 들어갈 자리입니다.
  // 지금은 UI 테스트를 위한 더미 데이터입니다.
  final List<Map<String, dynamic>> _dummyMessages = [
    {
      "senderId": "user123", // 내 ID라고 가정
      "senderName": "이동재",
      "text": "안녕하세요! 직관 같이 가실 분들 환영합니다!",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 5)),
      "isMe": true,
      "profileImage": null, // 나일 경우 이미지 없음
    },
    {
      "senderId": "user456",
      "senderName": "한성룡",
      "text": "안녕하세요! 저도 같이 가고 싶어요!",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 4)),
      "isMe": false,
      "profileImage": "https://via.placeholder.com/150/FFD700/000000?text=한성룡",
    },
    {
      "senderId": "user789",
      "senderName": "이동범",
      "text": "저는 아직 표가 없는데, 괜찮을까요?",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 3)),
      "isMe": false,
      "profileImage": "https://via.placeholder.com/150/ADFF2F/000000?text=이동범",
    },
    {
      "senderId": "user123",
      "senderName": "이동재",
      "text": "네! 오시면 같이 예매해봐요!",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 2)),
      "isMe": true,
      "profileImage": null,
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      return;
    }
    // 실제 백엔드 로직에서는 여기에 메시지를 서버로 보내는 코드가 들어갑니다.
    // 현재는 더미 데이터 리스트에만 추가합니다.
    setState(() {
      _dummyMessages.add({
        "senderId": "user123", // 로그인된 사용자 ID를 실제 사용
        "senderName": "이동재", // 로그인된 사용자 이름을 실제 사용
        "text": _messageController.text,
        "timestamp": DateTime.now(),
        "isMe": true,
        "profileImage": null,
      });
      _messageController.clear();
    });
    // 스크롤을 가장 아래로 내리는 로직도 추가해야 합니다.
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoomTitle), // 넘겨받은 채팅방 제목 사용
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app), // 채팅방 나가기 등 추가 기능
            onPressed: () {
              // TODO: 채팅방 나가기 기능 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('채팅방 나가기 기능 (미구현)')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false, // 메시지를 오래된 것부터 최신 순으로 (위에서 아래로)
              padding: const EdgeInsets.all(8.0),
              itemCount: _dummyMessages.length,
              itemBuilder: (context, index) {
                final message = _dummyMessages[index];
                return MessageBubble(
                  senderName: message['senderName']!,
                  text: message['text']!,
                  isMe: message['isMe']!,
                  profileImageUrl: message['profileImage'],
                  // timestamp: message['timestamp'], // 시간 표시도 추가할 수 있습니다.
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
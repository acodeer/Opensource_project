import 'package:flutter/material.dart';
import 'chat_room_screen.dart'; // 상세 채팅방 import

class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  // 더미 데이터
  final List<Map<String, String>> dummyChatRooms = [
    {
      "id": "room1",
      "title": "LG vs 두산 (잠실) - 응원석",
      "lastMessage": "도착하셨나요?",
      "time": "방금 전",
    },
    {
      "id": "room2",
      "title": "롯데 vs SSG (사직) - 3루",
      "lastMessage": "티켓 예매 완료했습니다.",
      "time": "1시간 전",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 채팅')),
      body: ListView.builder(
        itemCount: dummyChatRooms.length,
        itemBuilder: (context, index) {
          final room = dummyChatRooms[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.group)),
            title: Text(room['title']!),
            subtitle: Text(room['lastMessage']!),
            trailing: Text(room['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomScreen(
                    chatRoomId: room['id']!,
                    chatRoomTitle: room['title']!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
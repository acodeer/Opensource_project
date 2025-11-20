// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:opensw/screens/chat_room_screen.dart'; // 프로젝트 이름에 맞게 경로 수정

class ChatListScreen extends StatelessWidget {
  // 나중에 서버에서 받아올 실제 데이터가 들어갈 자리입니다.
  // 지금은 UI 테스트를 위한 더미 데이터입니다.
  final List<Map<String, String>> dummyChatRooms = [
    {
      "id": "party_lg_doosan_jamsil", // 채팅방 고유 ID (게시글 ID와 동일)
      "title": "6/12 잠실 LG vs 두산 직관팟",
      "lastMessage": "네, 그럼 5시에 뵈어요!",
      "time": "오후 2:30",
      "unreadCount": "3", // 안 읽은 메시지 수
      "image": "https://via.placeholder.com/150/FF6347/FFFFFF?text=LG" // 가짜 프로필 이미지
    },
    {
      "id": "party_ssg_lotte_munhak",
      "title": "부산 사직구장 롯데 직관 가실 분",
      "lastMessage": "티켓 예매는 같이 할까요?",
      "time": "오전 10:00",
      "unreadCount": "0",
      "image": "https://via.placeholder.com/150/4682B4/FFFFFF?text=LT"
    },
    {
      "id": "party_kiwoom_hanwha_gocheok",
      "title": "고척돔 키움 vs 한화",
      "lastMessage": "내일 날씨 좋으면 좋겠네요!",
      "time": "어제",
      "unreadCount": "1",
      "image": "https://via.placeholder.com/150/32CD32/FFFFFF?text=KW"
    },
  ];

  ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: dummyChatRooms.length,
        itemBuilder: (context, index) {
          final chatRoom = dummyChatRooms[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            elevation: 1.0,
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(chatRoom['image']!),
              ),
              title: Text(chatRoom['title']!),
              subtitle: Text(chatRoom['lastMessage']!),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    chatRoom['time']!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (chatRoom['unreadCount'] != '0')
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        chatRoom['unreadCount']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomScreen(
                      chatRoomId: chatRoom['id']!, // 채팅방 ID 넘겨주기
                      chatRoomTitle: chatRoom['title']!, // 채팅방 제목 넘겨주기
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
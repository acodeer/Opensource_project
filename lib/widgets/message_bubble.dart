// lib/widgets/message_bubble.dart
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String senderName;
  final String text;
  final bool isMe; // 내가 보낸 메시지인지 여부
  final String? profileImageUrl; // 상대방 프로필 이미지 URL (나일 경우 null)

  const MessageBubble({
    Key? key,
    required this.senderName,
    required this.text,
    required this.isMe,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        // 내가 보낸 메시지면 오른쪽 정렬, 아니면 왼쪽 정렬
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상대방 메시지일 경우에만 프로필 이미지와 닉네임 표시
          if (!isMe && profileImageUrl != null) ...[
            CircleAvatar(
              backgroundImage: NetworkImage(profileImageUrl!),
              radius: 18,
            ),
            const SizedBox(width: 8),
          ],
          // 메시지 버블 내용
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe) // 상대방 메시지일 경우에만 닉네임 표시
                  Text(
                    senderName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: isMe ? Theme.of(context).primaryColor : Colors.grey[300], // 내 메시지 색상
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(15),
                      topRight: const Radius.circular(15),
                      bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(0),
                      bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 내가 보낸 메시지일 경우 Spacer로 공간 확보
          if (isMe && profileImageUrl == null) const SizedBox(width: 46), // 프로필 이미지 크기만큼 공간
        ],
      ),
    );
  }
}
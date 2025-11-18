// lib/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'board_screen.dart';
import 'post_detail_screen.dart'; // 상세 화면 임포트

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToSpare;

  const HomeScreen({super.key, required this.onNavigateToSpare});

  void _navigateToBoard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BoardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 상단 버튼 영역
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              const Text('홈화면',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onNavigateToSpare,
                child: const Text('예비화면으로 이동'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _navigateToBoard(context),
                child: const Text('게시판으로 이동'),
              ),
            ],
          ),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            '최신 게시글',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // 게시글 목록 영역
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('timestamp', descending: true)
                .limit(5) // 홈 화면에는 최근 5개만 표시
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('게시글이 없습니다.'));
              }

              final posts = snapshot.data!.docs;

              // ******** 수정된 부분 시작 ********
              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  var post = posts[index];
                  // post.data()는 null일 수 있으므로 안전하게 처리합니다.
                  var postData = post.data() as Map<String, dynamic>?;

                  // 데이터가 null인 경우를 대비하여 빈 위젯을 반환합니다.
                  if (postData == null) {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                    title: Text(postData['title'] ?? '제목 없음'),
                    // 로그인 기능이 적용되었으므로 작성자 표시 가능
                    subtitle: Text("작성자: ${postData['writer'] ?? '익명'}"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // PostDetailScreen으로 게시물의 고유 ID를 전달
                          builder: (context) =>
                              PostDetailScreen(postId: post.id),
                        ),
                      );
                    },
                  );
                },
              );
              // ******** 수정된 부분 끝 ********
            },
          ),
        ),
      ],
    );
  }
}
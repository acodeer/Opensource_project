// lib/screens/board_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_detail_screen.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자유게시판'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!.docs;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var post = posts[index];
              var postData = post.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(postData['title'] ?? '제목 없음'),
                subtitle: Text("작성자: ${postData['writer'] ?? '익명'}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: post.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostDialog(context),
        child: const Icon(Icons.create),
      ),
    );
  }

  void _showPostDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('글을 쓰려면 로그인이 필요합니다.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('새 게시글 작성'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController,
                  decoration: const InputDecoration(labelText: '제목')),
              TextField(controller: contentController,
                  decoration: const InputDecoration(labelText: '내용')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('취소')),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  FirebaseFirestore.instance.collection('posts').add({
                    'title': titleController.text,
                    'content': contentController.text,
                    'timestamp': FieldValue.serverTimestamp(), // 서버 시간 기준 타임스탬프
                    'uid': user.uid,
                    'writer': user.displayName ?? user.email,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('작성'),
            ),
          ],
        );
      },
    );
  }
}
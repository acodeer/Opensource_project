import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId; // 댓글 저장을 위한 문서 ID
  final Map<String, dynamic> postData; // 목록에서 넘겨받은 데이터

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  // 댓글 등록 로직
  void _addComment() {
    final user = FirebaseAuth.instance.currentUser;

    // 1. 로그인 체크
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글을 쓰려면 로그인이 필요합니다.')));
      return;
    }

    // 2. 빈 내용 체크
    if (_commentController.text.trim().isEmpty) return;

    // 3. Firestore에 댓글 저장 (하위 컬렉션 'comments')
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

    // 4. 뒷정리
    _commentController.clear();
    FocusScope.of(context).unfocus(); // 키보드 내리기
  }

  // 카테고리별 색상 가져오기
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'VLOG': return Colors.redAccent;
      case '티켓양도': return Colors.greenAccent;
      case '맛집': return Colors.orangeAccent;
      default: return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.postData;
    final category = data['category'] ?? '자유';

    // 날짜 포맷팅
    String dateStr = '';
    if (data['timestamp'] != null) {
      DateTime dt = (data['timestamp'] as Timestamp).toDate();
      dateStr = "${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }

    return Scaffold(
      backgroundColor: Colors.grey[900], // 다크 테마 배경
      appBar: AppBar(
        title: Text("$category 게시판"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- 상단: 게시글 내용 + 댓글 리스트 (스크롤 가능 영역) ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 카테고리 태그 (뱃지 스타일)
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
                    data['title'] ?? '제목 없음',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                  ),
                  const SizedBox(height: 20),

                  // 3. 작성자 프로필 영역
                  Row(
                    children: [
                      // 프로필 아이콘
                      CircleAvatar(
                        backgroundColor: Colors.grey[800],
                        radius: 22,
                        child: const Icon(Icons.sports_baseball, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                data['writer'] ?? '익명 팬',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                              ),
                              const SizedBox(width: 6),
                              // '작성자' 표시 뱃지
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey, width: 0.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const Text("작성자", style: TextStyle(color: Colors.grey, fontSize: 10)),
                              )
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: Colors.grey, thickness: 0.5),
                  ),

                  // 4. 본문 내용
                  Text(
                    data['content'] ?? '',
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white),
                  ),
                  const SizedBox(height: 50),

                  // 5. 댓글 헤더
                  const Row(
                    children: [
                      Icon(Icons.comment, size: 18, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text(
                        "댓글",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // 6. 댓글 리스트 (StreamBuilder로 실시간 업데이트)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .collection('comments')
                        .orderBy('timestamp', descending: false) // 오래된 댓글부터 위로 쌓임
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox(); // 로딩 중
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
                        shrinkWrap: true, // 스크롤 가능한 부모 안에서 필수
                        physics: const NeverScrollableScrollPhysics(), // 부모 스크롤을 따름
                        itemCount: comments.length,
                        separatorBuilder: (context, index) => const Divider(color: Colors.grey, thickness: 0.2),
                        itemBuilder: (context, index) {
                          var cData = comments[index].data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 댓글 작성자 아이콘
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
                                      // 댓글 작성자 이름
                                      Text(
                                        cData['writer'] ?? '익명',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[100], fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      // 댓글 내용
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- 하단: 댓글 입력창 (화면 하단 고정) ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), // 하단 여백 넉넉히
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
        ],
      ),
    );
  }
}
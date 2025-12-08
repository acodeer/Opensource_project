import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_detail_screen.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = ['전체', '자유', 'VLOG', '티켓양도', '맛집'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('KBO 팬 게시판'), // 제목을 좀 더 자연스럽게
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) => _buildPostList(category)).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[900],
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text("글쓰기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showCategorySelectionDialog(context),
      ),
    );
  }

  Widget _buildPostList(String currentTabCategory) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('데이터를 불러오는데 실패했습니다.', style: TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // 1. 데이터 안전하게 가져오기 & 필터링
        var posts = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?; // null 체크
          if (data == null) return false;

          // 카테고리 필드가 없으면 '자유'로 간주 (에러 방지 핵심!)
          String postCategory = data.containsKey('category') ? data['category'] : '자유';

          // '전체' 탭이면 다 보여주고, 아니면 카테고리 맞는 것만
          if (currentTabCategory == '전체') return true;
          return postCategory == currentTabCategory;
        }).toList();

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 60, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  '$currentTabCategory 관련된 글이 없어요.\n첫 번째 주인공이 되어보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            var post = posts[index];
            var data = post.data() as Map<String, dynamic>;

            // 카테고리 없으면 '자유'로 표시
            String category = data['category'] ?? '자유';

            // 시간 포맷팅 (예: 11/20)
            String dateStr = '';
            if (data['timestamp'] != null) {
              DateTime dt = (data['timestamp'] as Timestamp).toDate();
              dateStr = "${dt.month}/${dt.day}";
            }

            return Card(
              color: Colors.grey[850],
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(
                        postId: post.id,
                        // postData: data, <--- 이 줄이 제거되었습니다.
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단: 카테고리 태그 + 제목
                      Row(
                        children: [
                          // 카테고리 뱃지
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _getCategoryColor(category), width: 0.5),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(color: _getCategoryColor(category), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['title'] ?? '제목 없음',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 하단: 닉네임 + 날짜
                      Row(
                        children: [
                          const Text("🧢 ", style: TextStyle(fontSize: 12)), // 야구팬 아이콘 느낌
                          Text(
                            data['writer'] ?? '익명 팬',
                            style: TextStyle(color: Colors.blue[100], fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "·  $dateStr",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          const Spacer(),
                          Icon(Icons.comment_outlined, size: 14, color: Colors.grey[600]),
                          // const SizedBox(width: 4),
                          // Text("0", style: TextStyle(color: Colors.grey[600], fontSize: 12)), // 댓글 수 기능은 추후 구현
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'VLOG': return Colors.redAccent;
      case '티켓양도': return Colors.greenAccent;
      case '맛집': return Colors.orangeAccent;
      default: return Colors.blueAccent;
    }
  }

  // (아이콘 가져오는 함수는 다이얼로그용으로 유지)
  Widget _getCategoryIcon(String category) {
    IconData icon;
    switch (category) {
      case 'VLOG': icon = Icons.play_circle_outline; break;
      case '티켓양도': icon = Icons.confirmation_number_outlined; break;
      case '맛집': icon = Icons.restaurant_menu; break;
      default: icon = Icons.article_outlined;
    }
    return Icon(icon, color: Colors.white);
  }

  void _showCategorySelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(20), child: Text('게시판 선택', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            ..._categories.where((c) => c != '전체').map((cat) => ListTile(
              leading: _getCategoryIcon(cat),
              title: Text(cat, style: const TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); _showWriteDialog(context, cat); },
            )).toList(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showWriteDialog(BuildContext context, String category) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text('$category 글쓰기', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: '제목',
                    labelStyle: TextStyle(color: Colors.grey),
                    hintText: '흥미로운 제목을 지어주세요',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))
                )
            ),
            const SizedBox(height: 16),
            TextField(
                controller: contentCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: '내용',
                    labelStyle: TextStyle(color: Colors.grey),
                    hintText: '매너있는 야구팬이 되어주세요 :)',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey))
                )
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                FirebaseFirestore.instance.collection('posts').add({
                  'category': category,
                  'title': titleCtrl.text,
                  'content': contentCtrl.text,
                  'writer': user.displayName ?? '익명 팬',
                  'uid': user.uid,
                  'timestamp': FieldValue.serverTimestamp(),
                  'creatorId': user.uid, // ★ 게시글 작성자의 UID를 저장하여 1:1 채팅에 사용
                  'creatorName': user.displayName ?? '익명 팬', // ★ 게시글 작성자의 이름을 저장
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('등록', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
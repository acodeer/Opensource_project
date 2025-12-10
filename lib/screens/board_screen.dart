import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart'; // 유튜브 링크 열기용 (필요시)

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

    // ★ 탭 변경 감지 리스너 추가
    _tabController.addListener(() {
      // 탭 이동 애니메이션이 끝나고, 현재 탭이 '티켓양도'(인덱스 3)일 때만 실행
      if (!_tabController.indexIsChanging && _tabController.index == 3) {
        _showTicketWarningDialog();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ★ 티켓 양도 면책 팝업 함수
  void _showTicketWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 확인 버튼을 눌러야만 닫히도록 설정
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
            SizedBox(width: 10),
            Text('티켓 거래 주의사항', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. 암표 거래 금지 (No Scalping)',
                style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 4),
              Text(
                'KBO 및 관계 법령에 따라 정가를 초과하여 판매하는 모든 영리 목적의 티켓 거래(암표)를 엄격히 금지합니다. 적발 시 게시글은 통보 없이 삭제될 수 있습니다.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 16),
              Text(
                '2. 법적 책임의 고지 (Disclaimer)',
                style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 4),
              Text(
                '\'(직관)갈래말래\'는 정보 공유 커뮤니티일 뿐 티켓 거래의 중개자나 당사자가 아닙니다. 거래 과정에서 발생하는 사기, 분쟁, 손실에 대해 운영진은 어떠한 법적 책임도 지지 않습니다.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 16),
              Text(
                '※ 안전한 거래를 위해 상대방의 예매 내역과 연락처를 꼼꼼히 확인하시기 바랍니다.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인했습니다', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('KBO 팬 게시판'),
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
        label: const Text(
          "글쓰기",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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

        final posts = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;
          final String postCategory = data.containsKey('category') ? data['category'] : '자유';
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
            final post = posts[index];
            final data = post.data() as Map<String, dynamic>;
            final String category = data['category'] ?? '자유';

            String dateStr = '';
            if (data['timestamp'] != null) {
              final dt = (data['timestamp'] as Timestamp).toDate();
              dateStr = "${dt.month}/${dt.day}";
            }

            return Card(
              color: Colors.grey[850],
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // 상세 화면으로 이동 (데이터 전달)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(
                        postId: post.id,
                        postData: data, // ★ 데이터 전달
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
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
                      Row(
                        children: [
                          const Text("🧢 ", style: TextStyle(fontSize: 12)),
                          Text(
                            data['writer'] ?? '익명 팬',
                            style: TextStyle(color: Colors.blue[100], fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          Text("·  $dateStr", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          const Spacer(),
                          Icon(Icons.comment_outlined, size: 14, color: Colors.grey[600]),
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
    final youtubeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text('$category 글쓰기', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: '제목', labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: const InputDecoration(labelText: '내용', labelStyle: TextStyle(color: Colors.grey), border: OutlineInputBorder(), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: youtubeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'YouTube 링크 (선택)', labelStyle: TextStyle(color: Colors.grey), hintText: 'https://youtu.be/...', hintStyle: TextStyle(color: Colors.grey, fontSize: 12), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
            onPressed: () async {
              if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;
              final youtubeUrl = youtubeCtrl.text.trim();
              final data = <String, dynamic>{
                'category': category,
                'title': titleCtrl.text,
                'content': contentCtrl.text,
                'writer': user.displayName ?? '익명 팬',
                'uid': user.uid,
                'timestamp': FieldValue.serverTimestamp(),
                'creatorId': user.uid,
                'creatorName': user.displayName ?? '익명 팬',
              };
              if (youtubeUrl.isNotEmpty) data['youtubeUrl'] = youtubeUrl;
              await FirebaseFirestore.instance.collection('posts').add(data);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('등록', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
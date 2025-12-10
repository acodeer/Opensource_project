import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData; // ★ BoardScreen에서 넘겨주는 데이터

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.postData, // ★ 필수 인자로 추가
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _auth = FirebaseAuth.instance;

  // 게시글 수정을 위한 문서 스냅샷 (나중에 로드됨)
  DocumentSnapshot<Map<String, dynamic>>? _postDoc;

  YoutubePlayerController? _ytController;
  String? _rawYoutubeUrl;

  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 1. 초기 데이터로 유튜브 설정 (화면 딜레이 없음)
    _initDataFromArgs();
    // 2. 최신 데이터 백그라운드 로드 (권한 확인용)
    _loadPostRef();
  }

  @override
  void dispose() {
    _ytController?.close();
    _commentCtrl.dispose();
    super.dispose();
  }

  // 전달받은 postData로 초기화
  void _initDataFromArgs() {
    final data = widget.postData;
    String? youtubeUrl = data['youtubeUrl'];

    // 내용에서 유튜브 링크 추출 시도
    if (youtubeUrl == null || youtubeUrl.trim().isEmpty) {
      final content = (data['content'] ?? '') as String;
      final match = RegExp(r'(https?:\/\/[^\s]+)').firstMatch(content.trim());
      if (match != null) {
        youtubeUrl = match.group(0);
      }
    }

    _rawYoutubeUrl = youtubeUrl;
    if (youtubeUrl != null && youtubeUrl.trim().isNotEmpty) {
      _initYoutube(youtubeUrl);
    }
  }

  // Firestore에서 최신 문서 가져오기 (수정/삭제 권한 확인용)
  Future<void> _loadPostRef() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (doc.exists) {
        if (mounted) {
          setState(() {
            _postDoc = doc;
          });
        }
      }
    } catch (e) {
      print("게시글 로드 오류: $e");
    }
  }

  void _initYoutube(String url) {
    final videoId = _extractVideoId(url);
    if (videoId == null) return;

    _ytController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        enableCaption: false,
      ),
    );
  }

  String? _extractVideoId(String url) {
    final trimmed = url.trim();
    if (!trimmed.startsWith('http')) {
      if (trimmed.length == 11 && RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
        return trimmed;
      }
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    if (uri.host.contains('youtu.be')) {
      if (uri.pathSegments.isNotEmpty) return uri.pathSegments.first;
    }
    if (uri.host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;
      final segments = uri.pathSegments;
      if (segments.isNotEmpty && segments.first == 'shorts' && segments.length >= 2) {
        return segments[1];
      }
    }
    return null;
  }

  bool get _isMyPost {
    final user = _auth.currentUser;
    // _postDoc이 로드되기 전에는 postData의 uid로 확인
    final writerUid = _postDoc?.data()?['uid'] ?? widget.postData['uid'];
    return user != null && writerUid == user.uid;
  }

  Future<void> _showEditPostDialog() async {
    // 최신 데이터가 없으면 postData 사용
    final data = _postDoc?.data() ?? widget.postData;

    final titleCtrl = TextEditingController(text: data['title'] ?? '');
    final contentCtrl = TextEditingController(text: data['content'] ?? '');
    final youtubeCtrl = TextEditingController(text: (data['youtubeUrl'] ?? '').toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('게시글 수정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: '제목', labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: const InputDecoration(labelText: '내용', labelStyle: TextStyle(color: Colors.grey), border: OutlineInputBorder(), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: youtubeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: '유튜브 링크(선택)', labelStyle: TextStyle(color: Colors.grey), hintText: 'https://youtu.be/...', hintStyle: TextStyle(color: Colors.grey, fontSize: 11), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;

              // 업데이트할 참조가 필요하므로 _postDoc이 로드될 때까지 대기 혹은 직접 참조 생성
              final docRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

              await docRef.update({
                'title': titleCtrl.text.trim(),
                'content': contentCtrl.text.trim(),
                'youtubeUrl': youtubeCtrl.text.trim().isEmpty ? null : youtubeCtrl.text.trim(),
              });

              // 화면 갱신을 위해 다시 로드
              await _loadPostRef();
              // 현재 화면 데이터 갱신
              _initDataFromArgs();

              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('저장', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePost() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('게시글 삭제', style: TextStyle(color: Colors.white)),
        content: const Text('정말로 이 게시글을 삭제할까요?\n댓글도 함께 삭제됩니다.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok != true) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final commentsSnap = await postRef.collection('comments').get();
    final batch = FirebaseFirestore.instance.batch();

    for (final c in commentsSnap.docs) {
      batch.delete(c.reference);
    }
    batch.delete(postRef);
    await batch.commit();

    if (mounted) Navigator.pop(context);
  }

  Future<void> _sendComment() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'content': text,
      'writerUid': user.uid,
      'writerName': user.displayName ?? '익명 팬',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  // 댓글 수정/삭제 로직 (기존과 동일)
  Future<void> _editComment(DocumentSnapshot<Map<String, dynamic>> commentDoc) async {
    final data = commentDoc.data()!;
    final contentCtrl = TextEditingController(text: data['content'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('댓글 수정', style: TextStyle(color: Colors.white)),
        content: TextField(controller: contentCtrl, style: const TextStyle(color: Colors.white), maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () async {
            if (contentCtrl.text.trim().isEmpty) return;
            await commentDoc.reference.update({'content': contentCtrl.text.trim()});
            if (mounted) Navigator.pop(ctx);
          }, child: const Text('저장', style: TextStyle(color: Colors.blue))),
        ],
      ),
    );
  }

  Future<void> _deleteComment(DocumentSnapshot<Map<String, dynamic>> commentDoc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('댓글 삭제', style: TextStyle(color: Colors.white)),
        content: const Text('이 댓글을 삭제할까요?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await commentDoc.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    // 데이터는 widget.postData를 우선 사용하되, _postDoc이 로드되면 그 데이터를 사용 (수정 사항 반영 위해)
    final displayData = _postDoc?.data() ?? widget.postData;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(displayData['title'] ?? '게시글 상세', overflow: TextOverflow.ellipsis),
        actions: [
          if (_isMyPost)
            PopupMenuButton<String>(
              color: Colors.grey[850],
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) => value == 'edit' ? _showEditPostDialog() : _confirmDeletePost(),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('수정', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostHeader(displayData),
                  const SizedBox(height: 16),
                  if (_ytController != null) _buildYoutubePlayer(),
                  if (_rawYoutubeUrl != null && _ytController == null) _buildYoutubeFallbackLink(),
                  const SizedBox(height: 16),
                  Text(displayData['content'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
                  const SizedBox(height: 30),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text('댓글', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  _buildCommentsList(user),
                  const SizedBox(height: 20), // 댓글 리스트 하단 여백
                ],
              ),
            ),
          ),
          _buildCommentInputArea(),
        ],
      ),
    );
  }

  Widget _buildPostHeader(Map<String, dynamic> data) {
    final writer = data['writer'] ?? '익명 팬';
    final ts = data['timestamp'] as Timestamp?;
    String dateStr = '';
    if (ts != null) {
      final dt = ts.toDate();
      dateStr = '${dt.year}.${dt.month}.${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}';
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[800],
          child: const Icon(Icons.sports_baseball, size: 22, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(writer, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text(dateStr, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildYoutubePlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: YoutubePlayer(
        controller: _ytController!,
        aspectRatio: 16 / 9,
      ),
    );
  }

  Widget _buildYoutubeFallbackLink() {
    return GestureDetector(
      onTap: () { /* 링크 열기 로직 */ },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent)),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(child: Text(_rawYoutubeUrl ?? '', style: const TextStyle(color: Colors.white, decoration: TextDecoration.underline), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList(User? user) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').orderBy('timestamp', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final comments = snapshot.data!.docs;
        if (comments.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('첫 댓글을 남겨보세요!', style: TextStyle(color: Colors.grey))));

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, index) {
            final c = comments[index];
            final data = c.data();
            final isMyComment = user != null && data['writerUid'] == user.uid;

            // 시간 표시
            String timeStr = '';
            if (data['timestamp'] != null) {
              final dt = (data['timestamp'] as Timestamp).toDate();
              timeStr = '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}';
            }

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(data['writerName'] ?? '익명', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      Text(timeStr, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      const Spacer(),
                      if (isMyComment)
                        PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
                            onSelected: (val) => val == 'edit' ? _editComment(c) : _deleteComment(c),
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'edit', child: Text('수정')),
                              const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
                            ]
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(data['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(color: Colors.black, border: Border(top: BorderSide(color: Colors.grey, width: 0.3))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '댓글을 입력하세요',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true, fillColor: Colors.grey[900],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.blue[900], radius: 22,
            child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _sendComment),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _auth = FirebaseAuth.instance;

  DocumentSnapshot<Map<String, dynamic>>? _postDoc;
  bool _isLoading = true;

  YoutubePlayerController? _ytController;
  String? _rawYoutubeUrl;

  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _ytController?.close();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (!doc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      String? youtubeUrl = data['youtubeUrl'];

      // 🔹 예전 글에서 내용에만 링크를 적어둔 경우, 내용에서 URL을 추출
      if (youtubeUrl == null || youtubeUrl.trim().isEmpty) {
        final content = (data['content'] ?? '') as String;
        final match =
        RegExp(r'(https?:\/\/[^\s]+)').firstMatch(content.trim());
        if (match != null) {
          youtubeUrl = match.group(0);
        }
      }

      _rawYoutubeUrl = youtubeUrl;

      if (youtubeUrl != null && youtubeUrl.trim().isNotEmpty) {
        _initYoutube(youtubeUrl);
      }

      setState(() {
        _postDoc = doc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글을 불러오지 못했습니다: $e')),
        );
      }
    }
  }

  void _initYoutube(String url) {
    final videoId = _extractVideoId(url);
    if (videoId == null) {
      return;
    }

    _ytController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
  }

  /// 🔹 유튜브 링크에서 videoId만 뽑는 함수
  String? _extractVideoId(String url) {
    final trimmed = url.trim();

    // 그냥 ID만 넣은 경우 (11자리)
    if (!trimmed.startsWith('http')) {
      if (trimmed.length == 11 &&
          RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
        return trimmed;
      }
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    // youtu.be/VIDEOID
    if (uri.host.contains('youtu.be')) {
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
    }

    // youtube.com/watch?v=VIDEOID
    if (uri.host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) {
        return v;
      }

      // shorts 링크: /shorts/VIDEOID
      final segments = uri.pathSegments;
      if (segments.isNotEmpty && segments.first == 'shorts' && segments.length >= 2) {
        return segments[1];
      }
    }

    return null;
  }

  bool get _isMyPost {
    final user = _auth.currentUser;
    if (user == null || _postDoc == null) return false;
    final data = _postDoc!.data()!;
    return data['uid'] == user.uid;
  }

  Future<void> _showEditPostDialog() async {
    if (_postDoc == null) return;

    final data = _postDoc!.data()!;
    final titleCtrl = TextEditingController(text: data['title'] ?? '');
    final contentCtrl = TextEditingController(text: data['content'] ?? '');
    final youtubeCtrl =
    TextEditingController(text: (data['youtubeUrl'] ?? '').toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          '게시글 수정',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '제목',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '내용',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: youtubeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '유튜브 링크(선택)',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'https://youtu.be/xxxx 또는 https://www.youtube.com/watch?v=xxxx',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 11),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[900],
            ),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final content = contentCtrl.text.trim();
              final youtubeUrl = youtubeCtrl.text.trim();

              if (title.isEmpty || content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')),
                );
                return;
              }

              await _postDoc!.reference.update({
                'title': title,
                'content': content,
                'youtubeUrl': youtubeUrl.isEmpty ? null : youtubeUrl,
              });

              // 영상 링크 변경 반영
              _ytController?.close();
              _ytController = null;
              _rawYoutubeUrl = youtubeUrl.isEmpty ? null : youtubeUrl;
              if (_rawYoutubeUrl != null) {
                _initYoutube(_rawYoutubeUrl!);
              }

              await _loadPost();

              if (mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text('저장', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePost() async {
    if (_postDoc == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('게시글 삭제', style: TextStyle(color: Colors.white)),
        content: const Text(
          '정말로 이 게시글을 삭제할까요?\n댓글도 함께 삭제됩니다.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final postRef = _postDoc!.reference;
    final commentsSnap = await postRef.collection('comments').get();

    final batch = FirebaseFirestore.instance.batch();
    for (final c in commentsSnap.docs) {
      batch.delete(c.reference);
    }
    batch.delete(postRef);
    await batch.commit();

    if (!mounted) return;
    Navigator.pop(context); // 목록으로 복귀
  }

  Future<void> _sendComment() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
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
  }

  Future<void> _editComment(DocumentSnapshot<Map<String, dynamic>> commentDoc) async {
    final data = commentDoc.data()!;
    final contentCtrl = TextEditingController(text: data['content'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('댓글 수정', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: contentCtrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final newText = contentCtrl.text.trim();
              if (newText.isEmpty) return;

              await commentDoc.reference.update({'content': newText});
              if (mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text('저장', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(
      DocumentSnapshot<Map<String, dynamic>> commentDoc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('댓글 삭제', style: TextStyle(color: Colors.white)),
        content: const Text(
          '이 댓글을 삭제할까요?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await commentDoc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _postDoc?.data()?['title'] ?? '게시글 상세',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_isMyPost)
            PopupMenuButton<String>(
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditPostDialog();
                } else if (value == 'delete') {
                  _confirmDeletePost();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('수정', style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('삭제', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _postDoc == null
          ? const Center(
        child: Text(
          '게시글을 찾을 수 없습니다.',
          style: TextStyle(color: Colors.white70),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostHeader(),
                  const SizedBox(height: 16),
                  if (_ytController != null) _buildYoutubePlayer(),
                  if (_rawYoutubeUrl != null &&
                      (_ytController == null))
                    _buildYoutubeFallbackLink(),
                  const SizedBox(height: 8),
                  _buildPostContent(),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text(
                    '댓글',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCommentsList(user),
                ],
              ),
            ),
          ),
          _buildCommentInputArea(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    final data = _postDoc!.data()!;
    final writer = data['writer'] ?? '익명 팬';
    final ts = data['timestamp'] as Timestamp?;
    String dateStr = '';
    if (ts != null) {
      final dt = ts.toDate();
      dateStr = '${dt.year}.${dt.month}.${dt.day}';
    }

    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Colors.blueGrey,
          child: Text('팬', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              writer,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
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
      onTap: () {
        // 🔹 여기서 url_launcher로 외부 브라우저 여는 것도 가능 (원하면 추가)
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.redAccent, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _rawYoutubeUrl ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    final data = _postDoc!.data()!;
    return Text(
      data['content'] ?? '',
      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
    );
  }

  Widget _buildCommentsList(User? user) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            '댓글을 불러오는데 실패했습니다.',
            style: TextStyle(color: Colors.white70),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final comments = snapshot.data!.docs;
        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '첫 댓글을 남겨보세요!',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (ctx, index) {
            final c = comments[index];
            final data = c.data();
            final writerName = data['writerName'] ?? '익명 팬';
            final content = data['content'] ?? '';
            final ts = data['timestamp'] as Timestamp?;
            String timeStr = '';
            if (ts != null) {
              final dt = ts.toDate();
              timeStr = '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            }

            final isMyComment =
                user != null && data['writerUid'] == user.uid;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.person,
                      size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              writerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              timeStr,
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 11),
                            ),
                            const Spacer(),
                            if (isMyComment)
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                color: Colors.grey[850],
                                icon: const Icon(Icons.more_vert,
                                    size: 16, color: Colors.grey),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editComment(c);
                                  } else if (value == 'delete') {
                                    _deleteComment(c);
                                  }
                                },
                                itemBuilder: (ctx) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('수정',
                                        style:
                                        TextStyle(color: Colors.white)),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('삭제',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          content,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInputArea() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Colors.grey[800]!),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: '댓글을 입력하세요',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: _sendComment,
              icon: const Icon(Icons.send, color: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }
}

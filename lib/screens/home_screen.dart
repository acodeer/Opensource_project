import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 확인용
import 'package:url_launcher/url_launcher.dart'; // 웹에서 링크 열기용

import 'match_waiting_screen.dart';
import '../models/match_model.dart';
import 'webview_screen.dart';

// 데이터 파일 불러오기
import '../data/season_2025.dart';
import '../data/season_2026.dart';

const List<String> availableTags = ['응원단', '가벼운 술자리', '아이와 동행', '초보 환영', '포토존', '야간 응원'];

class MatchGameScheduleScreen extends StatefulWidget {
  const MatchGameScheduleScreen({super.key});

  @override
  State<MatchGameScheduleScreen> createState() => _MatchGameScheduleScreenState();
}

class _MatchGameScheduleScreenState extends State<MatchGameScheduleScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late List<Game> allGames;

  // 기본 선택 날짜: 2026년 3월 21일 (개막전)
  DateTime _selectedDate = DateTime(2026, 3, 21);
  bool _isCalendarExpanded = false;

  @override
  void initState() {
    super.initState();
    // 25시즌, 26시즌 데이터 통합
    allGames = [...season2025, ...season2026];
  }

  // 팀 로고 경로 매핑
  String _getTeamLogo(String teamName) {
    Map<String, String> teamLogos = {
      '두산': 'assets/doosan.png',
      '한화': 'assets/eagles.png',
      '롯데': 'assets/giants.png',
      '키움': 'assets/kiwoom.png',
      'KIA': 'assets/kn.png',
      'KT': 'assets/kt.png',
      'LG': 'assets/twins.png',
      'NC': 'assets/nc.png',
      '삼성': 'assets/samsung.png',
      'SSG': 'assets/ssg.png',
      '나눔': 'assets/kbo.png',
      '드림': 'assets/kbo.png',
    };
    return teamLogos[teamName] ?? 'kbo.png';
  }

  String _formatDate(DateTime dt) => '${dt.month}월 ${dt.day}일 (${_getDayOfWeek(dt)})';

  String _getDayOfWeek(DateTime dt) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[dt.weekday - 1];
  }

  String _formatTime(DateTime dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _isCalendarExpanded = false; // 날짜 선택 후 캘린더 접기
    });
  }

  // 스탯 버튼 클릭 시 처리
  void _onStatsPressed() async {
    const String statizUrl = 'https://www.statiz.co.kr/';

    if (kIsWeb) {
      if (await canLaunchUrl(Uri.parse(statizUrl))) {
        await launchUrl(Uri.parse(statizUrl));
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WebViewScreen(
            url: statizUrl,
            title: 'STATIZ 기록실',
          ),
        ),
      );
    }
  }

  Future<MatchParty?> _findActiveParty() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final snapshot = await _firestore.collection('match_parties')
          .where('participantUids', arrayContains: user.uid)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return MatchParty.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _onGameTap(Game game) async {
    if (game.isCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('취소된 경기입니다.'), duration: Duration(seconds: 1)));
      return;
    }
    if (game.isFinished) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 종료된 경기입니다.'), duration: Duration(seconds: 1)));
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }
    final activeParty = await _findActiveParty();
    if (activeParty != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 참여 중인 파티가 있습니다.'), duration: Duration(seconds: 2)));
        final activeGame = allGames.firstWhere((g) => g.gameId == activeParty.gameId, orElse: () => game);
        Navigator.push(context, MaterialPageRoute(builder: (_) => MatchWaitingScreen(partyId: activeParty.matchId, game: activeGame)));
      }
      return;
    }
    _showMatchBottomSheet(game);
  }

  void _showMatchBottomSheet(Game game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${game.homeTeam} vs ${game.awayTeam}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('${game.stadium} | ${_formatDate(game.date)}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.greenAccent, child: Icon(Icons.add, color: Colors.black)),
                title: const Text('파티 만들기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('직접 방장이 되어 멤버를 모집합니다', style: TextStyle(color: Colors.white60)),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => MatchCreateScreen(game: game))); },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.lightBlueAccent, child: Icon(Icons.search, color: Colors.black)),
                title: const Text('파티 찾기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('이미 생성된 파티에 참여합니다', style: TextStyle(color: Colors.white60)),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => MatchListScreen(game: game))); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Game> filteredGames = allGames.where((g) =>
    g.date.year == _selectedDate.year &&
        g.date.month == _selectedDate.month &&
        g.date.day == _selectedDate.day
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.bar_chart, color: Colors.greenAccent),
          onPressed: _onStatsPressed,
        ),
        title: GestureDetector(
          onTap: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_formatDate(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              Icon(_isCalendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
          ),
        ],
      ),
      body: Column(
        children: [
          // ★ [수정됨] AnimatedCrossFade로 잔상 없이 깔끔하게 접힘 ★
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0), // 접혔을 때 (높이 0)
            secondChild: Container(
              width: double.infinity,
              height: 440, // 캘린더 높이
              color: const Color(0xFF1E1E1E),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 시즌 이동 버튼
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ActionChip(
                            label: const Text("2025 시즌"),
                            backgroundColor: _selectedDate.year == 2025 ? Colors.blue[900] : Colors.grey[800],
                            labelStyle: TextStyle(color: _selectedDate.year == 2025 ? Colors.white : Colors.grey[400], fontWeight: FontWeight.bold),
                            onPressed: () {
                              setState(() {
                                _selectedDate = DateTime(2025, 3, 8);
                              });
                            },
                          ),
                          const SizedBox(width: 12),
                          ActionChip(
                            label: const Text("2026 시즌"),
                            backgroundColor: _selectedDate.year == 2026 ? Colors.blue[900] : Colors.grey[800],
                            labelStyle: TextStyle(color: _selectedDate.year == 2026 ? Colors.white : Colors.grey[400], fontWeight: FontWeight.bold),
                            onPressed: () {
                              setState(() {
                                _selectedDate = DateTime(2026, 3, 21);
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: Colors.blue[900]!, // KBO 남색
                          onPrimary: Colors.white,
                          surface: const Color(0xFF1E1E1E),
                          onSurface: Colors.white,
                        ),
                        dialogBackgroundColor: const Color(0xFF1E1E1E),
                      ),
                      child: CalendarDatePicker(
                        key: ValueKey(_selectedDate),
                        initialDate: _selectedDate,
                        firstDate: DateTime(2025, 3, 1),
                        lastDate: DateTime(2026, 12, 31),
                        onDateChanged: _onDateSelected,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            crossFadeState: _isCalendarExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.topCenter,
            sizeCurve: Curves.easeInOut,
          ),

          Expanded(
            child: filteredGames.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_baseball_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text("${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일엔\n경기가 없습니다.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
                : ListView.builder(
              itemCount: filteredGames.length,
              itemBuilder: (context, index) {
                return _buildNaverStyleGameCard(filteredGames[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNaverStyleGameCard(Game game) {
    bool isCancelled = game.isCancelled;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    isCancelled ? "취소" : (game.isFinished ? "종료" : _formatTime(game.date)),
                    style: TextStyle(color: isCancelled ? Colors.redAccent : Colors.white, fontSize: 14, fontWeight: FontWeight.w700)
                ),
                const SizedBox(height: 4),
                Text(game.stadium, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(game.awayTeam, style: TextStyle(color: !isCancelled && game.isFinished && (game.awayScore! > game.homeScore!) ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 8),
                          Image.asset(_getTeamLogo(game.awayTeam), width: 34, height: 34, errorBuilder: (c,o,s) => const Icon(Icons.circle, color: Colors.grey)),
                        ],
                      ),
                      if (!isCancelled && game.isFinished && game.awayPitcher != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text("승 ${game.awayPitcher}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  alignment: Alignment.center,
                  child: isCancelled
                      ? const Text("취소", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold))
                      : (game.isFinished
                      ? Text(
                    "${game.awayScore} : ${game.homeScore}",
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  )
                      : const Text(
                    "VS",
                    style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                  )),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(_getTeamLogo(game.homeTeam), width: 34, height: 34, errorBuilder: (c,o,s) => const Icon(Icons.circle, color: Colors.grey)),
                          const SizedBox(width: 8),
                          Text(game.homeTeam, style: TextStyle(color: !isCancelled && game.isFinished && (game.homeScore! > game.awayScore!) ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      if (!isCancelled && game.isFinished && game.homePitcher != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text("패 ${game.homePitcher}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            height: 32,
            child: (game.isFinished || isCancelled)
                ? ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                disabledBackgroundColor: Colors.grey[800],
                disabledForegroundColor: Colors.grey,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(isCancelled ? "취소됨" : "경기종료", style: const TextStyle(fontSize: 11)),
            )
                : ElevatedButton(
              onPressed: () => _onGameTap(game),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text("직관매칭", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ... (하단 MatchCreateScreen, MatchListScreen 코드는 기존과 동일하게 유지) ...
class MatchCreateScreen extends StatefulWidget {
  final Game game;
  const MatchCreateScreen({required this.game, super.key});
  @override
  State<MatchCreateScreen> createState() => _MatchCreateState();
}

class _MatchCreateState extends State<MatchCreateScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String seatPref = '상관없음';
  final _nameCtrl = TextEditingController();
  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _auth.currentUser?.displayName ?? '나(방장)';
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else if (_selectedTags.length < 3) {
        _selectedTags.add(tag);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('태그는 최대 3개까지 선택할 수 있습니다.')));
      }
    });
  }

  void _createParty() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    try {
      final ownerName = _nameCtrl.text.isEmpty ? (user.displayName ?? '익명 방장') : _nameCtrl.text;

      final partyDocRef = await _firestore.collection('match_parties').add({
        'gameId': widget.game.gameId,
        'ownerUid': user.uid,
        'ownerName': ownerName,
        'seatPref': seatPref,
        'maxPlayers': 4,
        'participants': [ownerName],
        'participantUids': [user.uid],
        'tags': _selectedTags,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'searching',
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MatchWaitingScreen(partyId: partyDocRef.id, game: widget.game),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('생성 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(title: Text('파티 만들기'), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('새로운 파티 만들기', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '방장 닉네임', labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)))),
            const SizedBox(height: 20),
            DropdownButtonFormField(value: seatPref, dropdownColor: Colors.grey[800], style: const TextStyle(color: Colors.white), items: ['상관없음', '1루', '3루', '외야', '테이블석'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => seatPref = v as String), decoration: const InputDecoration(labelText: '선호 좌석', labelStyle: TextStyle(color: Colors.grey))),
            const SizedBox(height: 30),
            const Text('태그 선택 (최대 3개)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return ActionChip(
                label: Text(tag, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[300])),
                backgroundColor: isSelected ? Colors.blue[700] : Colors.grey[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.blue[900]! : Colors.grey[600]!)),
                onPressed: () => _toggleTag(tag),
              );
            }).toList()),
            const SizedBox(height: 50),
            SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]), onPressed: _createParty, child: const Text('생성하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))
          ],
        ),
      ),
    );
  }
}

class MatchListScreen extends StatefulWidget {
  final Game game;
  const MatchListScreen({required this.game, super.key});
  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? activeTagFilter;

  void _joinParty(MatchParty party) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (party.participantUids.contains(user.uid)) {
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => MatchWaitingScreen(partyId: party.matchId, game: widget.game)));
      return;
    }

    if (party.participants.length >= party.maxPlayers) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('인원이 가득 찼습니다.')));
      return;
    }

    try {
      await _firestore.collection('match_parties').doc(party.matchId).update({
        'participants': FieldValue.arrayUnion([user.displayName ?? '익명']),
        'participantUids': FieldValue.arrayUnion([user.uid]),
      });
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => MatchWaitingScreen(partyId: party.matchId, game: widget.game)));
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(title: const Text('파티 찾기'), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['전체', ...availableTags].map((tag) {
                  final bool isSelected = (activeTagFilter == null && tag == '전체') || activeTagFilter == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(tag, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[300])),
                      selected: isSelected,
                      onSelected: (bool selected) => setState(() => activeTagFilter = (tag == '전체' || activeTagFilter == tag) ? null : tag),
                      selectedColor: Colors.blue[700],
                      backgroundColor: Colors.grey[700],
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('match_parties').where('gameId', isEqualTo: widget.game.gameId).orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final allParties = snapshot.data?.docs.map((doc) => MatchParty.fromFirestore(doc)).toList() ?? [];
                final filteredParties = allParties.where((p) => (activeTagFilter == null || activeTagFilter == '전체') ? true : p.tags.contains(activeTagFilter)).toList();

                if (filteredParties.isEmpty) return const Center(child: Text("조건에 맞는 파티가 없습니다.", style: TextStyle(color: Colors.grey)));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredParties.length,
                  itemBuilder: (context, index) {
                    final party = filteredParties[index];
                    final isFull = party.participants.length >= party.maxPlayers;
                    return Card(
                      color: Colors.grey[800],
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: isFull ? null : () => _joinParty(party),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${party.ownerName}님의 파티", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: isFull ? Colors.red[700] : Colors.blue[900], borderRadius: BorderRadius.circular(4)),
                                    child: Text(isFull ? '마감' : '${party.participants.length}/${party.maxPlayers}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('좌석: ${party.seatPref}', style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 8),
                              Wrap(spacing: 4, children: party.tags.map((tag) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(4)), child: Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 11)))).toList()),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
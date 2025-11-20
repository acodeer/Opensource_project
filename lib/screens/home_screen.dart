import 'package:flutter/material.dart';
import 'dart:async';
import 'match_waiting_screen.dart'; // ★ 대기방 이동을 위해 추가

// --- 데이터 모델 ---
class Game {
  final String gameId;
  final String homeTeam;
  final String awayTeam;
  final DateTime date;
  final String stadium;

  Game({
    required this.gameId,
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
    required this.stadium,
  });
}

class MatchParty {
  final String matchId;
  final String gameId;
  final String ownerName;
  final String seatPref;
  final int maxPlayers;
  final List<String> participants;
  final DateTime expiresAt;
  String status;
  final List<String> tags;

  MatchParty({
    required this.matchId,
    required this.gameId,
    required this.ownerName,
    required this.seatPref,
    required this.maxPlayers,
    required this.participants,
    required this.expiresAt,
    this.status = 'searching',
    this.tags = const [],
  });
}

// --- 샘플 데이터 ---
List<Game> sampleGames = [
  Game(gameId: 'g1', homeTeam: '두산', awayTeam: 'LG', date: DateTime.now().add(const Duration(hours: 2)), stadium: '잠실'),
  Game(gameId: 'g2', homeTeam: '삼성', awayTeam: '한화', date: DateTime.now().add(const Duration(hours: 2)), stadium: '대구'),
  Game(gameId: 'g3', homeTeam: '롯데', awayTeam: 'NC', date: DateTime.now().add(const Duration(hours: 2)), stadium: '사직'),
  Game(gameId: 'g4', homeTeam: 'KT', awayTeam: 'KIA', date: DateTime.now().add(const Duration(hours: 2)), stadium: '수원'),
  Game(gameId: 'g5', homeTeam: 'SSG', awayTeam: '키움', date: DateTime.now().add(const Duration(hours: 2)), stadium: '인천'),
];

final List<MatchParty> localParties = [];
const List<String> availableTags = ['응원단', '가벼운 술자리', '아이와 동행', '초보 환영', '포토존', '야간 응원'];

// --- ★ 메인 홈 화면 클래스 (KboSchedulePage) ---
class KboSchedulePage extends StatefulWidget {
  const KboSchedulePage({super.key});

  @override
  State<KboSchedulePage> createState() => _KboSchedulePageState();
}

class _KboSchedulePageState extends State<KboSchedulePage> {
  late List<Game> _games;

  @override
  void initState() {
    super.initState();
    _games = sampleGames;
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // 경기 카드 클릭 시 바텀 시트 표시
  void _onGameTap(Game game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900], // 다크 테마
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${game.homeTeam} vs ${game.awayTeam}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '${game.stadium} | ${_formatDate(game.date)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // 파티 만들기 버튼
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.greenAccent,
                    child: Icon(Icons.add, color: Colors.black),
                  ),
                  title: const Text('파티 만들기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('내가 방장이 되어 멤버를 모집합니다', style: TextStyle(color: Colors.white60)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MatchCreateScreen(game: game)));
                  },
                ),
                const SizedBox(height: 10),

                // 파티 찾기 버튼
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.lightBlueAccent,
                    child: Icon(Icons.search, color: Colors.black),
                  ),
                  title: const Text('파티 찾기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('이미 생성된 파티에 참여합니다', style: TextStyle(color: Colors.white60)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MatchListScreen(game: game)));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 야간 경기장 배경
      appBar: AppBar(
        title: const Text('오늘의 경기', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '직관 매칭할 경기를 선택하세요 ⚾',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];
                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                  child: InkWell(
                    onTap: () => _onGameTap(game),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // 팀 로고 대용 (이니셜)
                          CircleAvatar(
                            backgroundColor: Colors.blue[900],
                            child: Text(game.homeTeam.substring(0, 1), style: const TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${game.homeTeam} vs ${game.awayTeam}',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    Text(' ${game.stadium}   ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                    Text(' ${_formatDate(game.date)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- 하위 화면 1: 파티 생성 (MatchCreateScreen) ---
class MatchCreateScreen extends StatefulWidget {
  final Game game;
  const MatchCreateScreen({required this.game, super.key});
  @override
  State<MatchCreateScreen> createState() => _MatchCreateState();
}

class _MatchCreateState extends State<MatchCreateScreen> {
  String seatPref = '상관없음';
  final _nameCtrl = TextEditingController();
  final List<String> _selectedTags = [];

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('${widget.game.homeTeam} vs ${widget.game.awayTeam}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('새로운 파티 만들기', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // 닉네임 입력
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '방장 닉네임',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
            ),
            const SizedBox(height: 20),

            // 좌석 선택
            DropdownButtonFormField<String>(
              value: seatPref,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
              items: ['상관없음', '1루 (홈)', '3루 (원정)', '외야', '테이블석'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => seatPref = v!),
              decoration: const InputDecoration(labelText: '선호 좌석', labelStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 30),

            // ★ 태그 선택 UI (수정됨) ★
            const Text('태그 선택 (최대 3개)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return ActionChip(
                  label: Text(tag, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[300])),
                  backgroundColor: isSelected ? Colors.blue[700] : Colors.grey[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? Colors.blue[900]! : Colors.grey[600]!),
                  ),
                  onPressed: () {
                    if (_selectedTags.length < 3 || isSelected) {
                      _toggleTag(tag);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('태그는 최대 3개까지 선택할 수 있습니다.')),
                      );
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 50),

            // 생성 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
                onPressed: () {
                  // 1. 파티 객체 생성
                  final newParty = MatchParty(
                    matchId: DateTime.now().toString(),
                    gameId: widget.game.gameId,
                    ownerName: _nameCtrl.text.isEmpty ? '나(방장)' : _nameCtrl.text,
                    seatPref: seatPref,
                    maxPlayers: 4,
                    participants: [_nameCtrl.text.isEmpty ? '나(방장)' : _nameCtrl.text],
                    expiresAt: DateTime.now(),
                    tags: _selectedTags,
                  );

                  // 2. 로컬 리스트에 추가
                  localParties.add(newParty);

                  // 3. ★ 대기방으로 이동 (뒤로가기 시 홈으로 가도록 pushReplacement)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchWaitingScreen(party: newParty, game: widget.game),
                    ),
                  );
                },
                child: const Text('생성하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 하위 화면 2: 파티 목록 (MatchListScreen) ---
class MatchListScreen extends StatefulWidget {
  final Game game;
  const MatchListScreen({required this.game, super.key});
  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  String? activeTagFilter;

  @override
  Widget build(BuildContext context) {
    // 태그 필터링 로직
    final parties = localParties.where((p) {
      final isSameGame = p.gameId == widget.game.gameId;
      final hasTag = activeTagFilter == null || activeTagFilter == '전체' || p.tags.contains(activeTagFilter);
      return isSameGame && hasTag;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('파티 찾기'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ★ 태그 필터 UI (수정됨) ★
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
                      label: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[300],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (tag == '전체') {
                            activeTagFilter = null;
                          } else {
                            activeTagFilter = (activeTagFilter == tag) ? null : tag;
                          }
                        });
                      },
                      selectedColor: Colors.blue[700],
                      backgroundColor: Colors.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? Colors.blue[900]! : Colors.grey[600]!),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 파티 리스트
          Expanded(
            child: parties.isEmpty
                ? const Center(
              child: Text(
                '조건에 맞는 파티가 없습니다.\n직접 파티를 만들어보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: parties.length,
              itemBuilder: (context, index) {
                final party = parties[index];
                return Card(
                  color: Colors.grey[800],
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      // ★ 클릭 시 대기방으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MatchWaitingScreen(party: party, game: widget.game),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${party.ownerName}님의 파티', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[900],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${party.participants.length}/${party.maxPlayers}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('좌석: ${party.seatPref}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          // 태그 뱃지
                          Wrap(
                            spacing: 4,
                            children: party.tags.map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
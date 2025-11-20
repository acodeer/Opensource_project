// lib/main.dart
import 'package:flutter/material.dart';
import 'dart:async';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '갈래말래',
      theme: ThemeData.dark(useMaterial3: false),
      home: const MainScreen(),
    );
  }
}

/// 간단한 Game 모델
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

/// MatchParty 모델 (태그 필드 포함)
class MatchParty {
  final String matchId;
  final String gameId;
  final String ownerName;
  final String seatPref;
  final int maxPlayers;
  final List<String> participants;
  final DateTime expiresAt;
  String status; // searching, matched, cancelled, expired
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

/// 샘플 게임 리스트
List<Game> sampleGames = [
  Game(
    gameId: 'g1',
    homeTeam: '두산',
    awayTeam: 'LG',
    date: DateTime.now().add(const Duration(days: 1, hours: 18)),
    stadium: '잠실',
  ),
  Game(
    gameId: 'g2',
    homeTeam: '삼성',
    awayTeam: '한화',
    date: DateTime.now().add(const Duration(days: 1, hours: 18)),
    stadium: '대구',
  ),
  Game(
    gameId: 'g3',
    homeTeam: '롯데',
    awayTeam: 'NC',
    date: DateTime.now().add(const Duration(days: 1, hours: 18)),
    stadium: '사직',
  ),
  Game(
    gameId: 'g4',
    homeTeam: 'KT',
    awayTeam: '기아',
    date: DateTime.now().add(const Duration(days: 1, hours: 18)),
    stadium: '수원',
  ),
  Game(
    gameId: 'g5',
    homeTeam: 'SSG',
    awayTeam: '키움',
    date: DateTime.now().add(const Duration(days: 1, hours: 18)),
    stadium: '인천',
  ),
];

/// 로컬 샘플 파티 저장 (앱 실행 동안 유지)
final List<MatchParty> localParties = [];

/// 공통 태그 리스트 (변경/확장 가능)
const List<String> availableTags = [
  '응원단',
  '가벼운 술자리',
  '아이와 동행',
  '초보 환영',
  '포토존',
  '야간 응원'
];

/// 메인 화면: 배경 + 경기 리스트
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late List<Game> _games;

  @override
  void initState() {
    super.initState();
    _games = sampleGames;
  }

  String _formatDate(DateTime dt) {
    final date = '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date  $time';
  }

  // 카드 탭 시 선택 팝업 표시
  void _onGameTap(Game game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${game.homeTeam} vs ${game.awayTeam}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.group_add, color: Colors.greenAccent),
                  title: const Text('파티 만들기'),
                  subtitle: const Text('직접 파티를 생성하여 참가자를 모집합니다'),
                  onTap: () {
                    Navigator.of(context).pop(); // 바텀시트 닫기
                    Navigator.of(this.context).push(
                      MaterialPageRoute(builder: (_) => MatchCreateScreen(game: game)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search, color: Colors.lightBlueAccent),
                  title: const Text('파티 찾기'),
                  subtitle: const Text('이 경기에 이미 생성된 파티를 찾아 참여합니다'),
                  onTap: () {
                    Navigator.of(context).pop(); // 바텀시트 닫기
                    Navigator.of(this.context).push(
                      MaterialPageRoute(builder: (_) => MatchListScreen(game: game)),
                    );
                  },
                ),
                const SizedBox(height: 8),
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/night_stadium_bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.45))),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('오늘의 KBO 경기', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _games.length,
                    itemBuilder: (context, index) {
                      final game = _games[index];
                      return _GameCard(
                        game: game,
                        formattedDate: _formatDate(game.date),
                        onTap: () => _onGameTap(game),
                      );
                    },
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

/// 경기 카드 (투명도 20%)
class _GameCard extends StatelessWidget {
  final Game game;
  final String formattedDate;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.formattedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardColor = Colors.white.withOpacity(0.2);
    return Card(
      color: cardColor,
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              CircleAvatar(radius: 28, backgroundColor: Colors.transparent, child: Icon(Icons.sports_baseball, color: Colors.orangeAccent, size: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${game.homeTeam}  vs  ${game.awayTeam}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(formattedDate, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(game.stadium, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ]),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

/// MatchCreateScreen: 파티 만들기 (태그 선택 포함)
class MatchCreateScreen extends StatefulWidget {
  final Game game;
  const MatchCreateScreen({required this.game, super.key});
  @override
  State createState() => _MatchCreateState();
}

class _MatchCreateState extends State<MatchCreateScreen> {
  String seatPref = '상관없음';
  int maxPlayers = 4;
  final TextEditingController _nameController = TextEditingController(text: '나');
  List<String> selectedTags = [];

  Future<void> _createMatch() async {
    final now = DateTime.now();
    final matchId = now.millisecondsSinceEpoch.toString();
    final expires = now.add(const Duration(minutes: 10));

    final newParty = MatchParty(
      matchId: matchId,
      gameId: widget.game.gameId,
      ownerName: _nameController.text.isNotEmpty ? _nameController.text : '나',
      seatPref: seatPref,
      maxPlayers: maxPlayers,
      participants: [_nameController.text.isNotEmpty ? _nameController.text : '나'],
      expiresAt: expires,
      tags: selectedTags,
    );

    // 로컬 저장 (Firestore 사용 시 컬렉션에 문서 추가로 변경)
    localParties.add(newParty);

    // 바로 대기 화면으로 이동
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MatchWaitingScreen(matchId: matchId, localMatch: newParty)));
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.homeTeam} vs ${widget.game.awayTeam}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(
            color: Colors.white.withOpacity(0.06),
            child: ListTile(
              leading: Icon(Icons.sports_baseball, color: Colors.orangeAccent),
              title: Text('${widget.game.homeTeam} vs ${widget.game.awayTeam}'),
              subtitle: Text('${widget.game.stadium} • ${widget.game.date.year}.${widget.game.date.month.toString().padLeft(2,'0')}.${widget.game.date.day.toString().padLeft(2,'0')} ${widget.game.date.hour.toString().padLeft(2,'0')}:${widget.game.date.minute.toString().padLeft(2,'0')}'),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: '대표자 이름')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: seatPref,
                items: ['상관없음', '내야', '외야', '지정석'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => seatPref = v ?? '상관없음'),
                decoration: const InputDecoration(labelText: '좌석 선호'),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 110, child: TextFormField(initialValue: maxPlayers.toString(), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '최대 인원'), onChanged: (v) => setState(() => maxPlayers = int.tryParse(v) ?? 4))),
          ]),
          // 태그 선택
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('태그 선택', style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: availableTags.map((tag) {
                    final selected = selectedTags.contains(tag);
                    return ChoiceChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) selectedTags.add(tag);
                          else selectedTags.remove(tag);
                        });
                      },
                      selectedColor: Colors.blueAccent.shade700,
                      backgroundColor: Colors.white12,
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                if (selectedTags.isNotEmpty)
                  Wrap(spacing: 6, children: selectedTags.map((t) => Chip(label: Text(t), backgroundColor: Colors.white10)).toList()),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(onPressed: _createMatch, child: const Padding(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), child: Text('파티 만들기'))),
        ]),
      ),
    );
  }
}

/// MatchListScreen: 해당 경기의 생성된 파티를 보여주고 참여할 수 있음 (태그 필터 포함)
class MatchListScreen extends StatefulWidget {
  final Game game;
  const MatchListScreen({required this.game, super.key});

  @override
  State createState() => _MatchListState();
}

class _MatchListState extends State<MatchListScreen> {
  List<MatchParty> _partiesForGame = [];
  String? activeTagFilter; // null이면 필터 없음

  @override
  void initState() {
    super.initState();
    _loadParties();
  }

  void _loadParties() {
    final all = localParties.where((p) => p.gameId == widget.game.gameId && p.status == 'searching');
    if (activeTagFilter != null) {
      _partiesForGame = all.where((p) => p.tags.contains(activeTagFilter)).toList();
    } else {
      _partiesForGame = all.toList();
    }
    setState(() {});
  }

  // 참가 처리 (로컬)
  void _joinParty(MatchParty party) {
    if (party.participants.length >= party.maxPlayers) return;
    party.participants.add('참가자${party.participants.length}'); // 샘플 이름
    if (party.participants.length >= party.maxPlayers) {
      party.status = 'matched';
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MatchConfirmedScreen(matchData: party)));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MatchWaitingScreen(matchId: party.matchId, localMatch: party)));
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadParties(); // 간단 구현: 진입시 갱신
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.homeTeam} vs ${widget.game.awayTeam} — 파티 찾기')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 태그 필터 영역
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: ['전체', ...availableTags].map((tag) {
                  final isAll = tag == '전체';
                  final active = (isAll && activeTagFilter == null) || (!isAll && activeTagFilter == tag);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tag),
                      selected: active,
                      onSelected: (_) {
                        setState(() {
                          activeTagFilter = isAll ? null : tag;
                          _loadParties();
                        });
                      },
                      selectedColor: Colors.blueAccent,
                      backgroundColor: Colors.white12,
                      labelStyle: TextStyle(color: active ? Colors.white : Colors.white70),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _partiesForGame.isEmpty
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('생성된 파티가 없습니다', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MatchCreateScreen(game: widget.game))), child: const Text('직접 파티 만들기')),
              ])
                  : ListView.separated(
                itemCount: _partiesForGame.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = _partiesForGame[i];
                  return Card(
                    color: Colors.white.withOpacity(0.06),
                    child: ListTile(
                      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${p.ownerName}의 파티 (${p.participants.length}/${p.maxPlayers})'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: p.tags.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                            child: Text(tag, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          )).toList(),
                        ),
                      ]),
                      subtitle: Text('좌석: ${p.seatPref} • 만료 ${p.expiresAt.hour.toString().padLeft(2,'0')}:${p.expiresAt.minute.toString().padLeft(2,'0')}'),
                      trailing: ElevatedButton(onPressed: () => _joinParty(p), child: const Text('참가')),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MatchWaitingScreen(matchId: p.matchId, localMatch: p))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// MatchWaitingScreen: 파티 대기 화면 (로컬 샘플/Firestore 스트림으로 대체 가능)
class MatchWaitingScreen extends StatefulWidget {
  final String matchId;
  final MatchParty? localMatch;
  const MatchWaitingScreen({required this.matchId, this.localMatch, super.key});

  @override
  State createState() => _MatchWaitingState();
}

class _MatchWaitingState extends State<MatchWaitingScreen> {
  late Timer _timer;
  Duration _remaining = Duration.zero;
  MatchParty? _match;

  @override
  void initState() {
    super.initState();
    if (widget.localMatch != null) {
      _match = widget.localMatch!;
      _remaining = _match!.expiresAt.difference(DateTime.now());
    } else {
      _match = localParties.firstWhere((p) => p.matchId == widget.matchId,);
      if (_match != null) _remaining = _match!.expiresAt.difference(DateTime.now());
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    setState(() {
      if (_remaining.inSeconds > 0) {
        _remaining = _remaining - const Duration(seconds: 1);
      } else {
        _timer.cancel();
        if (_match != null) _match!.status = 'expired';
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _cancelMatch() {
    if (_match != null) {
      _match!.status = 'cancelled';
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_match == null) {
      return Scaffold(appBar: AppBar(title: const Text('매칭 대기')), body: const Center(child: Text('파티 정보를 찾을 수 없습니다')));
    }

    final participants = _match!.participants;
    final maxPlayers = _match!.maxPlayers;

    return Scaffold(
      appBar: AppBar(title: const Text('매칭 대기')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(color: Colors.white.withOpacity(0.04), child: ListTile(title: Text('참가자 ${participants.length} / $maxPlayers', style: const TextStyle(fontSize: 18)), subtitle: Text('좌석: ${_match!.seatPref}'))),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: participants.map((p) => CircleAvatar(radius: 22, child: Text(p.substring(0, 1)))).toList()),
          const SizedBox(height: 12),
          Wrap(spacing: 6, children: _match!.tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: Text(tag, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          )).toList()),
          const Spacer(),
          Text('남은 시간: ${_remaining.inMinutes}분 ${_remaining.inSeconds % 60}초', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: () {
              // 테스트용: 다른 참가자 자동 추가(로컬)
              if (_match!.participants.length < _match!.maxPlayers) {
                setState(() {
                  _match!.participants.add('참가자${_match!.participants.length}');
                  if (_match!.participants.length >= _match!.maxPlayers) {
                    _match!.status = 'matched';
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MatchConfirmedScreen(matchData: _match!)));
                  }
                });
              }
            }, child: const Text('샘플 참가자 추가'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: _cancelMatch, child: const Text('취소'))),
          ])
        ]),
      ),
    );
  }
}

/// MatchConfirmedScreen: 매칭 완료 화면
class MatchConfirmedScreen extends StatelessWidget {
  final MatchParty matchData;
  const MatchConfirmedScreen({required this.matchData, super.key});

  @override
  Widget build(BuildContext c) {
    final participants = matchData.participants;
    return Scaffold(
      appBar: AppBar(title: const Text('매칭 완료')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('매칭이 완료되었습니다', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: matchData.tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
              child: Text(tag, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const Divider(),
              itemCount: participants.length,
              itemBuilder: (context, i) {
                final name = participants[i];
                return ListTile(leading: CircleAvatar(child: Text(name.substring(0, 1))), title: Text(name));
              },
            ),
          ),
          ElevatedButton(onPressed: () => Navigator.of(c).popUntil((r) => r.isFirst), child: const Text('확인')),
        ]),
      ),
    );
  }
}
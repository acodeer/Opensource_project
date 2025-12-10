// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'match_waiting_screen.dart';
import '../models/match_model.dart';
import '../models/user_model.dart'; // UserModel은 사용자 정보에 필요
import 'webview_screen.dart';

List<Game> sampleGames = [
  Game(gameId: 'g1', homeTeam: '두산', awayTeam: 'LG', date: DateTime.now().add(const Duration(hours: 2)), stadium: '잠실'),
  Game(gameId: 'g2', homeTeam: '삼성', awayTeam: '한화', date: DateTime.now().add(const Duration(hours: 2)), stadium: '대구'),
  Game(gameId: 'g3', homeTeam: '롯데', awayTeam: 'NC', date: DateTime.now().add(const Duration(hours: 2)), stadium: '사직'),
  Game(gameId: 'g4', homeTeam: 'KT', awayTeam: 'KIA', date: DateTime.now().add(const Duration(hours: 2)), stadium: '수원'),
  Game(gameId: 'g5', homeTeam: 'SSG', awayTeam: '키움', date: DateTime.now().add(const Duration(hours: 2)), stadium: '인천'),
];

const List<String> availableTags = ['응원단', '가벼운 술자리', '아이와 동행', '초보 환영', '포토존', '야간 응원'];

// --- 메인 홈 화면 클래스 ---
class MatchGameScheduleScreen extends StatefulWidget {
  const MatchGameScheduleScreen({super.key});

  @override
  State<MatchGameScheduleScreen> createState() => _MatchGameScheduleScreenState();
}

class _MatchGameScheduleScreenState extends State<MatchGameScheduleScreen> {
  late List<Game> _games;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;


  @override
  void initState() {
    super.initState();
    _games = sampleGames;
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // 사용자 참여 중인 파티를 찾아 MatchParty 객체를 반환하는 함수
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
      print("Active party check failed: $e");
      return null;
    }
  }


  // 경기 카드 클릭 시 바텀 시트 표시
  void _onGameTap(Game game) async {
    // 1. 로그인 체크
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    // 2. 이미 참여 중인 파티가 있는지 확인
    final activeParty = await _findActiveParty();

    if (activeParty != null) {
      // 3. 이미 참여 중이면 해당 파티의 대기방으로 즉시 이동
      if (context.mounted) {
        // 오류 수정 완료된 코드 사용
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 참여 중인 파티가 있습니다. 해당 파티로 이동합니다.'),
              duration: Duration(seconds: 2),
            )
        );

        final activeGame = _games.firstWhere(
                (g) => g.gameId == activeParty.gameId,
            orElse: () => game
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MatchWaitingScreen(
              partyId: activeParty.matchId,
              game: activeGame,
            ),
          ),
        );
      }
      return;
    }

    // 4. 참여 중인 파티가 없으면 기존 로직대로 Bottom Sheet 표시
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
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

          // ★ 웹뷰 링크 UI 추가 (Expanded 밖, Column의 마지막 부분)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Card(
              color: Colors.grey[850],
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: InkWell(
                onTap: () {
                  // 웹뷰 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WebViewScreen(
                        title: 'KBO 공식 기록 / 일정',
                        url: 'https://www.koreabaseball.com/record/schedule.do', // KBO 공식 사이트 예시
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.link, color: Colors.blueAccent),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'KBO 공식 기록 / 실시간 데이터 확인',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
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
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance; // ★ Firestore 인스턴스

  String seatPref = '상관없음';
  final _nameCtrl = TextEditingController();
  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    // 로그인된 사용자 이름으로 닉네임 필드 초기화
    _nameCtrl.text = _auth.currentUser?.displayName ?? '나(방장)';
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else if (_selectedTags.length < 3) {
        _selectedTags.add(tag);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('태그는 최대 3개까지 선택할 수 있습니다.')),
        );
      }
    });
  }

  // ★ 파티 생성 로직 (Firestore)
  void _createParty() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    // 1. 최종 중복 참여 확인 (다른 파티에 이미 참여 중이면 생성 불가)
    try {
      final existingPartySnapshot = await _firestore.collection('match_parties')
          .where('participantUids', arrayContains: user.uid)
          .limit(1)
          .get();

      if (existingPartySnapshot.docs.isNotEmpty) {
        if (mounted) {
          // ★ 오류 수정: duration을 SnackBar의 속성으로 올바르게 지정
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('이미 다른 파티에 참여 중입니다. 먼저 해당 파티를 나가주세요.'),
                duration: Duration(seconds: 3),
              )
          );
        }
        // 이미 참여 중인 파티가 있다면, 생성하지 않고 대기방으로 이동
        final activePartyId = existingPartySnapshot.docs.first.id;
        if (mounted) {
          final MatchParty activeParty = MatchParty.fromFirestore(existingPartySnapshot.docs.first);

          final activeGame = sampleGames.firstWhere(
                  (g) => g.gameId == activeParty.gameId,
              orElse: () => widget.game // 오류 방지
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MatchWaitingScreen(partyId: activePartyId, game: activeGame),
            ),
          );
        }
        return;
      }

      // 2. Firestore에 새 파티 문서 추가
      final ownerName = _nameCtrl.text.trim().isEmpty ? (user.displayName ?? '익명 방장') : _nameCtrl.text.trim();
      final partyDocRef = await _firestore.collection('match_parties').add({
        'gameId': widget.game.gameId,
        'ownerUid': user.uid,
        'ownerName': ownerName,
        'seatPref': seatPref,
        'maxPlayers': 4, // 고정값 사용
        'participants': [ownerName], // 방장 이름 포함
        'participantUids': [user.uid], // 방장 UID 포함
        'tags': _selectedTags,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'searching',
      });

      // 3. 대기방으로 이동
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('파티가 생성되었습니다!')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MatchWaitingScreen(
              partyId: partyDocRef.id, // 생성된 문서 ID 전달
              game: widget.game,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('파티 생성 실패: $e')));
      }
    }
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

            // 태그 선택 UI
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
                onPressed: _createParty, // ★ _createParty 함수 연결
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
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? activeTagFilter;

  // ★ 파티 참여 로직 (Firestore 업데이트)
  void _joinParty(MatchParty party) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. 이미 참여 중인지 확인 (대상 파티 내)
    if (party.participantUids.contains(user.uid)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 참여 중인 파티입니다. 대기방으로 이동합니다.')));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MatchWaitingScreen(partyId: party.matchId, game: widget.game),
          ),
        );
      }
      return;
    }

    // 2. 최종 중복 참여 확인 (다른 파티 포함)
    try {
      final existingPartySnapshot = await _firestore.collection('match_parties')
          .where('participantUids', arrayContains: user.uid)
          .limit(1)
          .get();

      if (existingPartySnapshot.docs.isNotEmpty) {
        final activePartyId = existingPartySnapshot.docs.first.id;
        // 다른 파티에 참여 중이라면 (단, 현재 참여하려는 파티가 아닌 경우)
        if (activePartyId != party.matchId) {
          if (mounted) {
            // ★ 오류 수정: duration을 SnackBar의 속성으로 올바르게 지정
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('이미 다른 파티에 참여 중이므로 매칭할 수 없습니다. 해당 파티로 이동합니다.'),
                  duration: Duration(seconds: 3),
                )
            );

            final MatchParty activeParty = MatchParty.fromFirestore(existingPartySnapshot.docs.first);
            final activeGame = sampleGames.firstWhere(
                    (g) => g.gameId == activeParty.gameId,
                orElse: () => widget.game
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MatchWaitingScreen(partyId: activePartyId, game: activeGame),
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      print("Duplication check failed: $e");
      // 오류 발생 시 경고만 주고 로직 진행 (최소한의 방어)
    }

    // 3. 인원 초과 확인
    if (party.participants.length >= party.maxPlayers) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 인원이 가득 찼습니다.')));
      }
      return;
    }

    // 4. 파티 참여 로직
    try {
      final userDisplayName = user.displayName ?? '익명 참여자';
      final partyRef = _firestore.collection('match_parties').doc(party.matchId);

      // participants와 participantUids 배열에 사용자 추가
      await partyRef.update({
        'participants': FieldValue.arrayUnion([userDisplayName]),
        'participantUids': FieldValue.arrayUnion([user.uid]),
      });

      // 대기방으로 이동
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('파티에 참여했습니다!')));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MatchWaitingScreen(partyId: party.matchId, game: widget.game),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('파티 참여 실패: $e')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('파티 찾기'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ★ 태그 필터 UI (기존 로직 유지)
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

          // ★ 파티 리스트 (StreamBuilder로 Firestore 연동)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('match_parties')
                  .where('gameId', isEqualTo: widget.game.gameId) // 해당 경기만 필터링
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('파티 로딩 오류: ${snapshot.error}', style: TextStyle(color: Colors.grey)));
                }

                // 1. 데이터 파싱
                final allParties = snapshot.data!.docs.map((doc) => MatchParty.fromFirestore(doc)).toList();

                // 2. 태그 필터링 (클라이언트 단에서 필터링)
                final filteredParties = allParties.where((p) {
                  if (activeTagFilter == null || activeTagFilter == '전체') return true;
                  return p.tags.contains(activeTagFilter);
                }).toList();

                // 3. 필터링된 목록이 비어있는 경우
                if (filteredParties.isEmpty) {
                  return const Center(
                    child: Text(
                      '조건에 맞는 파티가 없습니다.\n직접 파티를 만들어보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                // 4. 리스트 표시
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredParties.length,
                  itemBuilder: (context, index) {
                    final party = filteredParties[index];
                    final isFull = party.participants.length >= party.maxPlayers;

                    return Card(
                      color: isFull ? Colors.grey[900] : Colors.grey[800],
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: isFull ? null : () => _joinParty(party), // ★ _joinParty 함수 연결
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      '${party.ownerName}님의 파티',
                                      style: TextStyle(color: isFull ? Colors.grey : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isFull ? Colors.red[700] : Colors.blue[900],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isFull ? '마감' : '${party.participants.length}/${party.maxPlayers}',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
import '../models/match_model.dart';

// 2026년 가상 일정 (3월 개막 ~ 4월 초)
List<Game> season2026 = [
  // ==========================
  // [3월] 2026 정규시즌 개막 시리즈
  // ==========================

  // 3월 21일 (토) - 개막전 (14:00)
  Game(gameId: '260321_1', date: DateTime(2026, 3, 21, 14, 0), stadium: '잠실', homeTeam: 'LG', awayTeam: '두산', isFinished: false),
  Game(gameId: '260321_2', date: DateTime(2026, 3, 21, 14, 0), stadium: '문학', homeTeam: 'SSG', awayTeam: '롯데', isFinished: false),
  Game(gameId: '260321_3', date: DateTime(2026, 3, 21, 14, 0), stadium: '창원', homeTeam: 'NC', awayTeam: 'KIA', isFinished: false),
  Game(gameId: '260321_4', date: DateTime(2026, 3, 21, 14, 0), stadium: '수원', homeTeam: 'KT', awayTeam: '삼성', isFinished: false),
  Game(gameId: '260321_5', date: DateTime(2026, 3, 21, 14, 0), stadium: '고척', homeTeam: '키움', awayTeam: '한화', isFinished: false),

  // 3월 22일 (일) - 개막 시리즈 2차전 (14:00)
  Game(gameId: '260322_1', date: DateTime(2026, 3, 22, 14, 0), stadium: '잠실', homeTeam: 'LG', awayTeam: '두산', isFinished: false),
  Game(gameId: '260322_2', date: DateTime(2026, 3, 22, 14, 0), stadium: '문학', homeTeam: 'SSG', awayTeam: '롯데', isFinished: false),
  Game(gameId: '260322_3', date: DateTime(2026, 3, 22, 14, 0), stadium: '창원', homeTeam: 'NC', awayTeam: 'KIA', isFinished: false),
  Game(gameId: '260322_4', date: DateTime(2026, 3, 22, 14, 0), stadium: '수원', homeTeam: 'KT', awayTeam: '삼성', isFinished: false),
  Game(gameId: '260322_5', date: DateTime(2026, 3, 22, 14, 0), stadium: '고척', homeTeam: '키움', awayTeam: '한화', isFinished: false),

  // 3월 24일 (화) - 주중 3연전 (18:30)
  Game(gameId: '260324_1', date: DateTime(2026, 3, 24, 18, 30), stadium: '광주', homeTeam: 'KIA', awayTeam: 'LG', isFinished: false),
  Game(gameId: '260324_2', date: DateTime(2026, 3, 24, 18, 30), stadium: '사직', homeTeam: '롯데', awayTeam: '키움', isFinished: false),
  Game(gameId: '260324_3', date: DateTime(2026, 3, 24, 18, 30), stadium: '대전', homeTeam: '한화', awayTeam: 'SSG', isFinished: false),
  Game(gameId: '260324_4', date: DateTime(2026, 3, 24, 18, 30), stadium: '대구', homeTeam: '삼성', awayTeam: 'NC', isFinished: false),
  Game(gameId: '260324_5', date: DateTime(2026, 3, 24, 18, 30), stadium: '잠실', homeTeam: '두산', awayTeam: 'KT', isFinished: false),

  // 3월 25일 (수)
  Game(gameId: '260325_1', date: DateTime(2026, 3, 25, 18, 30), stadium: '광주', homeTeam: 'KIA', awayTeam: 'LG', isFinished: false),
  Game(gameId: '260325_2', date: DateTime(2026, 3, 25, 18, 30), stadium: '사직', homeTeam: '롯데', awayTeam: '키움', isFinished: false),
  Game(gameId: '260325_3', date: DateTime(2026, 3, 25, 18, 30), stadium: '대전', homeTeam: '한화', awayTeam: 'SSG', isFinished: false),
  Game(gameId: '260325_4', date: DateTime(2026, 3, 25, 18, 30), stadium: '대구', homeTeam: '삼성', awayTeam: 'NC', isFinished: false),
  Game(gameId: '260325_5', date: DateTime(2026, 3, 25, 18, 30), stadium: '잠실', homeTeam: '두산', awayTeam: 'KT', isFinished: false),

  // 3월 26일 (목)
  Game(gameId: '260326_1', date: DateTime(2026, 3, 26, 18, 30), stadium: '광주', homeTeam: 'KIA', awayTeam: 'LG', isFinished: false),
  Game(gameId: '260326_2', date: DateTime(2026, 3, 26, 18, 30), stadium: '사직', homeTeam: '롯데', awayTeam: '키움', isFinished: false),
  Game(gameId: '260326_3', date: DateTime(2026, 3, 26, 18, 30), stadium: '대전', homeTeam: '한화', awayTeam: 'SSG', isFinished: false),
  Game(gameId: '260326_4', date: DateTime(2026, 3, 26, 18, 30), stadium: '대구', homeTeam: '삼성', awayTeam: 'NC', isFinished: false),
  Game(gameId: '260326_5', date: DateTime(2026, 3, 26, 18, 30), stadium: '잠실', homeTeam: '두산', awayTeam: 'KT', isFinished: false),

  // 3월 27일 (금) - 주말 3연전 (18:30)
  Game(gameId: '260327_1', date: DateTime(2026, 3, 27, 18, 30), stadium: '문학', homeTeam: 'SSG', awayTeam: 'KIA', isFinished: false),
  Game(gameId: '260327_2', date: DateTime(2026, 3, 27, 18, 30), stadium: '고척', homeTeam: '키움', awayTeam: '삼성', isFinished: false),
  Game(gameId: '260327_3', date: DateTime(2026, 3, 27, 18, 30), stadium: '수원', homeTeam: 'KT', awayTeam: '롯데', isFinished: false),
  Game(gameId: '260327_4', date: DateTime(2026, 3, 27, 18, 30), stadium: '창원', homeTeam: 'NC', awayTeam: '두산', isFinished: false),
  Game(gameId: '260327_5', date: DateTime(2026, 3, 27, 18, 30), stadium: '잠실', homeTeam: 'LG', awayTeam: '한화', isFinished: false),

  // 3월 28일 (토) - (17:00)
  Game(gameId: '260328_1', date: DateTime(2026, 3, 28, 17, 0), stadium: '문학', homeTeam: 'SSG', awayTeam: 'KIA', isFinished: false),
  Game(gameId: '260328_2', date: DateTime(2026, 3, 28, 17, 0), stadium: '고척', homeTeam: '키움', awayTeam: '삼성', isFinished: false),
  Game(gameId: '260328_3', date: DateTime(2026, 3, 28, 17, 0), stadium: '수원', homeTeam: 'KT', awayTeam: '롯데', isFinished: false),
  Game(gameId: '260328_4', date: DateTime(2026, 3, 28, 17, 0), stadium: '창원', homeTeam: 'NC', awayTeam: '두산', isFinished: false),
  Game(gameId: '260328_5', date: DateTime(2026, 3, 28, 17, 0), stadium: '잠실', homeTeam: 'LG', awayTeam: '한화', isFinished: false),

  // 3월 29일 (일) - (14:00)
  Game(gameId: '260329_1', date: DateTime(2026, 3, 29, 14, 0), stadium: '문학', homeTeam: 'SSG', awayTeam: 'KIA', isFinished: false),
  Game(gameId: '260329_2', date: DateTime(2026, 3, 29, 14, 0), stadium: '고척', homeTeam: '키움', awayTeam: '삼성', isFinished: false),
  Game(gameId: '260329_3', date: DateTime(2026, 3, 29, 14, 0), stadium: '수원', homeTeam: 'KT', awayTeam: '롯데', isFinished: false),
  Game(gameId: '260329_4', date: DateTime(2026, 3, 29, 14, 0), stadium: '창원', homeTeam: 'NC', awayTeam: '두산', isFinished: false),
  Game(gameId: '260329_5', date: DateTime(2026, 3, 29, 14, 0), stadium: '잠실', homeTeam: 'LG', awayTeam: '한화', isFinished: false),
];
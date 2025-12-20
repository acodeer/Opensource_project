⚾ (직관)갈래말래 - KBO 실시간 직관 매칭 플랫폼
"혼자 가기 망설여지는 야구장, 이제 취향 맞는 파트너와 함께하세요!" > (직관)갈래말래는 KBO 경기 일정을 기반으로 직관 동행을 찾고, 실시간으로 소통하며 야구 데이터를 확인하는 올인원 소셜 플랫폼입니다.

📌 주요 기능 (Key Features)
1. 스마트 직관 매칭
경기 일정 캘린더: 내장된 2025/2026 시즌 데이터를 통해 경기 일정 및 결과 조회.

맞춤형 파티 탐색: 좌석 선호도, 응원 성향 태그별 파티 필터링.

실시간 매칭: 클릭 한 번으로 파티 참여 및 방 개설 가능.

2. 다층적 커뮤니티
프라이빗 채팅: 매칭된 파티원 간의 약속 조율을 위한 전용 채팅방.

당일 오픈 채팅: 경기 당일 모든 팬이 참여하는 실시간 응원 채널.

팬 게시판: VLOG 후기, 맛집 공유, 티켓 양도 정보를 위한 카테고리별 게시판.

3. 데이터 인프라
실시간 스탯 조회: 외부 KBO 기록실 및 티켓 예매처 웹뷰(WebView) 연동.

미디어 재생: 유튜브 API를 활용한 직관 VLOG 영상 앱 내 재생.

🏗 시스템 아키텍처 (System Architecture)
Frontend: Flutter (Dart) - Cross-platform (Android/iOS)

Backend: Firebase Cloud Firestore (Real-time DB), Firebase Auth, Firebase Storage

State Management: Provider / StreamBuilder

Integration: WebView Flutter, YouTube Player API

📂 프로젝트 구조 (Project Structure)
Plaintext

lib/
├── data/           # 내장 경기 일정 데이터 (season_2025.dart)
├── models/         # 데이터 모델 클래스 (user_model.dart, match_model.dart)
├── screens/        # UI 화면 구성 (home, chat, board, webview)
├── services/       # Firebase 연동 및 공통 로직
└── widgets/        # 재사용 가능한 UI 컴포넌트 (chat_bubble, post_card)
🚀 시작하기 (Getting Started)
사전 요구 사항
Flutter SDK (3.2.0 이상 추천)

Firebase 프로젝트 설정 및 google-services.json (Android) / GoogleService-Info.plist (iOS) 파일

설치 및 실행
저장소 클론

Bash

git clone https://github.com/username/project-name.git
패키지 설치

Bash

flutter pub get
앱 실행

Bash

flutter run
🛠 기술 스택 (Tech Stack)
언어: Dart

프레임워크: Flutter

데이터베이스: Google Cloud Firestore

인증: Firebase Authentication (Google Social Login)

주요 패키지:

firebase_core, cloud_firestore

webview_flutter

Youtubeer_flutter

image_picker

📈 기대 효과 및 향후 계획
KBO API 고도화: 실시간 경기 상황 및 우천 취소 정보 자동 반영 예정.

신뢰 시스템: 유저 간 매너 온도 및 리뷰 시스템 도입 예정.

비즈니스 확장: 구장 인근 상권 연계 쿠폰 및 배달 서비스 기획.

📄 라이선스 (License)
본 프로젝트는 오픈소스 학습 및 경진대회 참가를 목적으로 제작되었습니다.

💡 README 작성 팁
스크린샷 추가: 위 내용 중 ## 주요 기능 섹션 아래에 실제 앱의 스크린샷 이미지를 넣으면 훨씬 눈에 잘 들어옵니다.

배지(Badge) 활용: 상단에 사용된 배지는 프로젝트의 기술 스택을 한눈에 보여주는 좋은 도구입니다.

Gif 애니메이션: 매칭 과정이나 채팅 과정을 gif 파일로 만들어 넣으면 동작 설명을 텍스트보다 훨씬 효과적으로 전달할 수 있습니다.

이 내용을 깃허브의 README.md 파일에 복사해서 사용해 보세요! 추가로 수정하고 싶은 부분이 있으신가요?

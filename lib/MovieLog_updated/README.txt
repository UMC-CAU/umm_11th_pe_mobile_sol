MovieLog 수정본 적용 안내

기존 프로젝트의 lib 폴더를 삭제하지 말고, ZIP의 lib 안 파일들을 같은 위치에 덮어쓰세요.
movie_card.dart는 새 파일입니다. main.dart, sign_up_screen.dart, home_screen.dart,
movies_screen.dart, profile_screen.dart를 수정했습니다. 나머지는 첨부 원본입니다.

변경 사항
- /signup GoRoute 추가, 시작하기는 context.go로 회원가입 이동
- 회원가입 검증 성공 시 홈 이동, 뒤로가기 버튼 제거 및 PopScope 적용
- 홈 인기 영화 4개 표시, 홈과 영화 목록에서 공통 MovieCard 사용
- 프로필 수정 BottomSheet: 닉네임/자기소개 편집, 2자 이상 검증, 저장 Snackbar
- 파일명에서 업로드 중복 표기 (1), (2) 제거

기존 assets 및 pubspec.yaml은 그대로 필요합니다. 이 ZIP은 전체 Flutter 프로젝트가 아닙니다.
특히 assets/icons/error.svg, 포스터 이미지, 로고, Manrope 폰트 등록을 확인하세요.
첨부에 assets와 pubspec.yaml이 없어 자산 존재 여부는 검증하지 못했습니다.

적용 후 프로젝트 루트에서:
flutter pub get
flutter analyze
flutter run

go_router, flutter_rating_bar, flutter_svg가 없다면:
flutter pub add go_router flutter_rating_bar flutter_svg

확인 흐름:
시작하기 → 회원가입(뒤로가기 불가) → 유효 입력/약관 동의 → 홈(뒤로가기 불가)
홈 카드 → 해당 상세 → 뒤로가기
영화 탭 → 장르 선택 → 상세 → 평점 선택/저장 → 즐겨찾기 추가/삭제
마이 탭 → 프로필 수정 → 키보드 입력 → 저장 또는 취소

프로필/평점/즐겨찾기는 화면 내부 상태입니다. 화면 재생성/앱 재시작 후 초기화될 수 있습니다.
이 환경에는 Flutter/Dart SDK가 없어 flutter analyze 및 시뮬레이터 실행은 수행하지 못했습니다.
상대 import 연결과 변경 코드를 검토했습니다. PR 실행 영상은 실제 기기에서 녹화하세요.

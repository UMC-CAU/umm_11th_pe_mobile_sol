# MovieLog · 6주차 중복 확인과 내 평점 조회

기존 `movielog_week5.zip`의 Flutter 프로젝트에 6주차 Guided / Required / Challenge를 구현했습니다. 기존 시작·영화 홈·목록·상세·프로필 화면을 유지합니다.

## 실행

압축을 풀고 `movielog_week6` 폴더를 VS Code 또는 Android Studio에서 엽니다. `pubspec.yaml`이 있는 위치에서 실행합니다.

```bash
cp .env.example .env
flutter pub get
flutter run
```

`.env`의 `TMDB_ACCESS_TOKEN=` 뒤에 기존 5주차에서 사용한 본인의 **TMDB API Read Access Token**을 넣습니다. 앞에 `Bearer`를 붙이지 않습니다.

```dotenv
TMDB_ACCESS_TOKEN=본인의_READ_ACCESS_TOKEN
MOVIELOG_API_BASE_URL=https://workbook.devnoco.com
```

워크북 API는 토큰 없이 닉네임·이메일·평점을 조회합니다. TMDB 토큰이 없어도 중복 확인과 평점 목록 조회는 동작하며, 영화 제목·포스터는 대체 표시됩니다. 토큰 수정 후에는 앱을 완전히 종료하고 다시 실행합니다. `.env`는 압축·Git에 포함하지 않습니다.

기존 Git 프로젝트에 적용하려면 이 폴더의 파일을 같은 경로에 복사하고, 기존 `.git`과 개인 `.env`는 유지합니다. `lib`뿐 아니라 `.env.example`, `test`, `tool`, `docs`도 함께 복사합니다.

## 구현 내용

- **공용 MovieLogButton**: `lib/widgets/movielog_button.dart`. 기본 / 회색 비활성 / 통신 중 인디케이터, 내용 너비 / 최대 너비 / 고정 너비 지원.
- **회원가입**: 닉네임·이메일 오른쪽에 중복 확인 버튼을 각각 배치합니다. 사용 가능 안내, 중복 에러, 통신 실패 에러를 구분합니다. 두 필드가 확인 완료 상태이고 비밀번호·약관 조건도 맞아야 가입하기가 활성화됩니다.
- **입력 변경**: 이전 확인 결과가 즉시 무효화됩니다. 마지막으로 중복이 확인된 값을 다시 입력하면 API를 재호출하지 않고 에러·버튼 비활성 상태를 복원합니다. 비교에는 `trim()`을 사용합니다.
- **비동기 안전성**: 닉네임·이메일은 별도의 요청 버전을 사용합니다. 요청 중 입력 변경, 같은 값으로 돌아오기, 화면 종료 후 응답을 모두 처리합니다.
- **내 평점**: 마이페이지 → 내가 등록한 평점(`/my/ratings`). 학습용 회원 번호는 상수 `sampleMemberId = 1`입니다. 중앙 앱바와 뒤로가기, Loading / Empty / Error / Success, 재시도·새로고침을 제공합니다.
- **영화 정보 연결**: 기존 `TmdbMovieService.fetchMovie()`로 평점의 TMDB ID에 해당하는 제목·포스터를 조회합니다. 동일 ID는 캐시합니다. 404는 대체 표시로 캐시하고 일시적 실패는 다음 로딩에서 재시도합니다. 영화 조회가 실패해도 점수·후기·등록일은 유지합니다. `comment: null`은 생략합니다.
- **화면 이동**: root Navigator 위에 평점 화면을 열어 하단 탭을 가립니다. 뒤로가면 마이페이지로 돌아옵니다.
- **API 분리**: `MemberCheckService`와 `RatingApiService`는 하나의 MovieLog Dio를 공유합니다. TMDB의 주소·Authorization과 섞이지 않습니다. v5 응답은 Wrapper 없이 직접 파싱합니다.

6주차 프론트엔드는 **v5의 GET API 3개**를 사용합니다. 가입하기는 검증 후 홈으로 이동하는 동작이며, 실제 회원가입 POST와 평점 CRUD는 포함하지 않습니다. 화면에 현재 로그인 사용자라는 안내나 다른 사용자의 평점 수정·삭제 버튼을 제공하지 않습니다.

## 상태별 화면 확인 / 녹화

일반 실행 `flutter run`은 실제 API를 사용합니다. 아래 별도 진입점은 **가짜 데이터로 상태를 재현하는 데모**이며 상단에 DEMO 표시가 있습니다. 개인 TMDB 토큰 없이 실행할 수 있습니다.

회원가입:

```bash
flutter run -t tool/week6_demo.dart --dart-define=DEMO_ROUTE=/signup
```

| 입력 | 데모 결과 |
| --- | --- |
| 닉네임 `중복닉네임` | 중복 |
| 이메일 `taken@example.com` | 중복 |
| 닉네임 `오류닉네임` | 통신 실패 |
| 이메일 `error@example.com` | 통신 실패 |
| 그 외 형식이 올바른 입력 | 사용 가능 |

중복 확인은 1초 뒤 응답하여 통신 중 상태를 확인할 수 있습니다. 중복 값 → 다른 값 → 원래 중복 값 순서로 입력하면 챌린지 미션을 확인할 수 있습니다.

내 평점 네 가지 상태:

```bash
flutter run -t tool/week6_demo.dart --dart-define=DEMO_ROUTE=/my/ratings --dart-define=RATINGS_MODE=loading
flutter run -t tool/week6_demo.dart --dart-define=DEMO_ROUTE=/my/ratings --dart-define=RATINGS_MODE=empty
flutter run -t tool/week6_demo.dart --dart-define=DEMO_ROUTE=/my/ratings --dart-define=RATINGS_MODE=error
flutter run -t tool/week6_demo.dart --dart-define=DEMO_ROUTE=/my/ratings --dart-define=RATINGS_MODE=success
```

명령을 바꿀 때는 실행 중인 앱을 종료한 뒤 다시 실행합니다. 마이페이지에서 진입하는 동작은 아래 명령으로 확인합니다.

```bash
flutter run -t tool/week6_demo.dart
```

버튼 너비 3종과 통신 중·비활성 상태:

```bash
flutter run -t tool/week6_buttons.dart
```

## 검증과 제출 자료

```bash
flutter analyze
flutter test
```

69개 자동 테스트가 통과했습니다. 테스트는 실제 API 통신과 구분되는 가짜 응답을 사용합니다. 서비스 구현의 실제 v5 GET 통신은 아래 읽기 전용 검사로 별도 확인했습니다.

```bash
dart run tool/week6_live_check.dart
```

- [실습 검증 기록](docs/week6_verification.md): 항목별 검증과 수동 확인할 부분
- [PR·제출 양식 초안](docs/week6_submission.md): PR 본문, 트러블슈팅, 회고 초안
- [화면 예시](docs/evidence): Widget 렌더링으로 생성한 데모 화면 PNG, 실제 API 확인 JSON
- [기존 5주차 안내](docs/week5_readme.md): 이전 구현의 상세 설명

화면 PNG는 가짜 응답을 주입한 Flutter Widget 렌더링 결과이며, 실기기 녹화나 실제 TMDB 포스터 조회 증거는 아닙니다. 실제 기기 영상과 PR URL은 제출 전에 추가합니다. GitHub 원격 반영과 UMC 사이트 제출은 수행하지 않았습니다.

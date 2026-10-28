# MovieLog · 5주차 TMDB / MVVM / Provider

4주차 `feature/week-4`의 `c3cc9f9`를 기준으로 수정했습니다. 기존 시작·회원가입·프로필·하단 탭 UI를 유지하고, 영화 홈·목록·상세를 TMDB 데이터로 연결했습니다.

## 실행

프로젝트 루트(`pubspec.yaml` 위치)에서 실행합니다.

```bash
cp .env.example .env
```

`.env`를 열어 `TMDB_ACCESS_TOKEN=` 뒤에 본인의 **API Read Access Token**을 넣습니다. TMDB 계정의 설정 → API에서 발급받는 긴 토큰입니다. 짧은 API Key와 다릅니다. 토큰 앞에 `Bearer`를 붙이지 않습니다.

```dotenv
TMDB_ACCESS_TOKEN=본인의_READ_ACCESS_TOKEN
```

```bash
flutter pub get
flutter run
```

`.env`를 수정했다면 앱을 완전히 종료하고 다시 실행합니다. 토큰이 비어 있으면 앱은 열리지만 영화 화면에서 설정 안내가 나타납니다. `.env`는 Git에서 제외되며 `.env.example`에는 실제 값이 없습니다. 앱 asset에 담긴 값은 배포 앱의 완전한 비밀 보관 방법이 아닙니다.

## 구현 내용

- **Guided**: Popular 첫 페이지에서 `take(5)`. 0~4개 응답에도 안전합니다. 제목·포스터·평점·ID는 DTO를 사용합니다.
- **Required**: Genre API의 ID/이름으로 Chip 생성, Discover를 page 1부터 순회하며 ID 중복 제거 후 최대 30개, Loading / Empty / Error / Success, 재시도, 요청 중 장르 변경 차단.
- **Required**: 장르 변경 시 기존 30개를 로컬 필터링하지 않고 API에 다시 요청합니다. `전체`는 `with_genres`를 아예 보내지 않습니다.
- **Challenge**: `RefreshIndicator`로 새로고침, 선택 장르 유지, 완료 전 기존 목록 유지, 요청 중 중복 새로고침 차단.
- **Challenge**: BottomSheet에서 장르 다중 선택, 확인 시 ID를 `|`로 연결해 OR 조회. 취소는 적용하지 않습니다.
- **Challenge**: 실패 시 이전 성공 목록 유지, 재시도/취소 Dialog. page 2가 실패해도 부분 결과를 성공 목록으로 교체하지 않습니다. 재시도는 동일한 선택 장르로 page 1부터 다시 실행합니다.
- **포스터**: `poster_path`로 URL 조립, null/빈 경로/다운로드 실패 시 공통 placeholder.
- **상세/평점**: 카드 → `/movies/{TMDB ID}` → 상세 ViewModel → 평점 Dialog → `MovieRatingDraft.movieId`. 배열 index나 기존 mock ID를 사용하지 않습니다.
- **로그**: 개발 모드에서 Method / URL / Query / Headers / Status / Body / Error 기록. Authorization·토큰·API Key는 마스킹하며 release에서는 Interceptor를 등록하지 않습니다.
- **4주차 유지**: 검색·정렬, 장르 저장·복원, 기존 회원가입/프로필. 과거 장르 이름 저장값도 TMDB 장르 ID로 읽습니다.

평점과 즐겨찾기는 기존처럼 해당 상세 화면 안에서만 보관합니다. MovieLog 자체 백엔드에 저장하는 기능은 이번 과제 범위에 포함하지 않았습니다. TMDB 10점 평점과 개인 5점 평점을 화면에서 구분합니다.

## API Client 분리

두 API는 별도 Dio 인스턴스와 Provider 타입을 사용합니다.

| 구분 | TMDB | MovieLog 자체 API |
| --- | --- | --- |
| Client | `TmdbClient` | `MovieLogClient` |
| 주소 | `TmdbConfig.baseUrl` | `.env`의 `MOVIELOG_API_BASE_URL` |
| 인증 | `.env`의 `TMDB_ACCESS_TOKEN` | 로그인으로 받은 자체 API 토큰을 `setAccessToken()`에 전달 |
| 용도 | 영화 원본 정보 조회 | 후속 회원·평점·즐겨찾기 API Service에서 사용 |

`TmdbMovieService`는 `TmdbClient`의 Dio만 사용합니다. 로그인/로그아웃에 따른 MovieLog 토큰 변경은 TMDB 인증값에 영향을 주지 않습니다. 두 Client의 주소·헤더·요청 상태가 독립적인지 자동 테스트로 확인합니다.

MovieLog 서버 주소와 API Contract는 아직 제공되지 않았으므로 실제 회원/평점 요청은 연결하지 않았습니다. 현재 영화 탐색은 TMDB 설정만으로 실행됩니다. 추후 실제 서버 주소를 확인한 뒤 `.env`에 `MOVIELOG_API_BASE_URL`을 입력합니다. 주소 없이 자체 API 요청을 시도하면 설정 오류로 처리합니다.

## 포스터 null / 로드 실패 화면 강제 표시

앱을 실행 중이라면 터미널에서 `q`로 종료하고, 프로젝트 루트에서 아래 명령 중 하나로 새로 실행합니다. 영화 목록을 가져오는 TMDB 토큰 설정은 필요합니다.

포스터 경로를 null로 바꿔 즉시 placeholder 표시:

```bash
flutter run --dart-define=POSTER_TEST_MODE=null
```

잘못된 이미지 경로로 실제 로드 실패 분기를 실행:

```bash
flutter run --dart-define=POSTER_TEST_MODE=error
```

두 모드의 placeholder 모양은 같습니다. null은 이미지 요청 없이 바로 표시하고, error는 이미지 요청이 실패한 뒤 표시합니다. 로드 실패 모드는 잠시 로딩 표시가 나타날 수 있습니다. 이 옵션은 홈·목록·상세의 모든 TMDB 포스터에 적용됩니다.

정상 API 포스터로 돌아가기:

```bash
flutter run
```

모드를 바꿀 때는 앱 실행을 종료한 뒤 명령을 다시 실행합니다. 이 테스트 옵션은 debug에서만 동작하며 release는 실제 API의 포스터 경로를 사용합니다.

## DTO와 null 화면 처리

워크북의 세 DTO는 `lib/data/models/`에 있습니다.

- `tmdb_movie_dto.dart`: `id`, `title`, `overview`, `posterPath`, `backdropPath`, `releaseDate`, `genreIds`, `voteAverage`, `popularity`를 명시적으로 연결합니다. 기존 상세 화면용 `voteCount`, `genres`, `runtime`도 유지합니다.
- `tmdb_movie_page.dart`: 영화 배열과 `page`, `total_pages`, `total_results`를 함께 변환합니다. 유효한 페이지 metadata와 함께 온 null/missing `results`는 빈 목록으로 처리합니다.
- `tmdb_genre_dto.dart`: Genre API에서 받은 `id/name`을 사용합니다.
- 포스터가 null이면 공통 placeholder를 표시합니다.
- 줄거리가 없으면 상세의 줄거리 영역 가운데 `줄거리 정보가 없어요.`를 표시합니다.
- 날짜가 없으면 연도를 표시하지 않으며, 연결용 `·`도 남기지 않습니다.
- 장르 ID가 없으면 빈 목록으로 처리하고, 표시할 장르가 없는 영역은 생략합니다.

## 기존 GitHub 저장소에 반영

현재 결과는 로컬 `feature/week-5` 기준입니다. 연결된 GitHub 앱의 쓰기 요청이 403으로 거절되어 원격 브랜치/PR은 생성하지 못했습니다.

압축 파일은 `.git`과 개인 `.env`를 제외한 전체 프로젝트입니다. 그대로 새 폴더에서 열어 실행할 수 있습니다. 기존 Git 저장소에 반영하려면 압축 속 프로젝트의 파일을 기존 프로젝트에 같은 경로로 복사하고, 기존 `.git` 폴더는 유지합니다. `lib`뿐 아니라 `pubspec.yaml`, `pubspec.lock`, `.gitignore`, `.env.example`, 플랫폼 권한 파일도 함께 반영합니다.

기존 저장소의 터미널에서 아래 명령을 실행합니다. 이미 같은 이름의 로컬 브랜치가 있으면 첫 줄 대신 `git switch feature/week-5`를 사용합니다.

```bash
git switch -c feature/week-5
git add .
git commit -m "feat: 5주차 TMDB MVVM Provider 영화 조회 구현"
git push -u origin feature/week-5
```

PR은 base를 `feature/week-4`, compare를 `feature/week-5`로 지정합니다. 제출 설명은 `docs/week5_submission.md`를 참고합니다.

## 구조

| 위치 | 역할 |
| --- | --- |
| `lib/main.dart` | `.env`를 await로 읽고 앱 실행 |
| `lib/app/movie_log_app.dart` | MaterialApp 위에 두 Client/공용 Service/저장소 Provider 등록 |
| `lib/router/app_router.dart` | Route마다 별도 ChangeNotifierProvider 생성·초기 로드·dispose |
| `lib/core/config`, `lib/core/network` | TMDB와 MovieLog의 개별 Client·설정·인증, TMDB 마스킹 로그 |
| `lib/data/models` | snake_case / null / num 변환, TMDB DTO |
| `lib/data/services/tmdb_movie_service.dart` | HTTP 요청·JSON → DTO 변환만 담당 |
| `lib/data/local/movie_genre_preferences.dart` | 장르 ID 저장과 4주차 저장값 호환 |
| `lib/view_models` | 목록 개수·페이지 순회·장르 조건·화면 상태·요청 수명 관리 |
| `lib/home_screen.dart`, `lib/movies_screen.dart` | Provider 상태 구독과 사용자 입력 전달 |
| `lib/movie_detail_screen.dart`, `lib/movie_rating_input.dart` | 실제 ID로 상세 조회·평점 결과 생성 |
| `test` | DTO, 페이지 합치기, 상태 전이, API 쿼리, 마스킹, Widget 연결 검증 |

이전 `lib/MovieLog_updated/` 폴더는 저장소에 원래 들어 있던 과거 사본이며 실행 진입점이 아닙니다. 앱은 루트의 `lib/main.dart`로 실행합니다. `mock_movies.dart`와 `fake_movie_service.dart`도 기존 학습 기록으로 남기지만 실제 영화 화면에서는 사용하지 않습니다.

## 장르/검색 동작

- 한 Chip을 누르면 해당 장르만 선택합니다. 같은 단일 선택 Chip을 다시 누르거나 `전체`를 누르면 전체 조회합니다.
- 장르 여러 개는 우측 상단 필터 아이콘 → BottomSheet → 확인으로 선택합니다.
- 저장 키: `last_selected_movie_genre_ids`. 과거 `last_selected_movie_genre` 이름 저장값을 읽고 호환값도 함께 저장합니다.
- `/movies?genreIds=28%7C18` 또는 기존 `/movies?genre=드라마`는 저장된 선택보다 우선합니다.
- 검색·정렬은 **현재 API에서 불러온 최대 30개**에만 적용합니다. TMDB 전체 검색 API는 아닙니다.
- 다른 장르 요청에 실패해 이전 목록을 보여주는 경우, 이전 장르 목록이라는 안내를 함께 표시합니다.

## 검증

```bash
flutter analyze
flutter test
```

자동 테스트는 가짜 HTTP 응답과 Service를 주입하므로 개인 토큰이나 실제 TMDB 접속 없이 실행할 수 있습니다. 처음 clone한 환경은 먼저 `cp .env.example .env`를 실행합니다.

2026-10-28 재검증에서 `flutter analyze` 오류·경고 없음과 전체 자동 테스트 42개 통과를 확인했습니다. 제공된 iOS 시뮬레이터 화면에서 실제 API 영화 목록의 `영화 30편`과 정상 포스터 표시도 확인했습니다.

Popular/Genre/Discover의 실제 HTTP status·쿼리 로그, 기기 네트워크 OFF/ON, 앱 재실행 후 장르 복원, 포스터 강제 모드의 실행 영상은 추가 확인이 필요합니다. 자동 테스트의 HTTP 응답은 실제 TMDB 통신 증거가 아닙니다. Guided/Required 항목별 확인 결과와 남은 수동 검증 순서는 [docs/week5_verification.md](docs/week5_verification.md)에 정리했습니다.

제출 기록은 [docs/week5_submission.md](docs/week5_submission.md)에 작성합니다.

## 공식 참고 자료

- [Popular](https://developer.themoviedb.org/reference/movie-popular-list)
- [Discover](https://developer.themoviedb.org/reference/discover-movie)
- [Genre](https://developer.themoviedb.org/reference/genre-movie-list)
- [Image Basics](https://developer.themoviedb.org/docs/image-basics)
- [TMDB 출처 표기](https://developer.themoviedb.org/docs/faq)
- [Dio](https://pub.dev/packages/dio), [Provider](https://pub.dev/packages/provider), [flutter_dotenv](https://pub.dev/packages/flutter_dotenv)
- [RefreshIndicator](https://api.flutter.dev/flutter/material/RefreshIndicator-class.html)

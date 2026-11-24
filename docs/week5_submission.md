# 5주차 미션 기록

이름 / 닉네임: 최한솔 / 솔

기준 코드: `UMC-CAU/umm_11th_pe_mobile_sol`, `feature/week-4`, `c3cc9f9`

작업 브랜치: `feature/week-5`

## 제출 양식

| 항목 | 구현 위치 / 확인 내용 |
| --- | --- |
| PR 링크 | 미생성. GitHub 연결의 쓰기 요청이 403으로 거절됨. 직접 push 후 PR 링크 추가 |
| TMDB Token 비노출 확인 | `.env` Git 제외·미추적, 제공 프로젝트의 `.env` 커밋 기록 없음, 빈 `.env.example`, 로그 마스킹 테스트 통과. 실제 기기 콘솔·제출 영상의 비노출은 추가 확인 필요 |
| Popular 5개 화면 | `MovieHomeViewModel.load()` → `results.take(5)` → HomeScreen. 실제 화면 캡처 추가 필요 |
| Discover 최대 30개 화면과 실제 개수 | `MovieListViewModel.load()`의 페이지 순회와 ID Map으로 최대 30개 구성. 제공된 iOS 시뮬레이터 화면에서 실제 API 영화 정보와 `영화 30편` 확인. 고유 ID 30개 구성은 자동 테스트 통과 |
| Genre API 및 with_genres 요청 증거 | `/genre/movie/list`, `/discover/movie`, 선택 ID의 `|` OR 연결. 자동 HTTP 테스트로 쿼리 확인, 실제 로그/영상 추가 필요 |
| Loading / Empty / Error / Success | 자동 테스트 및 테스트 응답을 주입한 화면 렌더링 검토. 실제 Success는 제공된 시뮬레이터 캡처로 확인. 실제 네트워크 실패·복구 영상 추가 필요 |
| 포스터 null·실패 처리 | `TmdbPoster`의 null 처리, loadingBuilder, errorBuilder |
| movie.id 전달 위치 | 카드 route path/extra → MovieDetailViewModel → MovieRatingInput.movieId → MovieRatingDraft.movieId |
| 트러블슈팅 | 아래 기록 참고 |
| 미검증 항목 | Popular 홈 화면·실제 Status/쿼리 로그, 장르 변경 전후 요청 영상, 포스터 강제 모드의 기기 화면, 네트워크 OFF/ON 영상, 장르 저장 기기 재실행, Android/iOS 실기기 실행 |

## 자동 검증 및 화면 검토

- 2026-10-28 Flutter 정적 분석 재실행: `No issues found!`.
- 2026-10-28 전체 자동 테스트 재실행: 42개 통과(DTO / Service / ViewModel / Widget, API Client 분리 포함).
- 이전 버전의 release Web 빌드 성공 및 로그 제거를 확인했으며, 이번 DTO 보완에서는 정적 분석과 자동 테스트로 검증.
- Android INTERNET 권한과 macOS Debug/Release 네트워크 권한 XML 확인.
- 393×852 화면에서 홈·목록·장르 BottomSheet·오류 Dialog·상세 배치를 테스트 데이터로 렌더링해 검토.
- 위 화면 검토는 테스트 데이터이며, 실제 TMDB 응답 캡처/실기기 검증을 대신하지 않음.
- 제공된 실제 iOS 시뮬레이터 캡처에서 Discover 목록의 `영화 30편`, 제목·장르·평점·정상 포스터 확인.
- Client 분리와 Guided/Required 항목별 검증 상태: [week5_verification.md](week5_verification.md). 전체 수동 검증 완료 표시는 남은 기기 확인 후 적용.

## 직접 확인할 순서

1. `.env`에 본인 Read Access Token 입력 → `flutter pub get` → 앱 실행.
2. 기존 회원가입 화면에서 로그인 버튼으로 홈 이동 → Popular 최대 5개 확인. 콘솔의 Status 200과 마스킹 확인.
3. 영화 탭에서 API 응답에 따른 실제 영화 수(최대 30)와 제목·포스터 확인.
4. 장르 Chip 변경 → 콘솔에 page 1부터 새 Discover 요청과 with_genres 확인. 전체에서는 파라미터가 없어야 함.
5. 필터 BottomSheet에서 2개 장르 확인 → `with_genres=ID|ID` 요청과 결과 확인. 취소는 요청을 보내지 않아야 함.
6. 새로고침 중 기존 목록 유지와 장르 버튼 비활성화 확인.
7. 네트워크 OFF 후 새로고침 → 기존 목록 유지와 재시도/취소 Dialog 확인. 취소 후에도 목록 유지 확인.
8. 네트워크 ON → 재시도 → page 1부터 같은 장르로 다시 요청, 최신 목록 교체 확인.
9. 카드로 상세 진입 → 평점 남기기 → 저장. DTO ID가 Dialog에 전달되는 위치를 코드에서 확인.
10. 상세 주소 직접 실행 시 extra 없이도 숫자 ID로 재조회 확인. 앱 종료/재실행 후 장르 복원 확인.
11. 녹화·스크린샷에 토큰과 `.env` 원문이 들어가지 않았는지 확인.

## 트러블슈팅 기록

### 두 번째 페이지 요청이 실패하는 경우

- 상황/재현: 첫 페이지는 성공하고 두 번째 Discover 요청이 실패하도록 Service 테스트 응답 구성.
- 기대 결과: 이전에 성공한 완성 목록을 유지하고 같은 장르로 전체 로딩 재시도.
- 원인: 페이지를 받을 때마다 화면 목록을 갱신하면 부분 목록이 성공처럼 보일 수 있음.
- 수정: 요청 내부의 ID Map에 먼저 합친 후, 전체 루프가 성공한 경우에만 화면 목록/최근 성공 스냅샷 교체.
- 재검증: 자동 테스트에서 기존 목록 보존, 실패 상태, 재시도의 page 1 재시작과 같은 장르 조건 확인.

### 상세 주소에서 Mock 영화를 찾던 기존 동작

- 상황: 기존 코드의 상세 fallback은 `findMovieById`로 Mock ID만 조회.
- 문제: TMDB 숫자 ID로 전환하면 새로고침/직접 주소 실행 시 extra가 없을 때 영화를 찾지 못함.
- 수정: 별도 상세 ViewModel에서 `/movie/{TMDB ID}` 재조회. extra가 전달되어도 경로 ID와 일치할 때만 초기 화면에 사용.
- 재검증: extra 없는 `/movies/98765` Widget 테스트에서 해당 숫자 ID로 Service 조회 확인.

### 요청 실패 로그와 토큰 마스킹

- 자동 검증: 테스트용 HTTP adapter가 401을 반환하도록 구성하여 URL·Status·오류 로그와 마스킹 확인.
- 실제 TMDB 오류 로그: **미검증**. 개인 토큰/기기 환경에서 실패 재현 후 마스킹된 로그를 여기에 붙여넣기.
- 주의: 테스트용 401 로그를 실제 서버/기기 검증 결과로 제출하지 않기.

## 학습 회고

View는 상태를 읽고 입력을 전달한다. ViewModel은 해당 화면의 상태, 개수 제한, 페이지 합치기, 장르 조건을 관리한다. Service는 HTTP 요청과 DTO 변환만 담당한다. 공용 Service는 앱 최상단 Provider에서 공유하고, 각 Route의 ViewModel은 화면 수명에 맞춰 생성/폐기한다. notifyListeners를 호출하면 Consumer가 구독한 영역이 갱신된다.

## 워크북 DTO 세부 기준 보완

- DTO 경로를 `lib/data/models/`로 맞추고 페이지 DTO 파일명을 `tmdb_movie_page.dart`로 변경.
- 영화 DTO에 `backdropPath`, `popularity`를 추가하고 snake_case key 및 num → double 변환 연결.
- `overview`가 null/빈 값이면 `줄거리 정보가 없어요.`를 줄거리 영역 가운데 표시.
- `release_date`가 null/빈 값이면 연도와 불필요한 구분자를 생략.
- null `genre_ids`는 빈 목록으로 처리. Genre API의 ID/이름 사용 유지.
- 유효한 페이지 metadata가 있는 null `results`는 빈 목록으로 변환.
- 기존 상세 조회에 필요한 추가 필드와 잘못된 응답 검증은 유지.

## API Client 분리와 포스터 재현 모드

- `TmdbClient`와 `MovieLogClient`를 별도 Provider 타입과 Dio 인스턴스로 등록.
- MovieLog 자체 API 토큰의 설정/해제가 TMDB Authorization에 영향을 주지 않도록 분리.
- 두 Client의 실제 테스트용 HTTP 요청에서 주소와 인증값이 섞이지 않는지 검증.
- 자체 API 서버 주소와 API Contract는 미제공 상태여서 회원/평점 서버 연동은 미검증.
- `flutter run --dart-define=POSTER_TEST_MODE=null`로 포스터 null 재현.
- `flutter run --dart-define=POSTER_TEST_MODE=error`로 이미지 요청 실패 재현.
- `flutter run`으로 정상 포스터 모드 복귀. 두 강제 모드는 debug에서만 적용.

## 포스터 null·로드 실패 트러블슈팅 기록

**상황과 재현 순서:**
영화 목록의 포스터 대체 화면을 의도적으로 확인한다. 실행 중인 앱을 `q`로 종료한 뒤 `flutter run --dart-define=POSTER_TEST_MODE=null`로 null 모드를 실행한다. 다시 종료하고 `flutter run --dart-define=POSTER_TEST_MODE=error`로 이미지 요청 실패 모드를 실행한다. 옵션 없이 `flutter run`을 실행하면 정상 모드로 돌아간다.

**호출 API:**
영화 목록 화면의 API는 Discover(`/discover/movie`)이다. 이번 실패 재현 대상은 영화 목록 JSON이 아니라 별도 TMDB 포스터 이미지 요청이다.

**Query parameter(Token 제외):**
영화 목록 전체 조건의 설정값은 `language=ko-KR`, `page=1`, `include_adult=false`, `sort_by=popularity.desc`이며 `with_genres`는 생략한다. 포스터 이미지 요청에는 Query parameter가 없다.

**기대한 상태와 결과 개수:**
영화 API가 성공했다면 목록 상태와 결과 개수(최대 30개)를 유지하면서 포스터 영역만 placeholder로 표시한다. null 모드는 즉시, error 모드는 이미지 요청 실패 후 표시한다.

**실제 status / 응답 모양:**
테스트용 잘못된 이미지 URL `https://image.tmdb.org/t/p/w500/__movielog_debug_missing_poster__.jpg`를 실제 HTTP GET으로 확인한 결과 `404`, `Content-Type: text/html`, `File Not Found` 페이지가 반환되었다. 별도의 Flutter Widget 테스트에서는 가짜 HTTP 400 응답으로 대체 화면을 검증했다. 실제 API를 연결한 iOS 시뮬레이터 화면에서는 정상 영화 정보와 `영화 30편`을 확인했다. 해당 화면만으로 Discover의 HTTP status나 응답 JSON 전체를 확인한 것은 아니다.

**ViewModel 상태:**
자동 테스트에서 `MovieLoadStatus.success`와 테스트 영화 2개를 유지했다. 포스터 오류는 이미지 Widget이 처리하며 목록 ViewModel을 Error로 바꾸지 않는다.

**원인:**
`poster_path`가 없거나, 이미지 파일이 존재하지 않는 경로로 요청하면 포스터를 표시할 수 없다.

**수정:**
null·빈 경로는 공통 placeholder로 처리하고, 이미지 요청 실패는 `errorBuilder`에서 동일한 placeholder로 처리한다. 개발 모드에서만 재현할 수 있도록 `POSTER_TEST_MODE` 실행 옵션을 추가했다.

**재검증:**
전체 자동 테스트 42개 및 null/error 실행 옵션을 적용한 별도 포스터 테스트로 분기와 목록 상태 유지를 검증했다. 실제 API의 정상 영화 목록과 포스터 표시는 제공된 iOS 시뮬레이터 캡처로 확인했다. null/error 모드의 실제 기기 화면 녹화와 실패 중 목록 유지 확인은 추가로 필요하다.

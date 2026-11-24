# 5주차 Client 분리 및 Guided/Required 검증

확인일: 2026-10-28

검증한 앱 코드: `2f95829` (`feature/week-5`). 이번 변경은 검증 기록 보완이며 앱 코드 변경은 없다.

## 체크 결과

- [x] TMDB와 MovieLog 자체 API의 Client를 분리했다.
- [x] 현재 프로젝트에서 `flutter analyze`를 실행하여 `No issues found!`를 확인했다.
- [x] 전체 자동 테스트 42개가 통과했다.
- [x] Guided/Required의 구현 위치와 검증 결과를 항목별로 대조했다.
- [x] 제공된 iOS 시뮬레이터 화면에서 실제 API 영화 목록의 `영화 30편`, 장르 Chip, 제목·평점·정상 포스터 표시를 확인했다.
- [ ] 실제 API를 사용하는 Guided/Required 수동 검증 전체 완료. 아래에 남은 확인을 표시했다.

## API Client 분리

| 구분 | TMDB | MovieLog 자체 API |
| --- | --- | --- |
| Client | `lib/core/network/tmdb_client.dart`의 `TmdbClient` | `lib/core/network/movie_log_client.dart`의 `MovieLogClient` |
| Dio | TMDB 전용 인스턴스 | 별도 인스턴스 |
| Provider | `Provider<TmdbClient>` | `Provider<MovieLogClient>` |
| 서버 주소 | `https://api.themoviedb.org/3` | `.env`의 `MOVIELOG_API_BASE_URL` |
| 인증 | `.env`의 `TMDB_ACCESS_TOKEN` | 자체 API 로그인 토큰을 `setAccessToken()`으로 설정·해제 |
| 사용 | `TmdbMovieService`의 영화·장르 조회 | 자체 API Service를 연결할 때 사용 |

`test/api_client_separation_test.dart`의 4개 테스트와 Provider Widget 테스트에서 다음을 확인했다.

- 두 Client의 요청 주소와 인증값이 서로 섞이지 않는다.
- MovieLog 토큰이 없으면 TMDB 토큰을 대신 사용하지 않는다.
- MovieLog 로그인·로그아웃으로 헤더를 바꿔도 TMDB 헤더는 유지된다.
- 자체 API 주소가 없으면 HTTP 요청 전에 설정 오류로 끝난다.
- 앱에서 두 Provider를 각각 조회할 수 있다.

MovieLog 서버 주소와 API 명세는 제공되지 않아 실제 회원·평점·즐겨찾기 서버 호출은 연결하지 않았다. 현재 영화 탐색에는 `MOVIELOG_API_BASE_URL`을 비워 두어도 된다. Client 분리 완료와 실제 자체 API 연동 완료는 구분한다.

## 실행한 검증

```bash
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
```

- 정적 분석: `No issues found!`.
- 전체 테스트: `+42: All tests passed!`.
- 별도 임시 화면 검토: 가짜 Service 응답을 주입한 393×852 화면에서 Loading, Empty, Error, 재시도 후 Success, 장르 선택 상태를 렌더링해 검토했다. 이 화면 검토는 실제 TMDB 통신이나 기기 조작 결과가 아니다.
- 실제 API 연결 결과: 사용자가 제공한 iOS 시뮬레이터 캡처에서 목록 개수 30과 정상 영화 정보를 확인했다. 화면만으로 HTTP status, 응답 JSON 전체, ID 30개의 중복 여부를 판정하지 않았다. 중복 제거는 자동 테스트로 확인했다.

## Guided Practice 대조

| 항목 | 코드·자동 검증 결과 | 실제 실행에서 남은 확인 |
| --- | --- | --- |
| `.env` 로드와 Popular 첫 호출 | `main.dart`에서 로드 후 시작, Service의 `/movie/popular`, 토큰 마스킹 테스트 통과 | Popular의 실제 Status 200과 Authorization 마스킹 로그 |
| DTO 변환과 인기 최대 5개 | `MovieHomeViewModel`의 `results.take(5)`. 5개 및 2개 응답 테스트 통과 | 홈 인기 영화 목록 캡처 |
| Loading → Success/Error 연결 | ViewModel 상태 전이·재시도 테스트와 Consumer 연결 확인 | 실제 Popular 로딩·실패·재시도 영상 |
| 실제 제목·포스터 표시와 대체 화면 | Discover 실제 포스터는 제공 화면으로 확인. null·로드 실패 Widget 테스트 통과 | 홈 화면 및 강제 포스터 모드의 기기 화면 |
| 빌드마다 요청 반복 방지 | Route의 ViewModel 생성 시 최초 load, HomeScreen.build에서 요청하지 않음을 코드로 확인 | 홈을 다시 그릴 때 Popular 요청 횟수 로그 |
| 카드 ID를 평점 movieId로 전달 | 숫자 상세 경로 → Dialog → `MovieRatingDraft.movieId` Widget 테스트 통과 | 실제 상세·평점 Dialog 조작 화면 |

## Required Mission 대조

| 번호 | 항목 | 코드·자동 검증 결과 | 실제 실행에서 남은 확인 |
| --- | --- | --- | --- |
| 1 | Genre API로 Chip 구성 | Genre DTO의 id/name 사용, Service·Widget 테스트 통과. 제공 화면에서 Chip 표시 확인 | `/genre/movie/list` 실제 요청 로그 |
| 2 | Discover page 1부터 요청 | ViewModel의 page 1 시작과 페이지 순회 테스트 통과 | 실제 page별 요청 로그 |
| 3 | ID 중복 제거·최대 30개 | 페이지 크기·중복이 섞인 응답에서 고유 ID 30개 테스트 통과. 실제 화면의 `영화 30편` 확인 | 필요 시 실제 응답의 ID 목록 대조 |
| 4 | Loading / Empty / Error / Success | 상태 테스트 통과. 테스트 응답으로 각 화면 렌더링 검토. 실제 Success 화면 확인 | 실제 네트워크 실패·복구 영상 |
| 5 | 장르 선택 시 with_genres로 page 1 재요청 | Service 쿼리·ViewModel·Chip 조작 검증 통과 | 실제 장르 변경 전후 요청과 결과 영상 |
| 6 | 전체는 with_genres 생략 | 빈 선택의 파라미터 생략 테스트 통과 | 전체 선택의 실제 요청 로그 |
| 7 | Discover 요청 중 장르 변경 차단 | ChoiceChip 비활성화·ViewModel 차단 테스트 통과 | 느린 요청 중 Chip과 필터 버튼 조작 확인 |
| 8 | 상세·평점 Dialog에 DTO.id 전달 | `/movies/98765` 상세 조회, Dialog.movieId, 저장 Draft.movieId 테스트 통과 | 실제 상세·평점 Dialog 조작 화면 |

## 기기에서 마무리할 순서

1. `flutter run`으로 실행하고 홈의 인기 영화 최대 5개를 확인한다. 콘솔에서 Popular Status와 Authorization 마스킹을 확인한다.
2. 영화 탭에서 장르를 선택하고 Discover 요청이 `page=1`부터 다시 시작하며 `with_genres`에 선택 ID가 들어가는지 확인한다. 전체를 선택하면 키 자체가 없어야 한다.
3. 요청 중 장르 Chip과 필터 버튼이 비활성화되는지 확인한다.
4. 인터넷 연결을 끊고 새로고침한다. 이전 목록 유지, 재시도·취소 Dialog를 확인한다. 연결을 복구하고 같은 장르로 재시도해 성공 목록으로 교체되는지 확인한다.
5. 실행을 종료하고 아래 두 명령을 각각 실행해 대체 포스터 화면을 촬영한다. 모드를 바꿀 때마다 종료 후 다시 실행한다. 두 모드의 최종 placeholder 모양은 같다.

   ```bash
   flutter run --dart-define=POSTER_TEST_MODE=null
   flutter run --dart-define=POSTER_TEST_MODE=error
   ```

6. 옵션 없이 `flutter run`으로 복귀한 뒤 카드 → 상세 → 평점 남기기 → 저장을 조작한다. ID 전달은 위 자동 테스트와 코드 위치를 증거로 사용한다.
7. 앱을 종료·재실행해 선택 장르 복원을 확인하고, 제출할 로그·화면·영상에서 토큰 원문이 보이지 않는지 확인한다.

Empty 화면은 빈 API `results`를 주입해 검토했다. 일반 영화 검색에서 검색 결과가 없는 화면과 API 결과 자체가 빈 상태는 구분한다.

위 기록만으로 최종 체크리스트의 “Guided/Required 수동 검증 전체 완료”를 체크하지 않는다. 남은 기기 확인 결과와 증거를 확보한 뒤 완료로 바꾼다.

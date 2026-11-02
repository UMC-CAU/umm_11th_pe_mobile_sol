# 6주차 검증 기록

기준 자료: 사용자가 제공한 노션 링크와 첨부 과제 전문 `붙여넣은 텍스트(1)(6).txt`.
노션 링크는 직접 조회되지 않아 첨부 전문의 Guided / Required / Challenge를 기준으로 구현했습니다. 이미지 원본은 첨부 전문에 포함되지 않아 기존 2·3주차 앱의 색상·레이아웃을 확장했습니다.

## 자동 검증

환경: Flutter 3.47.9 / Dart 3.13.7, Linux. 기존 의존성 잠금 파일을 유지했습니다.

| 항목 | 검증 방법 | 결과 |
| --- | --- | --- |
| 정적 분석 | `flutter analyze --no-pub` | 오류·경고·정보 없음 |
| 기존·신규 회귀 테스트 | `flutter test --no-pub` | 69개 통과 |
| v5 JSON Wrapper 미사용 | bare object / bare array / 잘못된 Wrapper 테스트 | 통과 |
| nullable comment·시간 변환 | DTO 테스트 | 통과 |
| 닉네임·이메일 인코딩 | 한글·슬래시·#·?·+가 포함된 path segment | 통과 |
| 필드별 독립 요청 상태 | 두 요청을 동시에 시작해 따로 완료 | 통과 |
| 중복 값 재입력 | trim 적용 후 기존 중복 문자열 복원, 요청 횟수 확인 | 통과 |
| 입력 변경 시 무효화 | 사용 가능 결과 제거, A→B→A 중 늦은 응답 무시 | 통과 |
| 통신 오류와 중복 구분 | 오류 문구·재시도 가능 여부 비교 | 통과 |
| Form 서버 에러 | `forceErrorText` + `InputDecoration.errorText`, Form 검증 | 통과 |
| 중복 확인 중 버튼 | onPressed null, Text 생략, 인디케이터만 표시 | 통과 |
| 버튼 너비 | null / infinity / 96, 전역 버튼 테마와 함께 측정 | 통과 |
| 작은 화면·키보드 | 너비 320px + 키보드 하단 여백 300px, 스크롤·에러 | 통과 |
| 제출 버튼 | 양쪽 중복 확인 + 비밀번호·약관, 홈 이동 | 통과 |
| 평점의 상태 전환 | Loading→Error→재시도→Empty→Success | 통과 |
| 평점 화면 라우팅 | 마이페이지 push, 하단 탭 없음, 뒤로가기 복귀 | 통과 |
| TMDB 캐시 | 동일 ID 중복 요청 방지, 성공·404 캐시 | 통과 |
| TMDB 일시적 실패 | 평점 보존, 같은 로딩에서 ID당 한 번, 다음 로딩 재시도 | 통과 |
| 늦은 응답·화면 종료 | 새 요청 이후 이전 결과·화면 종료 후 알림 무시 | 통과 |

세부 테스트: `test/week6_services_test.dart`, `test/sign_up_view_model_test.dart`, `test/my_ratings_view_model_test.dart`, `test/week6_widget_test.dart`. 이전 5주차의 42개 테스트도 포함합니다.

## 실제 v5 HTTP 검증

`tool/week6_live_check.dart`가 **실제 MemberCheckService / RatingApiService**를 호출합니다. GET 요청만 보내며 회원·평점을 생성하거나 수정하지 않습니다. 현재 응답과 시각은 `evidence/live-api-checks.json`에서 확인합니다.

| 요청 | 확인 결과 |
| --- | --- |
| `GET /v5/members/nickname/{nickname}` | 200, `{available: true}` 형태의 본문 파싱 |
| `GET /v5/members/email/{email}` | 200, 이메일 path 인코딩과 본문 파싱 |
| `GET /v5/members/1/ratings` | 200, 평점 배열과 null comment 파싱 |
| `GET /v5/members/not-a-number/ratings` | 400, 프레임워크 오류 응답 |
| `GET /v5/members/999999999/ratings` | 404, 없는 회원 오류 응답 |

공개 학습용 데이터이므로 평점 개수와 내용은 다른 학습자의 사용에 따라 바뀔 수 있습니다. Empty, 통신 장애, 중복 여부의 고정 재현은 가짜 응답을 이용해 검증했습니다.

## 화면 예시

`evidence/01`~`09` PNG는 실제 Flutter Widget을 렌더링한 393×852 화면(2배 해상도)입니다. 상단 DEMO DATA 표시는 가짜 응답을 사용했다는 뜻입니다. `tool/capture_week6_test.dart`로 생성하며, 외부 한글 폰트를 `CAPTURE_FONT`에 지정합니다. 개인 토큰을 사용하지 않았고 실제 TMDB 포스터 다운로드는 검증하지 않았습니다.

## 제출 전에 직접 추가할 기록

- 개인 TMDB Read Access Token으로 일반 앱을 실행해 실제 영화 제목·포스터를 확인합니다.
- 닉네임·이메일 확인 전→통신 중→가능/중복과 입력 변경·동일 중복 값 복원 과정을 기기에서 녹화합니다.
- 마이페이지 진입→평점 목록→뒤로가기와 기기의 네트워크 OFF/ON 후 재시도를 녹화합니다.
- 버튼 너비 비교 데모를 확인합니다.
- GitHub에 반영해 PR 링크를 기입하고, 본인의 회고를 확인한 뒤 UMC에 노션 미션 페이지를 제출합니다.

위 기기 녹화·원격 PR 생성·최종 제출은 완료로 표시하지 않았습니다.

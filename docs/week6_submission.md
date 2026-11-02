# 6주차 제출 초안

아래 내용은 코드 구현과 자동 검증을 바탕으로 작성한 초안입니다. PR 링크·기기 영상 링크와 실제 학습 소감은 제출 전에 보완합니다.

## PR 제목

feat: 6주차 닉네임·이메일 중복 확인 및 내 평점 조회 구현

## PR 본문

회원가입 폼에서 닉네임·이메일을 v5 API로 확인하고, 마이페이지에서 학습용 회원 1의 공개 평점을 조회할 수 있습니다. 입력이 변경되면 확인 결과가 무효화되며, 마지막 중복 값을 다시 입력하면 재요청 없이 에러 상태를 복원합니다.

### 변경 사항

- 공용 `MovieLogButton`: 기본·통신 중·비활성 상태 및 세 가지 너비
- `CheckResult`, `RatingDto`, `RatingWithMovie`와 상태 없는 API Service
- `SignUpViewModel`: 필드별 상태·요청 버전·중복 값 기억, 통신 오류 구분
- 서버 에러를 `TextFormField`와 Form 검증에 연결
- `MyRatingsViewModel`: Loading / Empty / Error / Success, 영화 정보 캐시와 부분 실패 처리
- `/my/ratings`: root Navigator를 사용해 하단 탭을 가리는 평점 자식 화면
- TMDB와 MovieLog의 별도 Dio 유지, v5 공통 Wrapper 없는 응답 파싱
- 토큰 없이 상태를 재현하는 별도 녹화용 데모 진입점

### 검증

- `flutter analyze`: No issues found
- `flutter test`: 기존 42개 + 신규 27개, 총 69개 통과
- 실제 서비스 구현으로 v5 닉네임·이메일·회원 1 평점 GET 및 400/404 응답 확인
- 320px 화면과 키보드 표시, 중복·통신 중·오류·재시도, 화면 이동·복귀를 Widget 테스트로 확인
- `docs/evidence`의 PNG는 가짜 응답으로 렌더링한 예시이며 실기기 녹화와 구분

### 범위

실제 회원가입 POST, 로그인, 평점 CRUD는 호출하지 않습니다. 가입하기는 양쪽 중복 확인과 로컬 검증 후 홈으로 이동합니다. 평점 조회 대상은 로그인 사용자가 아닌 `sampleMemberId = 1`입니다.

## 제출 양식

```text
이름 / 닉네임: 최한솔 / 솔
PR 링크: [GitHub 반영 후 입력]
확인 전/통신 중/가능/중복 화면: docs/evidence/01~04 (데모 렌더링 예시), 기기 녹화 링크 추가
입력 변경 시 무효화 화면 또는 영상: [기기 영상 링크 추가]
동일 문자열 재입력 시 즉시 에러 화면 또는 영상: [기기 영상 링크 추가]
MovieLogButton 너비 비교 화면(null / double.infinity / 고정값): docs/evidence/09-button-widths.png
내가 등록한 평점(memberId 1) Loading/Empty/Error/Success 화면: docs/evidence/05~08 (데모 렌더링 예시)
트러블슈팅: 아래 기록 참고
6주차 회고: 아래 초안을 실제 학습 내용에 맞게 보완
```

## 구현 과정

1. 5주차 프로젝트의 라우터, Provider 등록, 회원가입 폼, 영화 상세 조회 Service를 확인했습니다.
2. v5의 성공 응답이 직접 객체/배열이라는 점에 맞춰 DTO와 조회 Service를 추가했습니다.
3. 공용 버튼을 만들고 입력창과 8px 간격의 별도 형제로 배치했습니다.
4. 닉네임·이메일에 각각 상태와 요청 버전을 두어 동시 요청·입력 변경을 처리했습니다.
5. 마이페이지에 진입 행을 추가하고 평점 화면을 root Navigator 위에 연결했습니다.
6. 평점 DTO와 TMDB 영화를 묶고, 영화 조회 실패 시 평점은 보존하도록 했습니다.
7. 상태 전환·재입력·오류·레이아웃·라우팅 테스트와 실제 v5 GET 검증을 수행했습니다.

## 트러블슈팅

### 이슈 1 — 전역 버튼 테마와 내용 너비 버튼

**이슈**: 기존 앱의 ElevatedButton 테마는 최소 너비가 `double.infinity`여서 입력창 옆의 내용 너비 버튼과 충돌할 수 있었습니다.

**문제**: 공용 버튼의 `width`만 null로 두어도 내부 버튼이 전역 최소 너비를 상속합니다.

**해결**: `MovieLogButton`에서 `minimumSize: Size(0, 44)`로 덮어쓰고, 바깥 `SizedBox`가 너비를 정하도록 했습니다.

**검증**: 전역 최소 너비가 infinity인 테마에서도 null / infinity / 96의 실제 렌더 너비를 테스트했습니다.

### 이슈 2 — 화면 에러 표시와 Form 검증

**이슈**: 서버 중복 결과를 decoration의 `errorText`에만 전달하면 로컬 validator가 null을 반환하는 경우 Form 검증과 화면 표시가 어긋날 수 있습니다.

**문제**: API의 중복 여부는 기존 로컬 형식 validator가 알지 못합니다.

**해결**: `forceErrorText`와 `InputDecoration.errorText`에 서버 메시지를 연결하고 제출 조건에도 양쪽 확인 완료를 포함했습니다.

**검증**: 중복 응답 후 에러 문구, 비활성 버튼, `Form.validate() == false`를 함께 확인했습니다.

### 이슈 3 — 입력 변경 후 늦게 도착한 응답

**이슈**: A 입력으로 요청한 뒤 B→A로 바꾸면 입력 문자열만 비교해서는 과거 응답을 구분할 수 없습니다.

**문제**: 현재 문자열은 같아도 요청 시점의 입력 상태와는 다릅니다.

**해결**: 닉네임·이메일 각각 요청 버전을 올리고, 결과를 적용하기 전에 버전과 dispose 여부를 확인합니다.

**검증**: A→B→A에서 과거 성공 결과가 적용되지 않으며, 화면 종료 후 알림이 발생하지 않는 것을 확인했습니다.

### 이슈 4 — 영화 상세 실패와 평점 데이터 보존

**이슈**: TMDB 실패를 전체 조회 실패로 처리하면 자체 백엔드에서 정상 조회한 평점까지 보이지 않습니다.

**문제**: 평점의 주인인 MovieLog 데이터와 부가 정보인 TMDB 데이터를 하나의 성공/실패로 묶는 구조입니다.

**해결**: 평점은 유지하고 영화 제목·포스터만 대체 표시합니다. 확정적인 404만 null로 캐시하고 일시적 실패는 다음 로딩에서 재시도합니다.

**검증**: 404와 일시적 실패 모두 평점이 남고, 같은 로딩에서는 ID당 한 번만 조회하는 것을 확인했습니다.

## 6주차 회고 초안

중복 확인은 단순한 true/false 처리보다 입력 변경, 통신 중, 통신 실패를 나누는 것이 중요하다는 점을 정리했습니다. ViewModel에서 상태를 관리하고 View가 같은 상태를 버튼과 입력창에 전달하면 표시와 동작을 일관되게 유지할 수 있습니다. 평점과 영화 정보를 구분해 부가 정보 조회가 실패해도 핵심 기록은 유지하도록 구현했습니다.

직접 실행하며 새로 이해한 점과 어려웠던 부분: [본인의 경험 추가]

## 참고

- https://api.flutter.dev/flutter/material/TextFormField-class.html
- https://api.flutter.dev/flutter/widgets/FormField/forceErrorText.html
- https://pub.dev/packages/dio
- https://pub.dev/packages/provider

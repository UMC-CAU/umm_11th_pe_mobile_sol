# MovieLog 8주차 실행 및 확인 안내

기준 코드: GitHub `UMC-CAU/umm_11th_pe_mobile_sol`의 `feature/week-7`, 커밋 `2397478`.
로컬에서 별도로 수정한 내용은 포함되어 있지 않을 수 있습니다.

## 실행 방법

1. 프로젝트 폴더에서 `.env.example`을 `.env`로 복사하고 기존 TMDB API Read Access Token을 입력합니다.
2. MovieLog 기본 서버는 UMC 워크북 서버입니다. 다른 서버는 `MOVIELOG_API_BASE_URL`을 변경하세요.
3. 아래 명령어를 실행합니다.

```bash
flutter pub get
flutter analyze
flutter test
open -a Simulator
flutter run -d ios
```

로그인, 앱 재시작 복원, 닉네임 수정과 중복 오류, 평점 등록·수정·삭제, 만료와 로그아웃을 직접 확인해야 합니다. 실제 기기 보안 저장소 동작은 검증하지 않았습니다. 토큰과 비밀번호는 기록이나 캡처에 노출하지 마세요.

## API 제한

현재 워크북 v7 로그인과 내 정보 응답에는 memberId가 없고, 토큰 기반 전체 내 평점 조회 API도 명시되어 있지 않습니다. 마이페이지 평점 화면은 현재 앱 세션에서 등록한 평점만 보여주며, 앱 재시작 후 이전에 등록한 전체 평점을 복원하지 않습니다. 서버의 기존 평점이 삭제되는 것은 아닙니다.

Flutter 앱 실행, 테스트 및 서버와 실제 기기 연동은 이 환경에서 검증하지 못했습니다. 확인하지 않은 결과를 통과로 기록하지 마세요.

# Tasks

## 1. Release handoff
- [x] 1.1 원자적인 릴리즈 요청·catch-up·dry-run·중복 억제를 구현하고 Python 회귀 테스트로 검증한다.
- [x] 1.2 helper 작업 기준 문서와 대상 엔진 검사 진입점을 작성하고 CLI/문서 경로를 검증한다.

## 2. Runtime execution
- [x] 2.1 `_ops` admission·Slack readback·정책 상속·단회 fallback·취소·결과 검증을 구현하고 focused tests 및 build로 확인한다.
- [x] 2.2 daemon 시작·종료와 worker 경계를 연결하고 registry 검사 및 운영 문서를 검증한다.

## 3. Delivery
- [x] 3.1 요청 변경만 commit/push하고 안전한 운영 배포·launchd 설정을 실제 재조회한다.
- [x] 3.2 1.14.1 catch-up의 durable 작업·실제 모델·프로젝트 채널 결과·호환 검증 근거를 확인한다.
- [x] 3.3 OpenSpec strict 검증과 최종 Git 상태를 확인하고 완료 근거를 기록한다.

## Workflow follow-up
- 완료 후 명세를 archive하고 기록을 commit/push한다.

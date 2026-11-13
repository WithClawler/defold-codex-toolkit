# Proposal

## Why

현재 주간 모니터는 새 엔진을 알리기만 하며 helper 영향 분석·수정·검증을 시작하지 않는다. 감지 결과를 지속 가능한 `_ops` 작업 큐와 연결해 사용자가 매번 재요청하지 않아도 helper 호환 작업과 프로젝트 채널 보고까지 진행한다.

## What Changes

- 새 stable 릴리즈를 원자적인 로컬 요청 파일로 기록하고 `_ops`가 프로젝트 채널에 작업 스레드를 생성한다.
- 중앙 자동화 모델 기본값을 상속한 worker가 기준 문서의 helper 수정·검증·호환 태그·결과 기록까지 수행한다.
- 릴리즈별 중복 억제, 불확실한 게시·등록 복구, 작업 중복 방지, 단회 fallback, 취소 보존을 적용한다.
- 이미 감지한 미처리 릴리즈는 명시적인 catch-up 실행으로 연결한다. 소비 게임은 영향 조사만 수행한다.

## Capabilities

### New Capabilities
- `engine-release-automation`: 엔진 릴리즈 감지부터 helper 호환 작업·검증·스레드 보고까지의 지속 가능한 실행 계약.

### Modified Capabilities

없음. 기존 `engine-compatibility`의 실제 엔진 검증 및 범위 구분을 재사용한다.

## Impact

이 저장소의 릴리즈 감지 스크립트, 운영 문서, 테스트와 `_ops`의 daemon admission 서비스·자동화 모델 registry·worker 실행 경계가 영향 범위다. 기존 주간 일정과 감지 상태는 유지하며 운영 DB는 기존 thread task 저장 구조를 재사용한다.

# Tasks

## 1. Engine verification

- [x] 1.1 격리된 smoke fixture와 runner를 추가하고 실제 Defold 1.14.0 엔진에서 GUI·설정·점수 처리를 검사한다.
- [x] 1.2 기존 Lua suite와 Python suite를 실행하고 호환 문서의 재현 명령을 확인한다.

## 2. Compatibility release

- [x] 2.1 공식 release, SHA, inventory, breaking change 영향과 검증 경계를 문서화하고 strict spec validation을 통과한다.
- [ ] 2.2 검증한 변경을 commit/push하고 defold-1.14.0 호환 tag를 원격 재조회한다.

## Workflow follow-up

- 모든 helper 작업이 완료되면 archive하고 동기화된 spec을 검증한다.
- 승인된 5개 소비 게임의 pin·빌드·실행 검사는 각 저장소에서 별도로 수행한다.

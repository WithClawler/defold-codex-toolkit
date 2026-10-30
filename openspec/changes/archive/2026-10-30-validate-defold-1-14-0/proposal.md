# Proposal

## Why

Defold 1.14.0 stable 알림 뒤 공용 helper와 승인된 소비 게임을 함께 올릴 근거가 필요하다. 현재 helper에는 엔진별 호환 기록이나 실제 엔진에서 실행하는 회귀 검사가 없다.

## What Changes

- 공식 1.14.0 Bob과 실제 엔진을 사용하는 격리된 helper smoke 검사를 추가한다.
- helper의 기존 Lua API를 유지하고 검증된 source commit에 호환 tag를 부여한다.
- 영향 inventory, 공식 breaking changes, 검증 결과와 미검증 경계를 기록한다.

## Capabilities

### New Capabilities

- `engine-compatibility`: 고정 엔진과 현재 helper source를 사용한 재현 가능한 호환 검사.

### Modified Capabilities

없음.

## Impact

이 저장소의 검사 스크립트, test fixture와 문서만 변경한다. 후속 소비 프로젝트 변경은 사용자가 승인한 Blocktris, FirstDonut, Mini Survivor, Daily Arcade Rotation, Stack Rush에 한정한다. 기존 공용 Bob 파일, 범위 밖 프로젝트, 배포 중인 게임과 저장 데이터는 유지한다.

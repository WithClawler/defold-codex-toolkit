# Design

## Context

현재 순수 Lua unit suite는 GUI와 Defold API mock을 사용한다. Library-only game.project는 bootstrap collection이 없고, 소비 프로젝트들은 서로 다른 Bob과 helper commit을 사용한다.

## Goals / Non-Goals

실제 엔진에서 모듈과 기본 API를 검증하고 재실행 가능하게 한다. 소비 게임의 게임성, 스토어 공개, Android 실기기 동작은 별도 검증이며 이 fixture로 보증하지 않는다.

## Decisions

- 검사용 최소 collection과 GUI script를 tests/engine에 두고, runner가 ignored .local 아래에 helper와 fixture만 복사한다. library root에 bootstrap을 추가하지 않아 소비 dependency 계약을 유지한다.
- Bob 1.14.0 stable과 공식 SHA를 기록한다. macOS headless engine은 GUI API를 실제 호출하면서 사용자의 열린 앱에 영향을 주지 않는다.
- 호환 tag는 helper 코드의 공개 API 버전과 분리한다. Lua runtime 변경이 필요하지 않으면 plugin 버전을 올리지 않는다.

## Risks / Trade-offs

- Headless는 렌더링 품질을 보증하지 않는다. → 소비 프로젝트 wasm-web bundle은 실제 브라우저 입력과 화면으로 검증한다.
- 소비자가 구형 commit을 사용한다. → 각 프로젝트의 기존 회귀 검사를 먼저 실행하고 고정 commit으로 갱신한다.
- 일부 프로젝트가 FirstDonut Bob을 공유한다. → 기존 파일을 덮지 않고 대상 프로젝트별 버전 경로를 사용한다.

## Migration Plan

순수 Lua 검사 → 실제 엔진 smoke → 호환 문서와 tag → 승인된 소비 프로젝트별 업그레이드 순서로 진행한다. 실패하면 기존 source pin과 Bob 경로로 돌아갈 수 있도록 기존 파일을 보존한다.

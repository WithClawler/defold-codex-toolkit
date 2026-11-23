# Changelog

이 프로젝트는 [Semantic Versioning](https://semver.org/)을 따릅니다.

## 0.8.1 - 2026-11-24

### Fixed

- 아랍 문자에서 순위 철회 확인 본문이 제목·버튼에 닿던 배치

## 0.8.0 - 2026-11-23

### Added

- `settings_panel`이 순위 동의 상태(`leaderboard_joined`, `leaderboard_has_identity`, `deletion_pending`)를 받으면 설정에 순위 동의 철회 행과 확인 화면을 보여준다
  - 확인하면 `leaderboard_consent_selected` `{ opted_in = false }`를 보내고, 삭제 대기 중에는 재시도 문구를 쓴다.

## 0.7.0 - 2026-11-18

### Added

- 한 제스처를 한 입력 소스만 처리하게 하는 공용 탭 입력 `defold_helper.tap_input`
  - 모바일의 `MOUSE_BUTTON_1`·`TOUCH_MULTI` 중복과 브라우저 호환 마우스 이벤트를 걸러낸다.
  - 누른 대상 위에서 손을 뗄 때만 실행하고, 대상을 벗어나면 해제, 스크롤 slop을 넘으면 취소한다.
  - 눌림 표시용 대상·영역 조회, 사각형·GUI 노드·사용자 hit 함수 대상, 모달 바깥 탭을 지원한다.

## 0.6.0 - 2026-07-25

### Added

- Defold `wasm-web` bundle을 자체 포함 단일 HTML로 변환하는 `tools/single_html` packer
- normalized RGBA, HEX/HSL 변환, WCAG 대비 계산을 제공하는 `defold_helper.color_utils`
- 비파괴 merge·mapping·결정적 순회를 제공하는 `defold_helper.table_utils`
- trim·prefix/suffix·resource path 결합을 제공하는 `defold_helper.string_utils`
- 재사용 가능한 privacy modal 상태·입력 routing helper
- bounded scroll의 overscroll, inertia, spring physics와 반복 row layout helper
- 기본 20개 locale과 고정 native language selector variation
- 실제 Debug/Development 빌드를 위한 runtime AI QA bridge 설계 지침

### Changed

- Codex plugin과 Defold library 버전을 `0.6.0`으로 통일
- single-HTML packer와 runtime utility 사용법을 plugin manifest와 문서에 연결

[0.8.1]: https://github.com/WithClawler/defold-codex-toolkit/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/WithClawler/defold-codex-toolkit/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/WithClawler/defold-codex-toolkit/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/doctor-clawler/defold-codex-toolkit/compare/v0.5.0...v0.6.0

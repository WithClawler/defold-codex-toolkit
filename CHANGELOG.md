# Changelog

이 프로젝트는 [Semantic Versioning](https://semver.org/)을 따릅니다.

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

[0.6.0]: https://github.com/doctor-clawler/defold-codex-toolkit/compare/v0.5.0...v0.6.0

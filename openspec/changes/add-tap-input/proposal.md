# Proposal

## Why

Defold에는 버튼·탭 위젯이 없어 게임마다 입력 처리를 직접 만들고 있다. mini-survivor 로비에서는 한 번 탭했는데 팝업이 열렸다 닫히거나 반응이 늦는 문제가 생겼다. 원인은 모바일에서 한 터치가 `MOUSE_BUTTON_1`과 `TOUCH_MULTI`로 두 번 들어오는 것, 브라우저 호환 마우스 이벤트, 누르는 순간 실행하는 버튼이다. `privacy_modal.tap_action`의 프레임 기반 중복 차단도 같은 문제를 게임별로 막은 흔적이다. 공용 헬퍼로 한 번 해결해 재사용한다.

## What Changes

- 새 런타임 모듈 `defold_helper.tap_input`을 추가한다.
  - 한 제스처를 한 입력 소스만 처리하는 source gate(네이티브 모바일 touch-only, 터치 뒤 호환 마우스 echo 차단, 짝 없는 release 무시)
  - 누른 대상 위에서 뗄 때만 실행하는 tap tracker(벗어나면 해제·복귀하면 재무장, 스크롤 slop 취소, 눌림 표시 조회)
  - 사각형·GUI 노드·사용자 hit 함수 대상과 모달 바깥 탭 판정
- 런타임 문서, `defold-ui-input` 스킬, 엔진 스모크, 버전(0.7.0)과 CHANGELOG를 갱신한다.

## Capabilities

### New Capabilities
- `tap-input`: Defold UI 포인터 이벤트를 한 제스처로 정리하고 release 기준으로 탭을 판정하는 공용 동작

### Modified Capabilities

## Impact

- 새 파일 `defold_helper/tap_input.lua`, `tests/tap_input_test.lua`
- `docs/runtime-library.md`, `skills/defold-ui-input/SKILL.md`, `tests/engine/smoke.gui_script`, `game.project`·plugin 버전
- 기존 모듈 동작 변경 없음. 소비 프로젝트는 의존성 고정 커밋을 올려야 사용할 수 있다(첫 적용: mini-survivor).

# Design

## Context

소비 게임은 대부분 `MOUSE_BUTTON_1`(touch)과 `TOUCH_MULTI`(multi_touch)를 별도 action으로 바인딩한다(`defold-ui-input` 지침). 모바일 네이티브에서는 두 action이 같은 터치로 함께 들어오고, 모바일 브라우저는 터치가 끝난 뒤 호환 mouse 이벤트를 다시 보낸다. 게임마다 시간·거리 휴리스틱(mini-survivor 8px/0.12s/0.4s, privacy_modal 프레임 비교)으로 막아 왔다.

## Goals / Non-Goals

**Goals:**
- 엔진 API 없이 순수 Lua로 판정해 단위 테스트가 가능하고, GUI 노드 판정만 `gui.pick_node`를 쓴다.
- 기존 GUI 구조(노드 유지형·매 프레임 재생성형)를 가리지 않고 쓸 수 있게 대상 판정을 호출자 콜백·사각형으로도 받는다.

**Non-Goals:**
- 시각 스타일, 바인딩 파일 수정, 좌표 변환, 스크롤 물리(`defold_helper.scroll`이 담당)
- 기존 `privacy_modal.tap_action` 동작 변경

## Decisions

- **거리 대신 시간 창으로 echo 차단:** 호환 mouse 이벤트 좌표는 터치 좌표와 어긋날 수 있고(캔버스 스케일·지연) 0.4s를 넘기도 한다. 터치 이후 1.0s 동안 mouse를 무시하는 것은 브라우저의 pointer-type 판정과 같은 방식이다. 하이브리드 기기에서 터치 직후 1초 내 실제 마우스 클릭은 무시되지만, 다음 클릭은 정상 처리된다.
- **gate와 tap tracker 분리:** 드래그·조이스틱처럼 탭이 아닌 입력도 source gate는 필요하므로 둘을 독립 상태로 둔다.
- **release 실행 + 재무장:** 플랫폼 버튼과 같은 동작이다. 누르는 순간 실행하면 손가락 아래에 새로 열린 UI가 held/release 이벤트를 받는 연쇄가 생긴다.
- **오류는 assert:** 잘못된 source·phase·좌표는 호출자 결함이므로 조용히 무시하지 않는다(works 런타임 오류 정책).

## Risks / Trade-offs

- [같은 프레임 press+release] Defold가 한 action에 두 플래그를 함께 줄 수 있다 → `phase`는 release를 돌려주고, 문서 예시처럼 호출자가 press를 먼저 처리한다.
- [touch_only 오판] 네이티브 모바일에서 외부 마우스를 쓰면 무시된다 → Defold 네이티브 모바일은 마우스도 터치로 전달하므로 실사용 영향이 작다. 옵션이라 게임별로 끌 수 있다.

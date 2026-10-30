# Defold engine compatibility

## Defold 1.14.0 stable — 2026-10-30

공식 엔진은 `1.14.0`, SHA는 `d295ed4edff2e49072719835713e625f409849f1`이다.
Bob release asset의 SHA-256은
`d8cbe667757ca1c5f4dfd251bc98660c35e7a65ac84bf0207ccef7607de6d1a1`이다.
공용 Lua API는 변경하지 않았다. 호환 tag는 `defold-1.14.0`이며 toolkit의 API 버전 `0.6.0`과 구분한다.

공식 근거:

- [Stable release와 engine SHA](https://github.com/defold/defold/releases/tag/1.14.0)
- [기능과 breaking changes](https://defold.com/2026/10/12/Defold-1-14-0/)
- [공식 문서 인덱스](https://defold.com/llms.txt)

## 검증과 재현

macOS에서 Java와 Lua를 준비하고 공식 Bob을 ignored 경로에 설치한다.

```sh
mkdir -p .local/engine/1.14.0
curl -fL https://github.com/defold/defold/releases/download/1.14.0/bob.jar \
  -o .local/engine/1.14.0/bob.jar
printf '%s  %s\n' \
  d8cbe667757ca1c5f4dfd251bc98660c35e7a65ac84bf0207ccef7607de6d1a1 \
  .local/engine/1.14.0/bob.jar | shasum -a 256 -c -
lua tests/run_lua_tests.lua
python3 -m unittest discover -s tests -p 'test_*.py'
python3 scripts/test_engine_compatibility.py
```

2026-10-30에 Lua 17개 suite, Python 9개 test와 macOS headless 실제 엔진 smoke가 통과했다.
엔진 smoke는 15개 helper 모듈을 컴파일·로드하고 실제 `gui`, `vmath`, `sys.save/load`를 호출한다.
설정 패널의 press/release hit test, 음소거 설정 저장·재조회, 닫기와 점수 저장·재조회를 검사한다.
저장은 전용 `defold-helper-engine-smoke` namespace만 사용하고 생성한 파일은 제거한다.
각 실행의 project, bundle, runtime log는 `.local/engine-smoke-*`에 보존한다.
성공은 프로세스 exit 0과 `DEFOLD_HELPER_ENGINE_SMOKE_OK 1.14.0 <engine-sha>`가 함께 있어야 한다.

Headless 검사는 화면 렌더링 품질이나 소비 게임의 플레이·광고·실기기 QA를 증명하지 않는다.
Android/iOS/macOS graphics backend의 실기기 검증과 스토어 제출·공개는 이 호환 tag의 검증 범위가 아니다.

## Inventory와 승인된 적용 범위

2026-10-30 works inventory에서 `game.project` 16개를 발견했다. 그중 helper 소비자는 아래 5개이다.
엔진 알림의 이전 버전 `1.13.2`는 release monitor 기준이며 로컬 프로젝트 버전과 다르다.

| 소비 프로젝트 | 기존 Bob 출처 | 기존 helper commit |
| --- | --- | --- |
| Blocktris | FirstDonut 공유 Bob 1.13.1 | `14103257e5e70d26aa01b8fbfa3073c0f22f1216` |
| FirstDonut | project Bob 1.13.1 | `14103257e5e70d26aa01b8fbfa3073c0f22f1216` |
| Mini Survivor | project Bob 1.13.0 | `68597b3aef0a9c2538edd9e9168deb5f32416f76` |
| Daily Arcade Rotation | FirstDonut 공유 Bob 1.13.1 | `d5459865e236ba615ad013fd8dcfaac75620260d` |
| Stack Rush (`daily-arcade-rotation/apps/stack-rush`) | product builder의 FirstDonut 공유 Bob 1.13.1 | `14103257e5e70d26aa01b8fbfa3073c0f22f1216` |

사용자가 helper와 위 5개 소비 게임을 적용 대상으로 지정했다. 소비자는 호환 tag가 가리키는
immutable commit을 dependency로 사용하고 각 project의 `.local/defold/1.14.0/bob.jar`로 빌드한다.
기존 FirstDonut의 `tools/defold/bob.jar`는 다른 게임들도 참조하므로 그대로 둔다.
독립 TextRPGM 1.12.3, playground 게임과 export/검증 복사본은 이번 적용 대상이 아니다.

## Breaking change 영향

- Native ABI: helper 자체는 Lua이고 C++ handle을 보관하지 않는다. 소비자의 font app manifest와
  Android native extension은 1.14.0 SDK로 새로 빌드해야 하며 구형 엔진 binary를 재사용하면 안 된다.
- Shared Lua state: FirstDonut과 Mini Survivor는 이미 `shared_state = 1`이다.
  다른 소비자는 기본값을 사용한다. `shared_state = 0`에 의존하는 소비자는 발견되지 않았다.
- Windows x86: 소비자의 실제 Windows target을 새로 추가하지 않는다. 지원이 제거된 `x86-win32`
  font app manifest 항목은 제거하고 기존 x86_64 항목을 유지한다.
- Accelerometer: 소비자의 input binding에서 가속도 입력 사용 여부를 확인한다. 사용하지 않으면
  새 기본값을 유지한다.
- Editor resource-type API: helper는 해당 editor plugin API를 사용하지 않는다.
  이 머신에서 실행 중인 Defold Editor는 발견되지 않았으며 검증 대상은 Bob 기반 빌드다.
- Metal 기본값과 모바일 safe area: Headless 통과로 검증했다고 보지 않으며 플랫폼별 화면 QA와 구분한다.

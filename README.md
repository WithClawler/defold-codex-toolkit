# Defold Codex Toolkit

이 저장소는 공개 GitHub에 올릴 수 있는 Defold용 Codex plugin 저장소입니다.

## 프로젝트 소개

`defold-codex-toolkit`은 Defold 프로젝트 작업에서 반복되는 워크플로우를 Codex가 더 일관되게 지원할 수 있도록 정리한 plugin 패키지입니다. 이 저장소는 Codex에서 로컬로 로드되는 plugin 형식이며, 공개 GitHub 업로드 자체가 OpenAI 공식 공개 marketplace 자동 등록을 뜻하지 않습니다.

현재 릴리즈 변경사항은 [`CHANGELOG.md`](CHANGELOG.md)에서 확인할 수 있습니다.

## 제공 기능

- Defold 빌드 및 번들 작업 가이드
- Slack `/build` 연동용 Android build/upload 스크립트 규약
- Defold GUI 및 입력 처리 가이드
- Defold GUI 텍스트, 폰트, 글리프 커버리지 점검 가이드
- Defold 디버깅 워크플로우 가이드
- Defold 엔진 릴리즈 확인 및 `defold_helper` 정합성 업그레이드 가이드
- Defold 프로젝트 컨벤션 점검 가이드
- Defold 프로젝트가 dependency로 가져다 쓸 수 있는 `defold_helper/` Lua runtime helper
- Defold HTML5 bundle을 자체 포함 단일 HTML로 변환하는 `tools/single_html` packer
- 빌드된 Debug/Development 제품을 AI가 직접 조작·관찰하기 위한 runtime QA bridge 설계 지침
- normalized color·WCAG contrast·table transform·resource path용 범용 Lua util
- CSV 기반 localization table helper 및 기본 20개 locale 코드/selector 이름 variation 목록
- 재사용 가능한 privacy modal 상태/클릭 처리 helper
- 재사용 가능한 bounded scroll 상태/드래그/휠/관성/탄성 layout helper

각 항목은 `skills/` 하위 `SKILL.md`로 제공됩니다.
빌드 제품 runtime QA 계약은
[`skills/defold-project-conventions/references/runtime-ai-qa.md`](skills/defold-project-conventions/references/runtime-ai-qa.md)를
기준으로 합니다.

최신 Defold 문서 확인이 필요한 작업에서는 공식 LLM용 문서 인덱스인 `https://defold.com/llms.txt`를 우선 진입점으로 사용합니다.

## Shared `/build` Contract

이 plugin은 `_ops` 같은 공유 Slack daemon이 Defold 프로젝트 루트에서 표준 build script를 찾아 실행하는 워크플로우를 전제로 합니다.

- 표준 진입 스크립트: `scripts/build_and_upload_android.sh`
- 권장 분리 스크립트:
  - `scripts/build_android.sh`
  - `scripts/upload_android_build_to_slack.sh`
- 권장 산출물 경로: `.local/artifacts/<project-slug>-android.apk`

기본 운영 모델은 다음과 같습니다.

1. Slack `/build`가 현재 active project root를 찾습니다.
2. `<project>/scripts/build_and_upload_android.sh`가 있으면 그 스크립트를 실행합니다.
3. 스크립트가 없으면 daemon은 `빌드 스크립트가 없습니다.`를 반환합니다.
4. 스크립트 자체가 Android build와 Slack 업로드를 모두 책임집니다.

이 계약을 따르면 새로운 Defold 프로젝트도 `_ops` 쪽에 프로젝트별 artifact branch를 추가하지 않고 같은 `/build` 표면을 재사용할 수 있습니다.

## Single-HTML packer

`tools/single_html/pack.mjs`는 이미 생성된 Defold `wasm-web` HTML5 bundle을 자체 포함 단일 HTML 파일로 변환합니다. WebAssembly 엔진, 생성된 엔진 JavaScript, archive 조각, loader, CSS와 로컬 미디어를 한 파일에 내장하므로 playable ad나 단일 파일 납품에 사용할 수 있습니다.

Node.js 18 이상과 Zstandard CLI 1.5 이상이 필요합니다. JavaScript dependency는 한 번 설치합니다.

```bash
npm install --prefix tools/single_html

node tools/single_html/pack.mjs \
  "build/default-web/My Game" \
  --output "build/MyGame.single.html"
```

기본 압축은 Zstandard이며, 테스트와 옵션 및 제한사항은 [`tools/single_html/README.md`](tools/single_html/README.md)에 정리되어 있습니다. `tools/`는 루트 `.defignore`로 Defold library dependency 결과에서 제외되므로 `defold_helper/` 런타임 패키지와 섞이지 않습니다.

## 디렉터리 구조 설명

```text
.codex-plugin/plugin.json
game.project
defold_helper/
  score_records.lua
  score_ui.lua
  game_over_ui.lua
  gameplay_layer.lua
  local_leaderboard.lua
  localization.lua
  privacy_modal.lua
  scroll.lua
  color_utils.lua
  table_utils.lua
  string_utils.lua
skills/
  defold-build-bundle/SKILL.md
  defold-ui-input/SKILL.md
  defold-ui-text-fonts/SKILL.md
  defold-debug-workflow/SKILL.md
  defold-engine-upgrade/SKILL.md
  defold-project-conventions/SKILL.md
  defold-project-conventions/references/runtime-ai-qa.md
tools/
  single_html/
    pack.mjs
    package.json
    test/pack.test.mjs
examples/marketplace.json.example
CHANGELOG.md
README.md
LICENSE
```

## Defold runtime library

이 저장소는 Codex skill package이면서 Defold library project이기도 합니다. `game.project`의 `[library] include_dirs = defold_helper` 설정으로 `defold_helper/` 폴더만 소비 프로젝트에 노출합니다.

소비 프로젝트에서는 release tag나 고정 commit archive URL을 `game.project`의 `[project] dependencies`에 넣고 Defold Editor에서 `Project > Fetch Libraries`를 실행합니다.

```ini
[project]
dependencies#0 = https://github.com/doctor-clawler/defold-codex-toolkit/archive/<commit-or-tag>.zip
```

코드에서는 project-local wrapper나 adapter가 helper namespace를 직접 require합니다.

```lua
local score_records = require("defold_helper.score_records")
local score_ui = require("defold_helper.score_ui")
local local_leaderboard = require("defold_helper.local_leaderboard")
local localization = require("defold_helper.localization")
local privacy_modal = require("defold_helper.privacy_modal")
local scroll = require("defold_helper.scroll")
local color_utils = require("defold_helper.color_utils")
local table_utils = require("defold_helper.table_utils")
local string_utils = require("defold_helper.string_utils")
```

자세한 adapter 예시는 [`docs/runtime-library.md`](docs/runtime-library.md)에 있습니다.

### Catalog localization and a shared settings panel

`localization_catalog`, `localized_text`, `settings_store`, `settings_panel`은
Stack Rush의 설정·텍스트 런타임을 게임별 의존성 주입 factory로 분리한 모듈입니다.
기존 CSV 기반 `defold_helper.localization` API는 그대로 유지합니다. 새 모듈은
게임의 번역·서체·저장 namespace·개인정보 공급자를 내장하지 않습니다.

```lua
local catalog = require("defold_helper.localization_catalog").new(DATA, {
  default_locale = "en-US",
  dynamic_text = "99999999 ·", -- 숫자·ASCII 외에 게임이 동적으로 사용하는 문자
  -- 선택 사항: 정규화된 locale을 받아 이 게임의 문서 URL을 반환합니다.
  policy_url = function(locale) return "https://example.com/privacy/" .. locale end,
})
local text = require("defold_helper.localized_text").new(catalog)
local settings = require("defold_helper.settings_store").new({
  namespace = "my-game",
  file_name = "game_settings",
  localization = catalog,
})
local settings_ui = require("defold_helper.settings_panel").new({
  localization = catalog,
  localized_text = text,
  settings_store = settings,
  enable_privacy = false,
  -- 선택 사항: 미지정 시 소리를 재생하지 않습니다.
  audio = {play = function(options, kind) end, stop = function() end},
})

local options = settings.load()
local locale = settings.locale(options, sys, html5)
local panel = settings_ui.create(locale, options)
settings_ui.open(panel)
-- 정규화된 GUI 좌표와 실제 press/release 단계를 전달합니다.
local consumed = settings_ui.handle_input(panel, "pressed", x, y)
settings_ui.handle_input(panel, "released", x, y)
-- panel.locale과 panel.settings를 화면·게임에 즉시 반영합니다.
```

`DATA`의 필드는 `locales = {{id, name, font, ...}}`,
`copy = {[locale] = {[key] = value}}`,
`fonts = {[font_id] = {name, resource, ttf, fallbacks = {font_id, ...}}}`입니다.
`resource`는 `/gui/ko.fontc` 같은 compiled font collection 경로,
`ttf`는 fallback으로 연결할 원본 리소스 경로입니다. 공용 카피와 게임별 override는
소비자가 이 데이터에 합친 뒤 factory에 전달합니다. 기본 locale은 목록과 copy에
명시되어 있어야 하며, 누락된 번역의 영어 fallback은 번역 완료로 간주하지 않습니다.

Catalog는 `normalize_locale/is_supported/info/locales/fonts/font_text/detect_locale/
copy/text/supported_locales/policy_url`을 제공합니다. 저장된 locale은 canonical ID만
허용하고, 기기 선택은 `device_language → locale → language` 순서로 감지합니다.
HTML5의 `?lang=`은 기기 선택 override이며 저장된 선택을 덮지 않습니다.

Text renderer는 `set_locale/prepare/set/fit`을 제공합니다. fallback font를 연결한 뒤
문구 전체와 동적 ASCII를 prewarm하고, 준비 성공 후에만 텍스트를 표시합니다.
비동기 요청 token은 오래된 언어의 callback이 새 텍스트를 덮지 못하게 하며,
화면이 숨긴 node를 다시 켜지 않습니다. 소비자는 runtime font generation과
문자권별 text layout engine을 설정하고 실제 카피 inventory에 맞는 폰트·라이선스를
번들해야 합니다. 다른 게임의 subset이 새 문구의 글리프까지 포함한다고 가정하지 않습니다.

일부 서체를 오프라인 bitmap으로 bake해 runtime 서체와 함께 사용하는 경우,
`DATA.fonts[font_id].runtime = false`로 지정합니다. 해당 서체는 `prepare()`와 `set()`에서
runtime prewarm과 fallback 연결을 건너뛰고 즉시 표시하며, 불필요하게 기존 텍스트를
비우지 않습니다. `runtime`을 생략하거나 `true`로 지정한 서체는 기존 비동기 준비·token
보호 동작을 유지합니다. 이 필드는 helper의 준비 방식만 정하므로 소비자는 실제로
오프라인 glyph bank를 포함한 `.fontc`를 제공해야 합니다. 예를 들어 TTF를 빌드 시점에
rasterize하려면 `.font`에 `output_format: TYPE_BITMAP`과
`material: "/builtins/fonts/font.material"`, 필요한 `characters`를 지정합니다.
외부 `.fnt` BMFont는 `font-fnt.material`을 사용합니다. 두 경우 모두 실제 글리프 범위와
레이아웃은 소비 프로젝트의 빌드·화면으로 확인합니다.

Settings store는 `load/save/locale`을 제공하고 사운드 기본값은 ON입니다. 저장 실패는
`false`로 반환하며 panel은 기존 선택을 유지하고 오류를 표시합니다. namespace와
파일은 기록·광고 동의 등 다른 저장 영역과 별도로 지정합니다.

Settings panel은 Stack Rush의 720×1280 배치·색상과 `create/render/open/handle_input`
호출 형태를 유지합니다. 기본 node prefix는 `privacy_center_`이고 `node_prefix`로
변경할 수 있습니다. `create()`가 반환한 `panel.visible`, `panel.locale`,
`panel.settings`, `panel.mode`는 소비자가 읽을 수 있습니다. 언어는 native name으로
5개씩 보여주고, modal 밖의 입력도 소비합니다. 키보드 등 panel에 전달하지 않는
입력은 소비자가 `panel.visible` 동안 차단해야 합니다. 한 frame에 press/release가
함께 온 경우 두 단계를 순서대로 호출해야 합니다.

광고가 없는 앱은 반드시 `enable_privacy=false`로 생성하면 sound/language/close만
제공하며 광고 mode를 열 수 없습니다. 기본 `true`는 Stack Rush 호환용입니다.
기존 광고/privacy 흐름을 사용하는 adapter는 `on_action(action, payload)`에서
`privacy_options_requested`, `advertising_choice_selected`,
`watch_rewarded_ad_requested`를 해당 게임의 controller에 전달합니다. 정책 문서 이동은
`open_url(url)`을 주입하거나 기본 `sys.open_url`을 사용합니다. 공급자 상태는
`settings_ui.on_message(panel, state)` 또는 기존 `panel.state=state; render(panel)`로
갱신합니다. 이 모듈 자체는 광고·랭킹 서비스를 활성화하거나 새 동의를 만들지 않습니다.

검증: `lua tests/run_lua_tests.lua`. 저장 실패·앱별 격리, locale 정규화·기기 감지,
비동기 font 준비·오래된 callback, 언어 pagination·사운드 OFF·modal 입력 capture와
광고 없는 구성의 provider action 차단을 확인합니다. 실제 font shaping·레이아웃은
소비 프로젝트의 Defold 빌드와 화면 검사로 별도 검증합니다.

## 설치 방법

1. 이 저장소를 로컬에 가져옵니다.

```bash
git clone https://github.com/doctor-clawler/defold-codex-toolkit.git defold-codex-toolkit
```

2. 또는 GitHub URL을 직접 설치 대상으로 쓰는 것이 아니라, 클론하거나 복사한 로컬 저장소를 사용합니다.

## 주간 최신 버전 자동 갱신

이 저장소 자체를 최신 상태로 유지하려면 `origin/main`을 최신 버전 기준으로 봅니다. 자동 체크 스크립트는 매주 금요일 한 번 원격을 fetch하고, 로컬 브랜치가 원격보다 뒤처져 있을 때만 `git merge --ff-only origin/main`으로 갱신합니다.

- 기본 실행 스크립트: `scripts/check_latest_and_update.py`
- launchd 래퍼: `scripts/run-latest-check.sh`
- launchd 설치 스크립트: `scripts/install-latest-check-launchd.sh`
- 기본 스케줄: 매주 금요일 `09:00` 로컬 시간
- Slack 알림 채널: `C0ARH1MHF4H`
- 로그 경로: `~/Library/Logs/defold-codex-toolkit/`

동작 정책은 다음과 같습니다.

1. 원격 최신 commit이 없으면 Slack에 아무 메시지도 보내지 않습니다.
2. 원격 최신 commit이 있으면 fast-forward 갱신 후 패치 노트와 변경 파일 요약을 Slack에 보냅니다.
3. 로컬 브랜치가 원격과 diverge 되었거나 working tree가 dirty이면 자동 병합하지 않고 로그에 실패를 남깁니다.

수동 실행:

```bash
python3 scripts/check_latest_and_update.py --no-notify
```

스케줄 설치 또는 갱신:

```bash
scripts/install-latest-check-launchd.sh
```

## Defold 엔진 릴리즈 체크

Defold 엔진 최신 릴리즈는 별도 주간 job이 확인합니다.

- 릴리즈 체크 스크립트: `scripts/check_defold_engine_release.py`
- launchd 래퍼: `scripts/run-defold-engine-release-check.sh`
- 기본 스케줄: 매주 금요일 `09:15` 로컬 시간
- Slack 알림 채널: `C0ARH1MHF4H`
- 상태 파일: `.local/state/defold-engine-release.json`

첫 실행에서는 현재 최신 Defold 릴리즈를 baseline으로 저장하고 Slack 메시지를 보내지 않습니다. 이후 새 릴리즈가 감지되면 공식 release notes 요약과 `defold-engine-upgrade` 권장 절차를 Slack에 보냅니다.

엔진 업그레이드는 프로젝트별로 수행합니다. `defold_helper`를 쓰는 프로젝트는 Defold Editor 또는 `bob.jar` 버전과 이 toolkit의 `defold_helper` dependency tag/commit을 함께 맞춰야 합니다. 즉, `defold_helper`는 Defold 엔진과 같은 패키지는 아니지만 업그레이드 검증 단위에서는 함께 정합성을 맞추는 대상으로 봅니다.

## 프로젝트 한정 사용 방법

다른 프로젝트에서 plugin을 붙여 쓰려면 다음 순서를 따릅니다.

1. 현재 프로젝트 루트에 `plugins/defold-codex-toolkit` 폴더를 준비합니다.
2. 이 저장소를 그 경로에 `clone`하거나 전체를 복사합니다.
3. 프로젝트의 `.agents/plugins/marketplace.json`에서 `source.path`를 로컬 경로로 지정합니다.
4. Codex를 재시작하거나 plugin discovery를 갱신합니다.

예시 경로:

- `./plugins/defold-codex-toolkit`

## marketplace.json 예시

아래 예시는 다른 프로젝트의 `.agents/plugins/marketplace.json`에서 추가하거나 적용할 내용입니다.

```json
{
  "name": "example-project-marketplace",
  "interface": {
    "displayName": "Example Project Marketplace"
  },
  "plugins": [
    {
      "name": "defold-codex-toolkit",
      "source": {
        "source": "local",
        "path": "./plugins/defold-codex-toolkit"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Coding"
    }
  ]
}
```

실제 적용은 [`examples/marketplace.json.example`](examples/marketplace.json.example) 파일을 복사해서 시작하는 방식을 권장합니다.

## Codex에서 사용되는 방식 설명

Codex는 호스트 프로젝트의 `.agents/plugins/marketplace.json`에 등록된 plugin path를 통해 `defold-codex-toolkit`의 `.codex-plugin/plugin.json`을 읽고, `skills/` 아래 `SKILL.md` 파일을 탐색합니다. 즉, Codex는 원격 GitHub URL을 직접 설치하는 것이 아니라 로컬 경로를 참조해서 plugin을 로드합니다.

`defold-build-bundle` skill은 위 Shared `/build` Contract를 따르는 Android build/upload 스크립트를 프로젝트에 정착시키는 지침으로도 사용됩니다.

## 주의사항 / 제한사항

- 이 저장소는 공개 GitHub용 plugin package이지만 OpenAI 공식 marketplace 자동 등록과는 무관합니다.
- GitHub URL만 넣어서 바로 설치되는 구조가 아닙니다.
- 반드시 프로젝트 안에 이 plugin 저장소를 로컬로 clone 또는 copy한 뒤, 프로젝트 쪽 marketplace가 그 로컬 path를 참조해야 합니다.
- README의 clone URL은 공개 저장소 `doctor-clawler/defold-codex-toolkit` 기준입니다.

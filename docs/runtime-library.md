# Defold Helper Runtime Library

`defold-codex-toolkit` also ships a small Defold library under the collision-resistant `defold_helper/` namespace. The helper repo is the source of truth for these runtime modules:

- `defold_helper.score_records`
- `defold_helper.score_ui`
- `defold_helper.game_over_ui`
- `defold_helper.gameplay_layer`
- `defold_helper.local_leaderboard`
- `defold_helper.localization`
- `defold_helper.privacy_modal`
- `defold_helper.scroll`
- `defold_helper.tap_input`
- `defold_helper.color_utils`
- `defold_helper.table_utils`
- `defold_helper.string_utils`

## Defold Adoption

The library project exposes only `defold_helper` through `game.project`:

```ini
[library]
include_dirs = defold_helper
```

In a consuming Defold project, add a pinned library archive URL to the `[project]` dependencies list:

```ini
[project]
dependencies#0 = https://github.com/doctor-clawler/defold-codex-toolkit/archive/<commit-or-tag>.zip
```

After changing dependencies, run `Project > Fetch Libraries` in the Defold editor. Defold will expose the shared folder so project code can use direct namespaced requires:

```lua
local score_records = require("defold_helper.score_records")
local score_ui = require("defold_helper.score_ui")
local local_leaderboard = require("defold_helper.local_leaderboard")
local privacy_modal = require("defold_helper.privacy_modal")
local scroll = require("defold_helper.scroll")
local tap_input = require("defold_helper.tap_input")
local color_utils = require("defold_helper.color_utils")
local table_utils = require("defold_helper.table_utils")
local string_utils = require("defold_helper.string_utils")
```

Use a release tag or pinned commit archive for production projects. A branch archive is useful for quick smoke checks but can change underneath a consumer.

## Adapter Pattern

Keep project-specific naming and game rules in the consumer project. For example, a tower-height game can wrap generic score records with local field names:

```lua
local score_records = require("defold_helper.score_records")

local HEIGHT_FIELDS = {
  last_score = "last_height_m",
  best_score = "best_height_m",
  total_score = "total_height_m",
  best_combo = "best_combo",
}

local state = score_records.load({
  sys = sys,
  app_name = "stack-rush",
  file_name = "height_records",
  fields = HEIGHT_FIELDS,
})
```

## Localization Tables

`defold_helper.localization` loads simple CSV localization tables with a `key` column and one column per language. Optional metadata columns such as `comment` or columns starting with `#` are ignored.

Use `localization.default_languages()` when a project needs the shared default table shape. The default locale order is:

```text
ko-KR, en, ja-JP, zh-CN, zh-TW, de-DE, fr-FR, es-419, es-ES, pt-BR, it-IT, ru-RU, tr-TR, pl-PL, th, id, vi, ar, hi-IN, nl-NL
```

Language selector UI should use fixed native language names, not the currently selected language's translation table. `localization.default_language_variations()` returns selector-ready records in the same order, with `code`, fixed native `name`, and legacy `aliases`. `localization.language_display_name("ko")` returns `한국어`, and `localization.language_display_name("ja")` returns `日本語`.

```lua
for _, language in ipairs(localization.default_language_variations()) do
  print(language.code, language.name)
end

print(localization.language_display_name("ko"))
```

Short legacy codes such as `ko`, `ja`, `zh`, `de`, `fr`, `es`, `pt`, `it`, `ru`, `tr`, `pl`, `hi`, and `nl` normalize to the matching default locale only when that canonical locale column exists in the bundle. This keeps older `en,ko` tables working while allowing new tables to use canonical locale columns.

```csv
key,ko-KR,en,ja-JP,zh-CN,zh-TW,de-DE,fr-FR,es-419,es-ES,pt-BR,it-IT,ru-RU,tr-TR,pl-PL,th,id,vi,ar,hi-IN,nl-NL,comment
ui.title,미니 서바이버,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,Mini Survivor,shown on title screen
ui.greeting,"안녕, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}","Hello, {name}",supports placeholders
```

In a Defold game, list the CSV file as a custom resource and load it through a small project-local adapter:

```lua
local localization = require("defold_helper.localization")

local bundle = localization.from_resource("/assets/localization.csv", {
  sys = sys,
  default_language = "ko-KR",
  fallback_language = "en",
  languages = localization.default_languages(),
})

print(bundle:text("ui.greeting", { name = "Ada" }))
print(bundle:text("ui.title", "ko"))
print(bundle:language_display_name("ko"))
```

The helper intentionally does not own a global language setting for the whole game. Keep save data, settings UI, and language switching policy in the consuming project.

## General Utility Modules

`defold_helper.color_utils` uses normalized `0..1` RGBA tables, matching Defold's native color vector range. It parses and formats common hex colors, interpolates and adjusts HSL colors, calculates [WCAG 2.2 sRGB contrast](https://www.w3.org/TR/WCAG22/#dfn-relative-luminance), and can create a `vmath.vector4` at the engine boundary.

```lua
local color_utils = require("defold_helper.color_utils")

local background = color_utils.from_hex("#101820")
local text_color, contrast = color_utils.best_contrast(background)

gui.set_color(self.panel, color_utils.to_vector4(background))
gui.set_color(self.label, color_utils.to_vector4(text_color))

if not color_utils.passes_contrast(contrast, "AA", false) then
  print("normal text contrast is too low")
end
```

`defold_helper.table_utils` keeps generic table operations non-mutating. `merge` returns a new shallow table with later sources winning, `map_values` preserves keys, and `sorted_keys`/`sorted_pairs` provide deterministic iteration for UI rows, debug output, and serialization adapters.

```lua
local table_utils = require("defold_helper.table_utils")

local options = table_utils.merge(default_options, saved_options, session_options)
for key, value in table_utils.sorted_pairs(options) do
  print(key, value)
end
```

`defold_helper.string_utils` contains small string and path-boundary operations without taking ownership of filesystem or URL policy.

```lua
local string_utils = require("defold_helper.string_utils")

local atlas_path = string_utils.join_path("/assets", "ui", "buttons.atlas")
if string_utils.ends_with(atlas_path, ".atlas") then
  print(atlas_path)
end
```

These modules intentionally do not create GUI nodes, select pivots, set blend modes, or choose font scale policy. Keep those visual decisions in project-local GUI adapters.

## Privacy Modal Adapter

`defold_helper.privacy_modal` owns reusable privacy-modal state, button hit fallback bounds, duplicate tap blocking, and open/close action routing. The consuming game still owns the actual `.gui` nodes, localized privacy text, visual styling, sound effects, and Play Console wording.

```lua
local privacy_modal = require("defold_helper.privacy_modal")

local modal = privacy_modal.create({
  lines = {
    "No personal data is collected.",
    "Local progress stays on this device.",
  },
  button_bounds = {
    min_x = 470,
    max_x = 625,
    min_y = 970,
    max_y = 1045,
  },
})

local result = privacy_modal.tap_action(modal, {
  frame = self.input_frame,
  last_handled_frame = self.last_touch_press_frame,
  x = x,
  y = y,
  button_hit = gui.pick_node(self.privacy_button, x, y),
})

if result.kind == privacy_modal.ACTIONS.OPEN then
  gui.set_enabled(self.privacy_modal_node, true)
elseif result.kind == privacy_modal.ACTIONS.CLOSE then
  gui.set_enabled(self.privacy_modal_node, false)
end
```

Keep project-specific legal copy in the consuming project, or feed it from `defold_helper.localization` through a local adapter. The helper should not include app names, policy claims, store URLs, or publisher contact data.

## Tap Input Adapter

`defold_helper.tap_input` owns the two input rules every Defold UI needs and that otherwise get re-invented per game:

- **One source per gesture.** On mobile a single touch reaches `on_input` through both a `MOUSE_BUTTON_1` binding and a `TOUCH_MULTI` binding, and mobile browsers add compatibility mouse events after the touch ends. `tap_input.gate` lets the first source own the gesture (a touch takes over a mouse gesture the engine emulated from that same touch), ignores the other source until release, ignores mouse events for `echo_window` seconds (default 1.0) after any touch event, and ignores releases or held frames that have no accepted press. Native Android/iOS builds can pass `touch_only = true`.
- **Activate on release.** `tap_input.tap` arms the target under the press, disarms while the pointer is off that target, re-arms when it returns, and activates only when the release lands on the same target. A press on nothing can never activate by sliding onto a button. `slop` turns a press into a scroll gesture once it moves too far. `tap_input.pressed` returns the armed target and bounds so the HUD can show a pressed state.

The consuming game still owns its bindings, coordinate conversion, visual pressed style and the actions themselves. Targets can be GUI nodes (`gui.pick_node`), center-anchored rectangles `{x, y, w, h}` or a custom `hit(x, y)` function. List them topmost first; `{ modal = true }` turns a miss into `tap_input.OUTSIDE` so an open modal blocks everything beneath it and can close from an outside tap.

```lua
local tap_input = require("defold_helper.tap_input")

function init(self)
  local system = sys.get_sys_info().system_name
  self.pointer_gate = tap_input.gate({ touch_only = system == "Android" or system == "iPhone OS" })
  self.tap = tap_input.tap()
  self.clock = 0
end

local function targets(self)
  if self.popup_open then
    return { { id = "close", node = self.close_node }, { id = "panel", node = self.panel_node } }, { modal = true }
  end
  return { { id = "settings", node = self.settings_node }, { id = "start", node = self.start_node } }
end

local function pointer(self, source, action, x, y)
  local phase = tap_input.phase(action.pressed, action.released, action.value)
  if action.pressed and action.released then
    -- A press and release inside one frame: run both halves of the tap.
    pointer(self, source, { pressed = true, value = 1 }, x, y)
  end
  if not tap_input.accept(self.pointer_gate, source, phase, self.clock) then return true end
  local list, options = targets(self)
  local target = tap_input.target_at(list, x, y, options)
  if phase == tap_input.PRESSED then
    tap_input.press(self.tap, target, x, y)
  elseif phase == tap_input.HELD then
    tap_input.move(self.tap, x, y, target)
  else
    local activated = tap_input.release(self.tap, x, y, target)
    if activated == "settings" then self.popup_open = true
    elseif activated == "close" or activated == tap_input.OUTSIDE then self.popup_open = false
    elseif activated == "start" then start_game(self) end
  end
  return true
end

function update(self, dt)
  self.clock = self.clock + dt
end

function on_input(self, action_id, action)
  if action_id == hash("touch") then return pointer(self, tap_input.MOUSE, action, action.x, action.y) end
  if action_id == hash("multi_touch") and action.touch and action.touch[1] then
    local touch = action.touch[1]
    return pointer(self, tap_input.TOUCH, touch, touch.x, touch.y)
  end
end
```

Use `tap_input.reset(gate)` and `tap_input.cancel(tap)` when the game ends a gesture itself, for example after a browser reports a release outside the canvas or when a mode change discards the pressed target. Invalid sources, phases, clocks, coordinates or targets raise errors instead of being ignored.

## Scroll State Adapter

`defold_helper.scroll` owns bounded scroll state, drag deltas, wheel steps, clamp behavior, optional rubber-band overscroll, release velocity, inertial/spring updates, repeated-row layout math, and normalized scroll ratios. The consuming game still owns hit rectangles, GUI nodes, scrollbar colors, concrete row art, and platform-specific input bindings.

```lua
local scroll = require("defold_helper.scroll")

local stats_scroll = scroll.create({
  min = 0,
  max = 500,
  wheel_step = 80,
  overscroll_limit = 80,
  overscroll_resistance = 0.35,
  spring_stiffness = 150,
  spring_damping = 15,
  inertia_damping = 5.5,
  max_velocity = 1450,
})

function on_pointer_pressed(y, frame)
  scroll.begin_drag(stats_scroll, y, { frame = frame })
end

function on_pointer_moved(y, frame)
  local changed = scroll.drag_to(stats_scroll, y, { frame = frame })
  if changed then
    redraw_stats(stats_scroll.offset)
  end
end

function on_pointer_released()
  scroll.end_drag(stats_scroll)
end

function on_mouse_wheel(direction)
  local changed = scroll.apply_wheel(stats_scroll, direction)
  if changed then
    redraw_stats(stats_scroll.offset)
  end
end

function update(dt)
  local changed = scroll.update(stats_scroll, dt)
  if changed then
    redraw_stats(stats_scroll.offset)
  end
end
```

Use `scroll.layout` when a fixed pool of GUI row nodes should represent a longer list without a visible row pop:

```lua
local layout = scroll.layout({
  offset = stats_scroll.offset,
  item_count = #items,
  slot_count = #row_nodes,
  row_spacing = 132,
  top = 291,
  min_y = -342,
  max_y = 342,
  slot_half_height = 63,
})

stats_scroll.max = layout.max_offset
for _, row in ipairs(layout.slots) do
  local item = row.visible and row.item_index and items[row.item_index]
  position_row(row.slot_index, row.y, item)
end
```

Map mouse-wheel or platform scroll events to `"up"` and `"down"` in the consuming project. The helper intentionally does not know about Defold GUI node ids, CSS-style scrollbars, touch areas, or visual style.

## Local Leaderboard Adapter

`defold_helper.local_leaderboard` owns small local leaderboard operations: row normalization, score/time sorting, run insertion, best-score promotion, limited row copying, and compact `MM:SS` display formatting.

Keep game-specific labels and character names in a project adapter:

```lua
local leaderboard = require("defold_helper.local_leaderboard")

local M = {}

function M.record_run(rows, run)
  return leaderboard.record_run(rows, run, {
    limit = 10,
    default_character_id = "classic",
  })
end

function M.format_rows(rows)
  return leaderboard.format_rows(rows, {
    limit = 5,
    empty_text = "No runs yet",
    character_name = function(character_id)
      return character_id
    end,
  })
end

return M
```

The helper does not persist leaderboard rows or own player identity. Save files, character display names, remote leaderboard sync, and GUI node binding stay in the consuming project.

The helper modules should not depend on a specific game name, score unit, GUI file, leaderboard backend, character catalog, or advertising provider.

-- Shared pointer arbitration and press-to-release taps for Defold UI.
--
-- A single physical touch can reach a Defold script twice: once through a
-- MOUSE_BUTTON_1 binding and once through TOUCH_MULTI, and mobile browsers add
-- compatibility mouse events after a touch ends. The gate below lets exactly one
-- source own each gesture. The tap tracker activates a target only when the
-- pointer is released over the same target it pressed, which is how platform
-- buttons behave and what keeps a held or repeated touch from reaching a popup
-- that opened underneath the finger.
local M = {}

M.TOUCH = "touch"
M.MOUSE = "mouse"
M.PRESSED = "pressed"
M.HELD = "held"
M.RELEASED = "released"
M.OUTSIDE = "outside"

local DEFAULT_ECHO_WINDOW = 1.0

local SOURCES = { [M.TOUCH] = true, [M.MOUSE] = true }
local PHASES = { [M.PRESSED] = true, [M.HELD] = true, [M.RELEASED] = true }

-- Converts Defold action flags into one phase. A held frame with a zero value
-- is a release reported without its flag by some platforms.
function M.phase(pressed, released, value)
  if pressed == true and released ~= true then return M.PRESSED end
  if released == true or (pressed ~= true and value ~= nil and value <= 0) then return M.RELEASED end
  return M.HELD
end

function M.gate(options)
  options = options or {}
  local echo_window = options.echo_window == nil and DEFAULT_ECHO_WINDOW or options.echo_window
  assert(type(echo_window) == "number" and echo_window >= 0, "echo_window must be a non-negative number")
  return {
    touch_only = options.touch_only == true,
    echo_window = echo_window,
    owner = nil,
    last_touch_time = nil,
  }
end

-- Returns true when this event belongs to the gesture the caller should handle.
-- `now` must come from one monotonic clock for the whole session.
function M.accept(gate, source, phase, now)
  assert(type(gate) == "table", "a gate created by tap_input.gate is required")
  assert(SOURCES[source], "unknown pointer source: " .. tostring(source))
  assert(PHASES[phase], "unknown pointer phase: " .. tostring(phase))
  assert(type(now) == "number", "a monotonic time is required")
  if source == M.TOUCH then
    gate.last_touch_time = now
  elseif gate.touch_only then
    return false
  elseif gate.last_touch_time and now - gate.last_touch_time <= gate.echo_window then
    -- Compatibility mouse events trail a real touch; they are never a new tap.
    return false
  end
  if gate.owner and gate.owner ~= source then
    return false
  end
  if phase == M.PRESSED then
    gate.owner = source
    return true
  end
  if not gate.owner then
    -- A release or held frame without an accepted press is an echo of a
    -- gesture that already ended (or that the caller ended deliberately).
    return false
  end
  if phase == M.RELEASED then
    gate.owner = nil
  end
  return true
end

function M.owner(gate)
  return gate.owner
end

-- Ends the current gesture without a release event, for example when a
-- browser reports a release that never reached the canvas.
function M.reset(gate)
  gate.owner = nil
end

function M.tap(options)
  options = options or {}
  assert(options.slop == nil or (type(options.slop) == "number" and options.slop >= 0), "slop must be a non-negative number")
  return { slop = options.slop, target = nil, bounds = nil, armed = false, moved = false, x = nil, y = nil }
end

-- Starts a tap. A nil target means the press hit nothing and can never
-- activate, even if the pointer later slides onto a target.
function M.press(tap, target, x, y, bounds)
  assert(type(x) == "number" and type(y) == "number", "press needs numeric coordinates")
  tap.target, tap.bounds = target, bounds
  tap.x, tap.y = x, y
  tap.moved = false
  tap.armed = target ~= nil
  return tap.armed
end

-- Updates the armed state from the target currently under the pointer.
-- Returns true when the armed state changed, so callers can refresh feedback.
function M.move(tap, x, y, target_at_point)
  if tap.target == nil then return false end
  assert(type(x) == "number" and type(y) == "number", "move needs numeric coordinates")
  if tap.slop and not tap.moved and (math.abs(x - tap.x) > tap.slop or math.abs(y - tap.y) > tap.slop) then
    tap.moved = true
  end
  local armed = not tap.moved and target_at_point == tap.target
  local changed = armed ~= tap.armed
  tap.armed = armed
  return changed
end

-- Finishes the tap. Returns the activated target, or nil when the release
-- left the pressed target, moved past the slop or never pressed a target.
function M.release(tap, x, y, target_at_point)
  M.move(tap, x, y, target_at_point)
  local activated = tap.armed and tap.target or nil
  M.cancel(tap)
  return activated
end

function M.cancel(tap)
  tap.target, tap.bounds, tap.armed, tap.moved, tap.x, tap.y = nil, nil, false, false, nil, nil
end

-- Target and bounds that should currently look pressed.
function M.pressed(tap)
  if not tap.armed then return nil, nil end
  return tap.target, tap.bounds
end

function M.active(tap)
  return tap.target ~= nil
end

-- Center-anchored rectangle {x, y, w, h}, matching GUI node pivots.
function M.rect_contains(rect, x, y)
  return rect ~= nil
    and math.abs(x - rect.x) <= rect.w * 0.5
    and math.abs(y - rect.y) <= rect.h * 0.5
end

local function entry_hit(entry, x, y)
  if entry.enabled == false then return false end
  if entry.hit then return entry.hit(x, y) == true end
  if entry.node then
    local gui_api = rawget(_G, "gui")
    assert(gui_api and gui_api.pick_node, "GUI node targets need the Defold gui API")
    return gui_api.is_enabled(entry.node) and gui_api.pick_node(entry.node, x, y)
  end
  assert(entry.rect, "a target needs rect, node or hit: " .. tostring(entry.id))
  return M.rect_contains(entry.rect, x, y)
end

-- Returns the first matching entry id and entry. List entries in priority
-- order (topmost first). With options.modal, a miss returns M.OUTSIDE so a
-- modal can close from a full outside tap while blocking targets beneath it.
function M.target_at(entries, x, y, options)
  for _, entry in ipairs(entries or {}) do
    assert(entry.id ~= nil, "every target needs an id")
    if entry_hit(entry, x, y) then return entry.id, entry end
  end
  if options and options.modal then return M.OUTSIDE, nil end
  return nil, nil
end

return M

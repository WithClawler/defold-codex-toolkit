local assert = require("tests.assert")

local function raises(fn, needle, message)
  local ok, err = pcall(fn)
  assert.equal(ok, false, message)
  assert.contains(tostring(err), needle, message)
end

local function run()
  package.loaded["defold_helper.tap_input"] = nil
  local tap_input = require("defold_helper.tap_input")
  local T, M = tap_input.TOUCH, tap_input.MOUSE
  local P, H, R = tap_input.PRESSED, tap_input.HELD, tap_input.RELEASED

  -- Phase conversion from Defold action flags.
  assert.equal(tap_input.phase(true, false, 1), P, "press flag starts a gesture")
  assert.equal(tap_input.phase(false, false, 1), H, "held frames keep the gesture")
  assert.equal(tap_input.phase(false, true, 0), R, "release flag ends the gesture")
  assert.equal(tap_input.phase(false, false, 0), R, "a zero-valued held frame is a release")
  assert.equal(tap_input.phase(true, true, 0), R, "a same-frame press and release resolves to release")

  -- One physical touch delivered as both touch and emulated mouse.
  local gate = tap_input.gate()
  assert.equal(tap_input.accept(gate, T, P, 1.00), true, "first source owns the gesture")
  assert.equal(tap_input.accept(gate, M, P, 1.00), false, "the emulated mouse press is a duplicate")
  assert.equal(tap_input.accept(gate, M, H, 1.02), false, "duplicate held frames are ignored")
  assert.equal(tap_input.accept(gate, T, H, 1.02), true, "owner held frames are accepted")
  assert.equal(tap_input.accept(gate, M, R, 1.10), false, "duplicate release cannot end the owner gesture")
  assert.equal(tap_input.owner(gate), T, "touch still owns the gesture")
  assert.equal(tap_input.accept(gate, T, R, 1.10), true, "owner release ends the gesture")
  assert.equal(tap_input.owner(gate), nil, "gesture cleared after release")

  -- Browser compatibility mouse events after a touch, even far away and late.
  assert.equal(tap_input.accept(gate, M, P, 1.70), false, "compat mouse press within the echo window is ignored")
  assert.equal(tap_input.accept(gate, M, R, 1.75), false, "compat mouse release within the echo window is ignored")
  assert.equal(tap_input.accept(gate, M, P, 2.20), true, "a real mouse press after the window is accepted")
  assert.equal(tap_input.accept(gate, M, R, 2.25), true, "and its release")

  -- Stray releases or held frames without an accepted press.
  assert.equal(tap_input.accept(gate, M, R, 3.00), false, "a release with no gesture is ignored")
  assert.equal(tap_input.accept(gate, M, H, 3.00), false, "a held frame with no gesture is ignored")

  -- A lost release: the owner presses again and keeps the gesture.
  assert.equal(tap_input.accept(gate, M, P, 4.00), true, "mouse press")
  assert.equal(tap_input.accept(gate, M, P, 4.50), true, "owner re-press restarts a gesture whose release was lost")
  tap_input.reset(gate)
  assert.equal(tap_input.accept(gate, M, R, 4.60), false, "release after an explicit reset is ignored")

  -- Native mobile builds accept touch only.
  local mobile = tap_input.gate({ touch_only = true })
  assert.equal(tap_input.accept(mobile, M, P, 10), false, "touch-only gate rejects emulated mouse even first")
  assert.equal(tap_input.accept(mobile, T, P, 10), true, "touch-only gate accepts touch")
  assert.equal(tap_input.accept(mobile, T, R, 10.1), true, "touch-only release")

  raises(function() tap_input.accept(gate, "pen", P, 1) end, "unknown pointer source", "unknown source fails loudly")
  raises(function() tap_input.accept(gate, T, "down", 1) end, "unknown pointer phase", "unknown phase fails loudly")
  raises(function() tap_input.accept(gate, T, P, nil) end, "monotonic time", "missing clock fails loudly")
  raises(function() tap_input.gate({ echo_window = -1 }) end, "echo_window", "negative echo window fails loudly")

  -- Release-activated taps.
  local tap = tap_input.tap()
  local bounds = { x = 100, y = 100, w = 80, h = 40 }
  assert.equal(tap_input.press(tap, "settings", 100, 100, bounds), true, "press on a target arms it")
  local pressed, pressed_bounds = tap_input.pressed(tap)
  assert.equal(pressed, "settings", "armed target exposed for pressed feedback")
  assert.equal(pressed_bounds, bounds, "armed bounds exposed for pressed feedback")
  assert.equal(tap_input.release(tap, 102, 101, "settings"), "settings", "release over the same target activates")
  assert.equal(tap_input.active(tap), false, "release clears the tap")
  assert.equal(tap_input.pressed(tap), nil, "nothing looks pressed after release")

  tap_input.press(tap, "settings", 100, 100, bounds)
  assert.equal(tap_input.move(tap, 300, 100, nil), true, "leaving the target disarms and reports a change")
  assert.equal(tap_input.pressed(tap), nil, "a disarmed target does not look pressed")
  assert.equal(tap_input.move(tap, 100, 100, "settings"), true, "returning re-arms")
  assert.equal(tap_input.move(tap, 101, 100, "settings"), false, "no change while staying armed")
  assert.equal(tap_input.release(tap, 300, 100, nil), nil, "release away from the target does nothing")

  tap_input.press(tap, "start", 100, 100)
  assert.equal(tap_input.release(tap, 100, 100, "settings"), nil, "release over a different target does nothing")

  assert.equal(tap_input.press(tap, nil, 10, 10), false, "press on nothing is not armed")
  assert.equal(tap_input.move(tap, 100, 100, "settings"), false, "sliding onto a target cannot arm it")
  assert.equal(tap_input.release(tap, 100, 100, "settings"), nil, "a slide-on release never activates")

  local list_tap = tap_input.tap({ slop = 12 })
  tap_input.press(list_tap, "card:2", 50, 50)
  tap_input.move(list_tap, 50, 70, "card:2")
  assert.equal(tap_input.pressed(list_tap), nil, "moving past the slop cancels the tap for scrolling")
  assert.equal(tap_input.move(list_tap, 50, 50, "card:2"), false, "a scroll gesture never re-arms")
  assert.equal(tap_input.release(list_tap, 50, 50, "card:2"), nil, "a scroll gesture never activates")

  tap_input.press(tap, "start", 1, 1)
  tap_input.cancel(tap)
  assert.equal(tap_input.release(tap, 1, 1, "start"), nil, "a cancelled tap cannot activate")
  raises(function() tap_input.press(tap, "start", nil, 1) end, "numeric coordinates", "invalid press coordinates fail loudly")

  -- Target lookup in priority order.
  local targets = {
    { id = "close", rect = { x = 200, y = 300, w = 40, h = 40 } },
    { id = "disabled", enabled = false, rect = { x = 100, y = 100, w = 500, h = 500 } },
    { id = "panel", rect = { x = 150, y = 150, w = 200, h = 400 } },
  }
  assert.equal(tap_input.target_at(targets, 200, 300), "close", "first listed target wins where targets overlap")
  assert.equal(tap_input.target_at(targets, 100, 100), "panel", "disabled targets are skipped")
  assert.equal(tap_input.target_at(targets, 600, 600), nil, "miss returns nil")
  assert.equal(tap_input.target_at(targets, 600, 600, { modal = true }), tap_input.OUTSIDE, "modal miss is an outside tap")
  assert.equal(tap_input.target_at({ { id = "custom", hit = function(x) return x < 0 end } }, -1, 0), "custom", "custom hit functions are supported")
  raises(function() tap_input.target_at({ { rect = targets[1].rect } }, 0, 0) end, "needs an id", "targets without id fail loudly")
  raises(function() tap_input.target_at({ { id = "broken" } }, 0, 0) end, "rect, node or hit", "targets without a hit shape fail loudly")

  local previous_gui = rawget(_G, "gui")
  local node_enabled = true
  _G.gui = {
    is_enabled = function() return node_enabled end,
    pick_node = function(node, x, y) return node == "button" and x == 5 and y == 5 end,
  }
  assert.equal(tap_input.target_at({ { id = "node_button", node = "button" } }, 5, 5), "node_button", "GUI nodes use gui.pick_node")
  node_enabled = false
  assert.equal(tap_input.target_at({ { id = "node_button", node = "button" } }, 5, 5), nil, "disabled GUI nodes are skipped")
  _G.gui = previous_gui
end

return run

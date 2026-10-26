local check = require("tests.assert")
local factory = require("defold_helper.settings_store")

return function()
  local disk, failure = {}, false
  local localization = {
    is_supported=function(locale) return locale == "ko-KR" or locale == "en-US" end,
    detect_locale=function() return "ko-KR" end,
  }
  local api = {
    get_save_file=function(namespace, name) return namespace .. "/" .. name end,
    load=function(path) if failure == "throw" then error("read error") end; return disk[path] end,
    save=function(path, value)
      if failure == "throw" then error("write error") end
      if failure then return false end
      disk[path] = value
      return true
    end,
  }
  local stack = factory.new({namespace="stack", localization=localization, sys=api})
  local tunnel = factory.new({namespace="tunnel", localization=localization, sys=api})
  check.equal(stack.load().sound_enabled, true)
  check.equal(stack.locale(stack.load()), "ko-KR")
  check.equal(stack.save({sound_enabled=false,locale="en-US"}), true)
  check.equal(stack.load().sound_enabled, false)
  check.equal(stack.locale(stack.load()), "en-US")
  check.equal(tunnel.load().sound_enabled, true, "different app namespaces cannot share options")
  check.equal(tunnel.load().locale, nil)
  failure = true
  check.equal(stack.save({sound_enabled=true,locale="ko-KR"}), false)
  check.equal(stack.load().locale, "en-US", "failed persistence leaves durable choices unchanged")
  failure = "throw"
  check.equal(stack.load().sound_enabled, true, "read failures use safe defaults")
  check.equal(stack.save({sound_enabled=true}), false)
  failure = false
  disk["stack/game_settings"] = {sound_enabled="false",locale="invalid"}
  check.equal(stack.load().sound_enabled, true)
  check.equal(stack.load().locale, nil)
end

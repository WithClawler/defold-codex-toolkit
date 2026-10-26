local M = {}

function M.new(options)
  options = options or {}
  local localization = assert(options.localization, "A localization catalog is required")
  local namespace = assert(options.namespace, "A save namespace is required")
  local file_name = options.file_name or "game_settings"
  local store = {}

  local function normalize(value)
    value = type(value) == "table" and value or {}
    return {
      sound_enabled = type(value.sound_enabled) ~= "boolean" or value.sound_enabled,
      locale = localization.is_supported(value.locale) and value.locale or nil,
    }
  end

  function store.load(api)
    api = api or options.sys or rawget(_G, "sys")
    if not api or not api.get_save_file or not api.load then return normalize() end
    local ok, value = pcall(function() return api.load(api.get_save_file(namespace, file_name)) end)
    return normalize(ok and value or nil)
  end

  function store.save(value, api)
    api = api or options.sys or rawget(_G, "sys")
    if not api or not api.get_save_file or not api.save then return false end
    local ok, saved = pcall(function()
      return api.save(api.get_save_file(namespace, file_name), normalize(value))
    end)
    return ok and saved == true
  end

  function store.locale(value, api, html5_api)
    return value.locale or localization.detect_locale(api, html5_api)
  end

  return store
end

return M

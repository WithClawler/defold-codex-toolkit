-- Catalog-based localization; the existing CSV localization API remains independent.
local M = {}

function M.new(data, options)
  data, options = data or {}, options or {}
  local catalog = {}
  local locales, fonts, copy = data.locales or {}, data.fonts or {}, data.copy or {}
  local by_id, by_language, font_text = {}, {}, {}
  local default_locale = options.default_locale or data.default_locale or "en-US"
  for _, entry in ipairs(locales) do
    by_id[entry.id] = entry
    by_language[entry.id:match("^[^-]+")]=entry.id
  end
  assert(by_id[default_locale], "The default locale must be present in the catalog")
  assert(type(copy[default_locale]) == "table", "The default locale must have an explicit copy table")

  function catalog.normalize_locale(value)
    local locale = tostring(value or ""):lower():gsub("_", "-")
    if locale == "zh" or locale:match("^zh%-") then
      local selected = locale:find("hant", 1, true) or locale:match("^zh%-[thm][wko]")
      selected = selected and "zh-TW" or "zh-CN"
      return by_id[selected] and selected or default_locale
    end
    local language = locale:match("^[^-]+") or ""
    if language == "no" or language == "nn" then language = "nb" end
    if language == "in" then language = "id" end
    return by_language[language] or default_locale
  end

  function catalog.is_supported(locale)
    return type(locale) == "string" and by_id[locale] ~= nil
  end

  function catalog.info(locale)
    return by_id[catalog.normalize_locale(locale)]
  end

  function catalog.locales() return locales end
  function catalog.fonts() return fonts end

  function catalog.policy_url(locale)
    local selected = catalog.normalize_locale(locale)
    if type(options.policy_url) == "function" then return options.policy_url(selected) end
    return options.policy_url
  end

  function catalog.font_text(font_id)
    if not font_text[font_id] then
      local ascii = {}
      for code = 32, 126 do ascii[#ascii + 1] = string.char(code) end
      local values = { table.concat(ascii), options.dynamic_text or "" }
      for _, entry in ipairs(locales) do
        if entry.font == font_id then
          values[#values + 1] = entry.name
          for _, text in pairs(copy[entry.id] or {}) do values[#values + 1] = text end
        end
      end
      font_text[font_id] = table.concat(values, "\n")
    end
    return font_text[font_id]
  end

  function catalog.detect_locale(sys_api, html5_api)
    if html5_api and type(html5_api.run) == "function" then
      local ok, override = pcall(html5_api.run, [[
(function() {
  return new URLSearchParams(window.location.search).get("lang") || "";
})();
]])
      if ok and override ~= nil and override ~= "" then return catalog.normalize_locale(override) end
    end
    if sys_api and type(sys_api.get_sys_info) == "function" then
      local ok, info = pcall(sys_api.get_sys_info)
      if ok and type(info) == "table" then
        local requested = info.device_language
        if type(requested) ~= "string" or requested == "" then requested = info.locale end
        if type(requested) ~= "string" or requested == "" then requested = info.language end
        local normalized = tostring(requested or ""):lower():gsub("_", "-")
        if normalized == "zh" then
          local territory = tostring(info.territory or ""):upper()
          if territory == "TW" or territory == "HK" or territory == "MO" then requested = "zh-" .. territory end
        end
        return catalog.normalize_locale(requested)
      end
    end
    return default_locale
  end

  function catalog.copy(locale)
    return copy[catalog.normalize_locale(locale)] or copy[default_locale]
  end

  function catalog.text(locale, key)
    return catalog.copy(locale)[key] or copy[default_locale][key] or tostring(key or "")
  end

  function catalog.supported_locales()
    local result = {}
    for _, entry in ipairs(locales) do result[#result + 1] = entry.id end
    return result
  end

  return catalog
end

return M

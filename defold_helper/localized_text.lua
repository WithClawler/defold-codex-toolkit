local M = {}

function M.new(localization)
  assert(localization, "A localization catalog is required")
  local text = {}
  local current_locale = localization.normalize_locale(nil)
  local ready, pending = {}, {}
  local tokens = setmetatable({}, { __mode = "k" })

  function text.set_locale(locale)
    current_locale = localization.normalize_locale(locale)
  end

  local function runtime_api()
    local api = rawget(_G, "font")
    if api and type(api.prewarm_text) == "function" then return api end
  end

  function text.prepare(locale, callback)
    local info = localization.info(locale)
    local id, api = info.font, runtime_api()
    if not api or ready[id] then callback(); return end
    if pending[id] then pending[id][#pending[id] + 1] = callback; return end
    pending[id] = { callback }
    local spec = localization.fonts()[id]
    for _, fallback in ipairs(spec.fallbacks or {}) do
      api.add_font(hash(spec.resource), hash(localization.fonts()[fallback].ttf))
    end
    api.prewarm_text(hash(spec.resource), localization.font_text(id), function(_, _, success, error_text)
      local callbacks = pending[id]
      pending[id] = nil
      if not success then error("Unable to prepare localized font " .. id .. ": " .. tostring(error_text)) end
      ready[id] = true
      for _, run in ipairs(callbacks) do run() end
    end)
  end

  function text.set(node, value, after, locale)
    local selected = locale or current_locale
    local value_text = tostring(value or "")
    tokens[node] = (tokens[node] or 0) + 1
    local token = tokens[node]
    -- Screen visibility remains owned by the consumer, including during font preparation.
    if runtime_api() and not ready[localization.info(selected).font] then gui.set_text(node, "") end
    text.prepare(selected, function()
      if tokens[node] ~= token then return end
      local spec = localization.fonts()[localization.info(selected).font]
      if type(gui.set_font) == "function" then gui.set_font(node, spec.name) end
      gui.set_text(node, value_text)
      if after then after(node) end
    end)
  end

  function text.fit(node, max_width, base, minimum)
    local resource_api = rawget(_G, "resource")
    local fitted = base
    if resource_api and resource_api.get_text_metrics and gui.get_font_resource and gui.get_text then
      local ok, metrics = pcall(function()
        return resource_api.get_text_metrics(gui.get_font_resource(gui.get_font(node)), gui.get_text(node))
      end)
      if ok and metrics and metrics.width and metrics.width * base > max_width then
        fitted = math.max(minimum, max_width / metrics.width)
      end
    end
    gui.set_scale(node, vmath.vector3(fitted, fitted, 1))
  end

  return text
end

return M

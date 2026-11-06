local M = {}

function M.new(localization, options)
  assert(localization, "A localization catalog is required")
  options = options or {}
  local text = {}
local locale = localization.normalize_locale(nil)
local ready, pending, attached = {}, {}, {}
local tokens = setmetatable({}, { __mode = "k" })
local fallback_characters = {}
for codepoint = 32, 126 do fallback_characters[#fallback_characters + 1] = string.char(codepoint) end
-- Consumers can extend the fallback inventory for their fonts.
local fallback_text = options.fallback_text or table.concat(fallback_characters)

local function runtime_api()
  local api = rawget(_G, "font")
  if api and type(api.prewarm_text) == "function" then return api end
end

function text.set_locale(value)
  locale = localization.normalize_locale(value)
end

function text.prepare(selected, callback)
  local id = localization.info(selected).font
  local api = runtime_api()
  local spec = localization.fonts()[id]
  if spec.runtime == false or not api or ready[id] then callback(); return end
  if pending[id] then pending[id][#pending[id] + 1] = callback; return end
  pending[id] = { callback }
  local resource = hash(spec.resource)
  local value = localization.font_text(id)
  local function complete(_, _, success, error_text)
    local callbacks = pending[id]
    pending[id] = nil
    if not success then error("Unable to prepare localized font " .. id .. ": " .. tostring(error_text)) end
    ready[id] = true
    for _, run in ipairs(callbacks) do run() end
  end
  -- Defold 1.14.0 deduplicates a prewarm job by glyph index, without its font.
  -- Warm the primary face before adding Latin: otherwise equal indices in the
  -- fallback face suppress primary glyphs even though the callback succeeds.
  api.prewarm_text(resource, value, function(self, request, success, error_text)
    if not success then complete(self, request, success, error_text); return end
    if #(spec.fallbacks or {}) == 0 then complete(self, request, success); return end
    if not attached[id] then
      for _, fallback in ipairs(spec.fallbacks) do
        api.add_font(resource, hash(localization.fonts()[fallback].ttf))
      end
      attached[id] = true
    end
    -- Prewarm just the fallback inventory. Repeating the native catalog here
    -- regenerates it on 1.14.0, whose cache check only sees drawn GPU glyphs.
    api.prewarm_text(resource, fallback_text, complete)
  end)
end

function text.set(node, value, after, selected)
  selected = selected or locale
  value = tostring(value or "")
  tokens[node] = (tokens[node] or 0) + 1
  local token = tokens[node]
  local id = localization.info(selected).font
  if localization.fonts()[id].runtime ~= false and runtime_api() and not ready[id] then gui.set_text(node, "") end
  text.prepare(selected, function()
    if tokens[node] ~= token then return end
    local spec = localization.fonts()[localization.info(selected).font]
    if type(gui.set_font) == "function" then gui.set_font(node, spec.name) end
    gui.set_text(node, value)
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

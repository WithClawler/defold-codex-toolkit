local M = {}

local function number_or(value, fallback)
  local number = tonumber(value)
  if number == nil or number ~= number then
    return fallback
  end
  return number
end

local function clamp(value, minimum, maximum)
  value = number_or(value, minimum)
  if value < minimum then
    return minimum
  end
  if value > maximum then
    return maximum
  end
  return value
end

local function channel(color, name, vector_name, index, fallback)
  if type(color) ~= "table" then
    return fallback
  end
  local value = color[name]
  if value == nil then
    value = color[vector_name]
  end
  if value == nil then
    value = color[index]
  end
  return value == nil and fallback or value
end

local function byte(value)
  return math.floor(clamp(value, 0, 1) * 255 + 0.5)
end

function M.rgba(red, green, blue, alpha)
  return {
    r = clamp(red, 0, 1),
    g = clamp(green, 0, 1),
    b = clamp(blue, 0, 1),
    a = clamp(alpha == nil and 1 or alpha, 0, 1),
  }
end

function M.rgb(red, green, blue)
  return M.rgba(red, green, blue, 1)
end

function M.from_rgba8(red, green, blue, alpha)
  return M.rgba(
    number_or(red, 0) / 255,
    number_or(green, 0) / 255,
    number_or(blue, 0) / 255,
    number_or(alpha, 255) / 255
  )
end

function M.normalize(color)
  return M.rgba(
    channel(color, "r", "x", 1, 0),
    channel(color, "g", "y", 2, 0),
    channel(color, "b", "z", 3, 0),
    channel(color, "a", "w", 4, 1)
  )
end

function M.white(alpha)
  return M.rgba(1, 1, 1, alpha)
end

function M.black(alpha)
  return M.rgba(0, 0, 0, alpha)
end

function M.from_hex(value, alpha)
  local hex = tostring(value or "")
  hex = string.gsub(hex, "^%s+", "")
  hex = string.gsub(hex, "%s+$", "")
  hex = string.gsub(hex, "^#", "")
  hex = string.gsub(hex, "^0[xX]", "")

  if not string.match(hex, "^[%x]+$") then
    error("invalid hex color: " .. tostring(value), 2)
  end

  if #hex == 3 or #hex == 4 then
    hex = string.gsub(hex, ".", function(character)
      return character .. character
    end)
  end

  if #hex ~= 6 and #hex ~= 8 then
    error("hex color must use RGB, RGBA, RRGGBB, or RRGGBBAA", 2)
  end

  local red = tonumber(string.sub(hex, 1, 2), 16)
  local green = tonumber(string.sub(hex, 3, 4), 16)
  local blue = tonumber(string.sub(hex, 5, 6), 16)
  local embedded_alpha = #hex == 8 and tonumber(string.sub(hex, 7, 8), 16) or 255
  local color = M.from_rgba8(red, green, blue, embedded_alpha)
  if alpha ~= nil then
    color.a = clamp(alpha, 0, 1)
  end
  return color
end

function M.to_hex(color, include_alpha)
  color = M.normalize(color)
  if include_alpha == nil then
    include_alpha = color.a < 1
  end

  local result = string.format("#%02X%02X%02X", byte(color.r), byte(color.g), byte(color.b))
  if include_alpha then
    result = result .. string.format("%02X", byte(color.a))
  end
  return result
end

function M.to_vector4(color, vmath_api)
  local api = vmath_api or rawget(_G, "vmath")
  if type(api) ~= "table" or type(api.vector4) ~= "function" then
    error("to_vector4 requires vmath.vector4 or an injected vmath API", 2)
  end
  color = M.normalize(color)
  return api.vector4(color.r, color.g, color.b, color.a)
end

function M.lerp(from_color, to_color, amount)
  local from = M.normalize(from_color)
  local to = M.normalize(to_color)
  local t = clamp(amount, 0, 1)
  return M.rgba(
    from.r + (to.r - from.r) * t,
    from.g + (to.g - from.g) * t,
    from.b + (to.b - from.b) * t,
    from.a + (to.a - from.a) * t
  )
end

function M.rgb_to_hsl(color)
  color = M.normalize(color)
  local maximum = math.max(color.r, color.g, color.b)
  local minimum = math.min(color.r, color.g, color.b)
  local delta = maximum - minimum
  local lightness = (maximum + minimum) / 2

  if delta == 0 then
    return 0, 0, lightness
  end

  local saturation = delta / (1 - math.abs(2 * lightness - 1))
  local hue
  if maximum == color.r then
    hue = ((color.g - color.b) / delta) % 6
  elseif maximum == color.g then
    hue = ((color.b - color.r) / delta) + 2
  else
    hue = ((color.r - color.g) / delta) + 4
  end
  hue = (hue / 6) % 1
  return hue, saturation, lightness
end

local function hue_channel(first, second, hue)
  if hue < 0 then
    hue = hue + 1
  elseif hue > 1 then
    hue = hue - 1
  end
  if hue < 1 / 6 then
    return first + (second - first) * 6 * hue
  end
  if hue < 1 / 2 then
    return second
  end
  if hue < 2 / 3 then
    return first + (second - first) * (2 / 3 - hue) * 6
  end
  return first
end

function M.from_hsl(hue, saturation, lightness, alpha)
  hue = number_or(hue, 0) % 1
  saturation = clamp(saturation, 0, 1)
  lightness = clamp(lightness, 0, 1)

  if saturation == 0 then
    return M.rgba(lightness, lightness, lightness, alpha)
  end

  local second
  if lightness < 0.5 then
    second = lightness * (1 + saturation)
  else
    second = lightness + saturation - lightness * saturation
  end
  local first = 2 * lightness - second
  return M.rgba(
    hue_channel(first, second, hue + 1 / 3),
    hue_channel(first, second, hue),
    hue_channel(first, second, hue - 1 / 3),
    alpha
  )
end

function M.adjust_hsl(color, adjustments)
  color = M.normalize(color)
  adjustments = type(adjustments) == "table" and adjustments or {}
  local hue, saturation, lightness = M.rgb_to_hsl(color)
  return M.from_hsl(
    hue + number_or(adjustments.hue or adjustments.h, 0),
    saturation + number_or(adjustments.saturation or adjustments.s, 0),
    lightness + number_or(adjustments.lightness or adjustments.l, 0),
    color.a
  )
end

function M.spread(color, amount)
  color = M.normalize(color)
  amount = clamp(amount, 0, 1)
  return {
    darker = M.adjust_hsl(color, { lightness = -amount }),
    lighter = M.adjust_hsl(color, { lightness = amount }),
  }
end

-- WCAG 2.2 relative luminance conversion for normalized sRGB channels.
local function linear_channel(value)
  if value <= 0.04045 then
    return value / 12.92
  end
  return ((value + 0.055) / 1.055) ^ 2.4
end

function M.relative_luminance(color)
  color = M.normalize(color)
  return 0.2126 * linear_channel(color.r)
    + 0.7152 * linear_channel(color.g)
    + 0.0722 * linear_channel(color.b)
end

function M.contrast_ratio(first_color, second_color)
  local first = M.relative_luminance(first_color)
  local second = M.relative_luminance(second_color)
  if first < second then
    first, second = second, first
  end
  return (first + 0.05) / (second + 0.05)
end

function M.passes_contrast(ratio, level, large_text)
  ratio = number_or(ratio, 0)
  level = string.upper(tostring(level or "AA"))
  if level == "AAA" then
    return ratio >= (large_text and 4.5 or 7)
  end
  if level == "AA" then
    return ratio >= (large_text and 3 or 4.5)
  end
  error("contrast level must be AA or AAA", 2)
end

function M.best_contrast(background, first_candidate, second_candidate)
  local first = M.normalize(first_candidate or M.black())
  local second = M.normalize(second_candidate or M.white())
  local first_ratio = M.contrast_ratio(background, first)
  local second_ratio = M.contrast_ratio(background, second)
  if first_ratio >= second_ratio then
    return first, first_ratio
  end
  return second, second_ratio
end

function M.is_dark(color)
  local best = M.best_contrast(color, M.black(), M.white())
  return best.r == 1 and best.g == 1 and best.b == 1
end

return M

local assert = require("tests.assert")

local function near(actual, expected, tolerance, message)
  tolerance = tolerance or 0.000001
  if math.abs(actual - expected) > tolerance then
    error(message or string.format("expected %.8f, got %.8f", expected, actual), 2)
  end
end

local function run()
  package.loaded["defold_helper.color_utils"] = nil
  local color = require("defold_helper.color_utils")

  local clamped = color.rgba(-1, 0.5, 2, 3)
  assert.equal(clamped.r, 0, "rgba should clamp red")
  assert.equal(clamped.g, 0.5, "rgba should preserve normalized green")
  assert.equal(clamped.b, 1, "rgba should clamp blue")
  assert.equal(clamped.a, 1, "rgba should clamp alpha")

  local orange = color.from_hex("#F80")
  assert.equal(color.to_hex(orange), "#FF8800", "short hex should expand to normalized RGB")
  assert.equal(color.to_hex(color.from_hex("33669980")), "#33669980", "hex alpha should round-trip")
  assert.equal(color.to_hex(color.from_hex("#336699", 0.25), true), "#33669940", "explicit alpha should override hex alpha")

  local invalid_ok = pcall(color.from_hex, "#12")
  assert.equal(invalid_ok, false, "invalid hex lengths should fail")

  local vector = color.to_vector4(color.from_rgba8(255, 128, 0, 128), {
    vector4 = function(red, green, blue, alpha)
      return { red, green, blue, alpha }
    end,
  })
  near(vector[1], 1)
  near(vector[2], 128 / 255)
  near(vector[3], 0)
  near(vector[4], 128 / 255)

  local midpoint = color.lerp(color.black(0), color.white(1), 0.5)
  near(midpoint.r, 0.5)
  near(midpoint.a, 0.5)

  local source = color.from_hex("#2E86DE")
  local hue, saturation, lightness = color.rgb_to_hsl(source)
  local round_trip = color.from_hsl(hue, saturation, lightness, source.a)
  near(round_trip.r, source.r)
  near(round_trip.g, source.g)
  near(round_trip.b, source.b)

  local spread = color.spread(source, 0.15)
  assert.equal(color.relative_luminance(spread.darker) < color.relative_luminance(source), true, "spread should create a darker color")
  assert.equal(color.relative_luminance(spread.lighter) > color.relative_luminance(source), true, "spread should create a lighter color")

  near(color.contrast_ratio(color.black(), color.white()), 21, 0.000001, "black and white should have maximum WCAG contrast")
  assert.equal(color.passes_contrast(4.5, "AA", false), true, "AA normal text should pass at 4.5")
  assert.equal(color.passes_contrast(4.49, "AA", false), false, "AA normal text should fail below 4.5")
  assert.equal(color.passes_contrast(4.5, "AAA", true), true, "AAA large text should pass at 4.5")

  local best, ratio = color.best_contrast(color.from_hex("#101820"))
  assert.equal(color.to_hex(best), "#FFFFFF", "dark backgrounds should choose white by default")
  assert.equal(ratio > 4.5, true, "best contrast should return its ratio")
  assert.equal(color.is_dark(color.from_hex("#101820")), true, "dark colors should be detected")
  assert.equal(color.is_dark(color.from_hex("#F5F5F5")), false, "light colors should be detected")

  local vector_like = color.normalize({ x = 0.1, y = 0.2, z = 0.3, w = 0.4 })
  near(vector_like.r, 0.1)
  near(vector_like.a, 0.4)
end

return run

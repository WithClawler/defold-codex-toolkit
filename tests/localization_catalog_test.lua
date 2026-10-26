local check = require("tests.assert")
local factory = require("defold_helper.localization_catalog")

return function()
  local data = {
    locales = {
      {id="en-US",name="English",font="latin"},
      {id="ko-KR",name="한국어",font="ko"},
      {id="zh-CN",name="简体中文",font="sc"},
      {id="zh-TW",name="繁體中文",font="tc"},
      {id="nb-NO",name="Norsk bokmål",font="latin"},
      {id="id-ID",name="Bahasa Indonesia",font="latin"},
    },
    fonts = {},
    copy = {["en-US"]={title="Play",fallback="Fallback"},["ko-KR"]={title="시작"}},
  }
  local catalog = factory.new(data, {policy_url=function(locale) return "https://game.example/" .. locale end})
  check.equal(catalog.normalize_locale("KO_kr"), "ko-KR")
  check.equal(catalog.normalize_locale("zh-Hant-HK"), "zh-TW")
  check.equal(catalog.normalize_locale("zh-MO"), "zh-TW")
  check.equal(catalog.normalize_locale("zh-Hans"), "zh-CN")
  check.equal(catalog.normalize_locale("no-NO"), "nb-NO")
  check.equal(catalog.normalize_locale("in-ID"), "id-ID")
  check.equal(catalog.normalize_locale("unknown"), "en-US")
  check.equal(catalog.text("ko", "title"), "시작")
  check.equal(catalog.text("ko", "fallback"), "Fallback")
  check.equal(catalog.text("ko", "missing"), "missing")
  check.equal(catalog.is_supported("ko"), false, "save validation accepts canonical IDs only")
  check.equal(catalog.policy_url("ko"), "https://game.example/ko-KR")
  check.equal(catalog.detect_locale({get_sys_info=function() return {device_language="ko",language="en"} end}), "ko-KR")
  check.equal(catalog.detect_locale({get_sys_info=function() return {language="zh",territory="HK"} end}), "zh-TW")
  check.equal(catalog.detect_locale(nil, {run=function() return "nb" end}), "nb-NO")
  check.equal(catalog.detect_locale({get_sys_info=function() error("unsupported") end}), "en-US")
  check.contains(catalog.font_text("ko"), "시작")
  check.contains(catalog.font_text("ko"), "한국어")
  for code = 32, 126 do check.contains(catalog.font_text("ko"), string.char(code)) end
  local second = factory.new({locales={{id="en-US",name="English",font="latin"}},copy={["en-US"]={title="Other"}}})
  check.equal(second.text("ko", "title"), "Other", "catalog factories cannot share game copy")
  check.equal(second.policy_url("en"), nil, "apps without a policy action do not inherit another game's URL")
  check.equal(#catalog.supported_locales(), 6)
  check.equal(#second.supported_locales(), 1)
end

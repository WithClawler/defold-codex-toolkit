local assert = require("tests.assert")

local function run()
  package.loaded["defold_helper.string_utils"] = nil
  local string_utils = require("defold_helper.string_utils")

  assert.equal(string_utils.trim("  Defold \n"), "Defold", "trim should remove surrounding whitespace")
  assert.equal(string_utils.is_blank(" \t\n"), true, "is_blank should detect whitespace-only strings")
  assert.equal(string_utils.starts_with("defold_helper.color_utils", "defold_helper"), true, "starts_with should match prefixes")
  assert.equal(string_utils.starts_with("defold", "fold"), false, "starts_with should reject non-prefixes")
  assert.equal(string_utils.ends_with("main.collectionc", ".collectionc"), true, "ends_with should match suffixes")
  assert.equal(string_utils.ends_with("main.collection", ".collectionc"), false, "ends_with should reject non-suffixes")

  assert.equal(string_utils.join_path("assets", "ui", "button.png"), "assets/ui/button.png", "join_path should join multiple segments")
  assert.equal(string_utils.join_path("assets/", "/ui/", "/button.png"), "assets/ui/button.png", "join_path should collapse boundary slashes")
  assert.equal(string_utils.join_path("https://example.com/", "/games/demo"), "https://example.com/games/demo", "join_path should preserve URL schemes")
  assert.equal(string_utils.join_path("/", "assets"), "/assets", "join_path should preserve a root slash")
  assert.equal(string_utils.join_path(nil, "", "assets"), "assets", "join_path should skip empty segments")
end

return run

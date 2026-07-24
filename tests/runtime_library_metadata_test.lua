local assert = require("tests.assert")

local function read_file(path)
  local handle = io.open(path, "r")
  if not handle then
    return ""
  end
  local content = handle:read("*a")
  handle:close()
  return content
end

local function run()
  local game_project = read_file("game.project")
  assert.contains(game_project, "[library]", "helper repo should declare Defold library metadata")
  assert.contains(game_project, "include_dirs = defold_helper", "library metadata should expose only the defold_helper namespace")

  local plugin_manifest = read_file(".codex-plugin/plugin.json")
  local project_version = string.match(game_project, "version%s*=%s*([%w%.%-]+)")
  local plugin_version = string.match(plugin_manifest, "\"version\"%s*:%s*\"([^\"]+)\"")
  assert.equal(project_version, plugin_version, "Defold library and Codex plugin versions should match")

  local docs = read_file("docs/runtime-library.md")
  assert.contains(docs, "require(\"defold_helper.score_records\")", "adoption docs should show score_records require path")
  assert.contains(docs, "require(\"defold_helper.localization\")", "adoption docs should show localization require path")
  assert.contains(docs, "require(\"defold_helper.privacy_modal\")", "adoption docs should show privacy_modal require path")
  assert.contains(docs, "require(\"defold_helper.scroll\")", "adoption docs should show scroll require path")
  assert.contains(docs, "require(\"defold_helper.color_utils\")", "adoption docs should show color_utils require path")
  assert.contains(docs, "require(\"defold_helper.table_utils\")", "adoption docs should show table_utils require path")
  assert.contains(docs, "require(\"defold_helper.string_utils\")", "adoption docs should show string_utils require path")
  assert.contains(docs, "key,ko-KR,en,ja-JP", "adoption docs should document csv localization table shape")
  assert.contains(docs, "localization.default_languages()", "adoption docs should document the shared default locale list")
  assert.contains(docs, "localization.default_language_variations()", "adoption docs should document the shared language selector variations")
  assert.contains(docs, "localization.language_display_name(\"ko\")", "adoption docs should document fixed native language names")
  assert.contains(docs, "privacy_modal.tap_action", "adoption docs should document privacy modal action routing")
  assert.contains(docs, "scroll.apply_wheel", "adoption docs should document wheel scrolling")
  assert.contains(docs, "scroll.update", "adoption docs should document inertial scroll updates")
  assert.contains(docs, "scroll.layout", "adoption docs should document reusable row layout")
  assert.contains(docs, "color_utils.best_contrast", "adoption docs should document WCAG-oriented color selection")
  assert.contains(docs, "table_utils.sorted_pairs", "adoption docs should document deterministic table iteration")
  assert.contains(docs, "string_utils.join_path", "adoption docs should document path joining")
  assert.contains(docs, "dependencies", "adoption docs should document Defold dependency configuration")

  local conventions = read_file("skills/defold-project-conventions/SKILL.md")
  assert.contains(conventions, "references/runtime-ai-qa.md", "project conventions should route built-product QA to its runtime contract")

  local runtime_qa = read_file("skills/defold-project-conventions/references/runtime-ai-qa.md")
  assert.contains(runtime_qa, "built Defold game", "runtime QA contract should target the built product")
  assert.contains(runtime_qa, "same action/message path", "runtime QA input should use the real player path")
  assert.contains(runtime_qa, "Release/Store bundle", "runtime QA contract should require release exclusion")
  assert.contains(runtime_qa, "Computer Use", "runtime QA contract should preserve visual black-box checks")
end

return run

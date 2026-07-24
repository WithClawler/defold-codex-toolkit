local assert = require("tests.assert")

local function run()
  package.loaded["defold_helper.table_utils"] = nil
  local table_utils = require("defold_helper.table_utils")

  local first = { a = 1, shared = "first" }
  local second = { b = 2, shared = "second" }
  local merged = table_utils.merge(first, nil, second)
  assert.equal(merged.a, 1, "merge should keep earlier unique keys")
  assert.equal(merged.b, 2, "merge should include later unique keys")
  assert.equal(merged.shared, "second", "merge should let later tables win")
  merged.a = 9
  assert.equal(first.a, 1, "merge should not mutate its sources")

  local mapped = table_utils.map_values({ a = 2, b = 3 }, function(value, key)
    return key .. tostring(value * 2)
  end)
  assert.equal(mapped.a, "a4", "map_values should pass values and keys")
  assert.equal(mapped.b, "b6", "map_values should preserve keys")

  local ordered = table_utils.sorted_keys({ z = 1, a = 2, m = 3 })
  assert.equal(table.concat(ordered, ","), "a,m,z", "sorted_keys should sort comparable keys")

  local descending = {}
  for key, value in table_utils.sorted_pairs({ a = 1, c = 3, b = 2 }, function(left, right)
    return left > right
  end) do
    descending[#descending + 1] = key .. value
  end
  assert.equal(table.concat(descending, ","), "c3,b2,a1", "sorted_pairs should honor a custom comparator")

  local mixed = table_utils.sorted_keys({ [2] = true, [1] = true, b = true, a = true })
  assert.equal(tostring(mixed[1]) .. "," .. tostring(mixed[2]) .. "," .. tostring(mixed[3]) .. "," .. tostring(mixed[4]), "1,2,a,b", "default sorting should handle number and string keys deterministically")

  local invalid_ok = pcall(table_utils.map_values, {}, "not a function")
  assert.equal(invalid_ok, false, "map_values should reject invalid mappers")
end

return run

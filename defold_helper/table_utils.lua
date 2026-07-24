local M = {}

local TYPE_ORDER = {
  number = 1,
  string = 2,
  boolean = 3,
}

local function table_or_empty(value, argument_name)
  if value == nil then
    return {}
  end
  if type(value) ~= "table" then
    error((argument_name or "value") .. " must be a table", 3)
  end
  return value
end

local function default_less(left, right)
  local left_type = type(left)
  local right_type = type(right)
  local left_order = TYPE_ORDER[left_type] or 4
  local right_order = TYPE_ORDER[right_type] or 4
  if left_order ~= right_order then
    return left_order < right_order
  end
  if left_type == "number" or left_type == "string" then
    return left < right
  end
  if left_type == "boolean" then
    return left == false and right == true
  end
  return tostring(left) < tostring(right)
end

function M.shallow_copy(source)
  source = table_or_empty(source, "source")
  local copy = {}
  for key, value in pairs(source) do
    copy[key] = value
  end
  return copy
end

function M.merge(...)
  local result = {}
  for index = 1, select("#", ...) do
    local source = table_or_empty(select(index, ...), "merge source")
    for key, value in pairs(source) do
      result[key] = value
    end
  end
  return result
end

function M.map_values(source, mapper)
  source = table_or_empty(source, "source")
  if type(mapper) ~= "function" then
    error("mapper must be a function", 2)
  end
  local result = {}
  for key, value in pairs(source) do
    result[key] = mapper(value, key, source)
  end
  return result
end

function M.keys(source)
  source = table_or_empty(source, "source")
  local result = {}
  for key in pairs(source) do
    result[#result + 1] = key
  end
  return result
end

function M.sorted_keys(source, less)
  source = table_or_empty(source, "source")
  if less ~= nil and type(less) ~= "function" then
    error("less must be a function", 2)
  end

  local result = M.keys(source)
  table.sort(result, function(left, right)
    if less then
      return less(left, right, source)
    end
    return default_less(left, right)
  end)
  return result
end

function M.sorted_pairs(source, less)
  source = table_or_empty(source, "source")
  local ordered_keys = M.sorted_keys(source, less)
  local index = 0
  return function()
    index = index + 1
    local key = ordered_keys[index]
    if key ~= nil then
      return key, source[key]
    end
  end
end

return M

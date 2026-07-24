local M = {}

local function text(value)
  if value == nil then
    return ""
  end
  return tostring(value)
end

function M.trim(value)
  local result = text(value)
  result = string.gsub(result, "^%s+", "")
  result = string.gsub(result, "%s+$", "")
  return result
end

function M.is_blank(value)
  return M.trim(value) == ""
end

function M.starts_with(value, prefix)
  value = text(value)
  prefix = text(prefix)
  return string.sub(value, 1, #prefix) == prefix
end

function M.ends_with(value, suffix)
  value = text(value)
  suffix = text(suffix)
  if suffix == "" then
    return true
  end
  return string.sub(value, -#suffix) == suffix
end

function M.join_path(...)
  local result = ""
  for index = 1, select("#", ...) do
    local segment = text(select(index, ...))
    if segment ~= "" then
      if result == "" then
        result = segment
      else
        local left_has_slash = string.sub(result, -1) == "/"
        local right_has_slash = string.sub(segment, 1, 1) == "/"
        if left_has_slash and right_has_slash then
          result = result .. string.gsub(segment, "^/+", "")
        elseif not left_has_slash and not right_has_slash then
          result = result .. "/" .. segment
        else
          result = result .. segment
        end
      end
    end
  end
  return result
end

return M

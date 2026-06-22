---@param line string
---@param ctx blink.cmp.Context
local function compute_meta_yaml(line, ctx)
  -- protect regex performance
  assert(#line <= 200)

  local col = ctx.cursor[2]
  local indent = #line:match("^(%s*)")
  local colon_pos = line:find(":", indent + 1, true)

  if not colon_pos then
    -- The user is still typing the dependency key.
    local name = line:sub(indent + 1, col)
    return {
      name,
      indent + 1,
      col,
      col + 1,
      nil,
      nil,
      nil,
      nil,
      false,
    }
  end

  -- Key (package name)
  local key_with_quotes = line:sub(indent + 1, colon_pos - 1)
  local key_trimmed = key_with_quotes:match("^%s*(.-)%s*$")
  local key_leading_spaces = #key_with_quotes - #key_with_quotes:match("^%s*(.*)$")
  local key_start = indent + 1 + key_leading_spaces
  local key_end = key_start + #key_trimmed - 1

  local key_content_start = key_start
  local key_content_end = key_end

  if #key_trimmed >= 2 then
    local first = key_trimmed:sub(1, 1)
    local last = key_trimmed:sub(-1)
    if (first == '"' and last == '"') or (first == "'" and last == "'") then
      key_content_start = key_start + 1
      key_content_end = key_end - 1
    end
  end

  -- Value (version)
  local after_colon = line:sub(colon_pos + 1)
  local value_leading_spaces = #after_colon - #after_colon:match("^%s*(.*)$")
  local value_start_abs = colon_pos + value_leading_spaces + 1
  local value_part = line:sub(value_start_abs)
  local value_trimmed = value_part:match("^%s*(.-)%s*$")
  local value_end_abs = value_start_abs + #value_trimmed - 1

  local value_content_start = value_start_abs
  local value_content_end = value_end_abs

  if #value_trimmed >= 2 then
    local first = value_trimmed:sub(1, 1)
    local last = value_trimmed:sub(-1)
    if (first == '"' and last == '"') or (first == "'" and last == "'") then
      value_content_start = value_start_abs + 1
      value_content_end = value_end_abs - 1
    end
  end

  local find_version = col >= value_content_start
  local current_version
  local current_version_matcher

  if find_version then
    local typed = line:sub(value_content_start, col)
    current_version_matcher, current_version = typed:match("^([~^]?)(.*)$")
  end

  -- For an empty value we shift the closing position by one so that
  -- completions still trigger at the value position.
  local pos_fourth_quote = value_end_abs + 1
  if value_end_abs < value_start_abs then
    pos_fourth_quote = value_start_abs + 1
  end

  return {
    line:sub(key_content_start, key_content_end),
    key_content_start,
    key_content_end,
    key_end + 1,
    value_start_abs,
    pos_fourth_quote,
    current_version,
    current_version_matcher,
    find_version,
  }
end

return compute_meta_yaml

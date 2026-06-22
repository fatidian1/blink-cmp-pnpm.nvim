---@param line string
---@return string|nil key
---@return integer indent
local function parse_key(line)
  local indent = #line:match("^(%s*)")
  local key = line:sub(indent + 1):match('^"?([%w%-%_%@/%.]+)"?:')
  return key, indent
end

---@return boolean
local function is_cursor_in_catalog_node()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row, false)

  ---@type { key: string, indent: integer }[]
  local stack = {}

  for _, line in ipairs(lines) do
    local key, indent = parse_key(line)

    while #stack > 0 and stack[#stack].indent >= indent do
      table.remove(stack)
    end

    if key then
      table.insert(stack, { key = key, indent = indent })
    end
  end

  local depth = #stack

  -- Inside the singular `catalog:` block.
  if depth >= 2 and stack[depth - 1].key == "catalog" then
    return true
  end

  -- Inside a named catalog under `catalogs:`.
  if depth >= 3 and stack[depth - 2].key == "catalogs" then
    return true
  end

  return false
end

return is_cursor_in_catalog_node

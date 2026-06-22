local M = {}

---@type table<string, blink-cmp-pnpm.Catalogs>
local cache = {}

---@param value string
---@return string
local function strip_quotes(value)
  local single = value:match("^'(.*)'$")
  if single then
    return single
  end
  local double = value:match('^"(.*)"$')
  if double then
    return double
  end
  return value
end

---@param value string
---@return string
local function strip_inline_comment(value)
  -- Remove a trailing `# comment`, but do not touch simple values that happen
  -- to contain a hash inside quotes (quoted values are stripped earlier).
  return value:gsub("%s*#.*$", "")
end

---@param path string
---@return table<string, any>
local function parse_yaml(path)
  local lines = vim.fn.readfile(path)
  local root = {}
  ---@type { node: table<string, any>, indent: integer }[]
  local stack = { { node = root, indent = -1 } }

  for _, line in ipairs(lines) do
    if line:match("%S") and not line:match("^%s*#") then
      local indent = #line:match("^(%s*)")
      local content = line:sub(indent + 1)
      local key, value = content:match("^([%w%-%_%@/%.]+):%s*(.*)$")

      if key then
        value = strip_inline_comment(value)
        value = strip_quotes(value)

        while #stack > 1 and stack[#stack].indent >= indent do
          table.remove(stack)
        end

        local current = stack[#stack].node
        if value == "" then
          current[key] = {}
          table.insert(stack, { node = current[key], indent = indent })
        else
          current[key] = value
        end
      end
    end
  end

  return root
end

---@param root string
---@return blink-cmp-pnpm.Catalogs
function M.load(root)
  if cache[root] then
    return cache[root]
  end

  local path = root .. "/pnpm-workspace.yaml"
  if vim.fn.filereadable(path) ~= 1 then
    path = root .. "/pnpm-workspace.yml"
  end

  local catalogs = { default = {}, named = {} }

  if vim.fn.filereadable(path) == 1 then
    local parsed = parse_yaml(path)

    if type(parsed.catalog) == "table" then
      catalogs.default = parsed.catalog
    end

    if type(parsed.catalogs) == "table" then
      catalogs.named = parsed.catalogs
    end
  end

  cache[root] = catalogs
  return catalogs
end

---@param catalogs blink-cmp-pnpm.Catalogs
---@param dep_name string
---@return string[]
function M.get_tags(catalogs, dep_name)
  local tags = {}

  if type(catalogs.default) == "table" and catalogs.default[dep_name] then
    table.insert(tags, "catalog:")
  end

  if type(catalogs.named) == "table" then
    for catalog_name, deps in pairs(catalogs.named) do
      if type(deps) == "table" and deps[dep_name] then
        table.insert(tags, "catalog:" .. catalog_name)
      end
    end
  end

  return tags
end

---@param catalogs blink-cmp-pnpm.Catalogs
---@param dep_name string
---@param items lsp.CompletionItem[]
---@param kind integer
function M.add_catalog_tags(catalogs, dep_name, items, kind)
  local tags = M.get_tags(catalogs, dep_name)
  for index, tag in ipairs(tags) do
    table.insert(items, {
      label = tag,
      kind = kind,
      sortText = "!" .. string.format("%03d", index),
    })
  end
end

function M.clear_cache()
  cache = {}
end

return M

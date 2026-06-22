local M = {}

---@type table<string, string[]>
local cached_workspaces = {}

---@param root? string
---@param manager? PackageManager
---@param callback fun(workspaces: string[])
local function load_workspaces(root, manager, callback)
  if not root or manager ~= "pnpm" then
    callback({})
    return
  end

  if cached_workspaces[root] then
    callback(cached_workspaces[root])
    return
  end

  vim.system({ "pnpm", "ls", "--depth=-1", "--recursive", "--json" }, { cwd = root }, function(result)
    local workspaces = {}

    if result.code ~= 0 then
      callback(workspaces)
      return
    end

    local ok, decoded = pcall(vim.json.decode, result.stdout)
    if not ok or type(decoded) ~= "table" then
      callback(workspaces)
      return
    end

    for _, workspace in ipairs(decoded) do
      if type(workspace.name) == "string" then
        table.insert(workspaces, workspace.name)
      end
    end

    cached_workspaces[root] = workspaces
    callback(workspaces)
  end)
end

---@param workspaces string[]
---@param name string
---@return string[]
local function filter_workspaces(workspaces, name)
  local filtered_workspaces = {}
  for _, workspace in ipairs(workspaces) do
    if workspace:match(name) then
      table.insert(filtered_workspaces, workspace)
    end
  end
  return filtered_workspaces
end

---@param workspaces string[]
---@param items lsp.CompletionItem[]
---@param kind integer
local function add_workspace_versions(workspaces, items, kind)
  if not workspaces or #workspaces == 0 then
    return
  end

  local tags = { "workspace:*", "workspace:^", "workspace:~" }
  for index, tag in ipairs(tags) do
    table.insert(items, {
      label = tag,
      kind = kind,
      sortText = "!" .. string.format("%03d", index),
    })
  end
end

M.load_workspaces = load_workspaces
M.filter_workspaces = filter_workspaces
M.add_workspace_versions = add_workspace_versions

function M.clear_cache()
  cached_workspaces = {}
end

return M

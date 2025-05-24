local M = {}

---@param name string
---@param callback fun(workspaces: string[])
local function load_workspaces(callback)
  vim.system({ "pnpm", "ls", "--depth=-1", "--recursive", "--json" }, nil, function(result)
    local workspaces = {}

    if result.code ~= 0 then
      callback(workspaces)
      return
    end

    local decoded = vim.json.decode(result.stdout)

    for _, workspace in ipairs(decoded) do
      table.insert(workspaces, workspace.name)
    end

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

local function add_workspace_version(workspaces, items, kind)
  if workspaces[1] then
    local workspace_version = {
      label = "workspace:*",
      sortText = 0,
      kind = kind,
    }
    table.insert(items, workspace_version)
  end
end

M.load_workspaces = load_workspaces
M.filter_workspaces = filter_workspaces
M.add_workspace_version = add_workspace_version

return M

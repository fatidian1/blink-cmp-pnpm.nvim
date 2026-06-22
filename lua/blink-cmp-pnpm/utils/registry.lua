local M = {}

---@param manager "npm" | "pnpm"
---@param name string
---@return string[]
local function search_args(manager, name)
  if manager == "pnpm" then
    return { "pnpm", "search", name, "--json" }
  end
  return { "npm", "search", "--json", "--no-update-notifier", name }
end

---@param manager "npm" | "pnpm"
---@param name string
---@return string[]
local function latest_args(manager, name)
  if manager == "pnpm" then
    return { "pnpm", "view", name, "version", "--json" }
  end
  return { "npm", "info", name, "version", "--no-update-notifier" }
end

---@param manager "npm" | "pnpm"
---@param name string
---@return string[]
local function all_args(manager, name)
  if manager == "pnpm" then
    return { "pnpm", "view", name, "versions", "--json" }
  end
  return { "npm", "info", name, "versions", "--json", "--no-update-notifier" }
end

---@param name string
---@param callback fun(packages: NpmPackage[])
---@param manager? "npm" | "pnpm"
local function load_packages(name, callback, manager)
  manager = manager or "npm"

  if not name then
    callback({})
    return
  end

  vim.system(search_args(manager, name), nil, function(result)
    if result.code ~= 0 then
      callback({})
      return
    end

    local ok, packages = pcall(vim.json.decode, result.stdout)
    if not ok or type(packages) ~= "table" then
      callback({})
      return
    end

    callback(packages)
  end)
end

---@param name string
---@param callback fun(version: string)
---@param manager? "npm" | "pnpm"
local function list_latest_version(name, callback, manager)
  manager = manager or "npm"

  if not name then
    callback("")
    return
  end

  vim.system(latest_args(manager, name), nil, function(result)
    if result.code ~= 0 then
      callback("")
      return
    end

    -- pnpm returns a JSON string such as "4.18.1"
    local ok, version = pcall(vim.json.decode, result.stdout)
    if ok and type(version) == "string" then
      callback(version)
      return
    end

    -- npm returns plain text
    local lines = vim.split(result.stdout, "\n")
    callback(lines[1] or "")
  end)
end

---@param name string
---@param callback fun(versions: string[])
---@param manager? "npm" | "pnpm"
local function list_all_versions(name, callback, manager)
  manager = manager or "npm"

  if not name then
    callback({})
    return
  end

  vim.system(all_args(manager, name), nil, function(result)
    if result.code ~= 0 then
      callback({})
      return
    end

    local ok, versions = pcall(vim.json.decode, result.stdout)
    if not ok or type(versions) ~= "table" then
      callback({})
      return
    end

    callback(versions)
  end)
end

M.load_packages = load_packages
M.list_latest_version = list_latest_version
M.list_all_versions = list_all_versions

return M

local M = {}

---@type table<string, "npm" | "pnpm">
local cache = {}

---@param path string
---@return string|nil
local function find_root(path)
  local dir = path
  if vim.fn.isdirectory(dir) == 0 then
    dir = vim.fn.fnamemodify(dir, ":h")
  end

  while dir ~= "" and dir ~= "/" do
    if
      vim.fn.filereadable(dir .. "/package.json") == 1
      or vim.fn.filereadable(dir .. "/pnpm-workspace.yaml") == 1
      or vim.fn.filereadable(dir .. "/pnpm-workspace.yml") == 1
    then
      return dir
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  return nil
end

---@param root string
---@return "npm" | "pnpm"
local function detect_manager(root)
  if vim.fn.executable("pnpm") ~= 1 then
    return "npm"
  end

  -- pnpm-specific project artifacts
  if
    vim.fn.filereadable(root .. "/pnpm-lock.yaml") == 1
    or vim.fn.filereadable(root .. "/pnpm-workspace.yaml") == 1
    or vim.fn.filereadable(root .. "/pnpm-workspace.yml") == 1
  then
    return "pnpm"
  end

  -- packageManager field in package.json
  local package_json_path = root .. "/package.json"
  if vim.fn.filereadable(package_json_path) == 1 then
    local ok, decoded = pcall(function()
      return vim.json.decode(table.concat(vim.fn.readfile(package_json_path), "\n"))
    end)

    if ok and type(decoded) == "table" and type(decoded.packageManager) == "string" then
      if decoded.packageManager:sub(1, 4) == "pnpm" then
        return "pnpm"
      end
    end
  end

  return "npm"
end

---@param bufnr integer
---@return string|nil root
---@return "npm" | "pnpm" manager
function M.get(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    path = vim.fn.getcwd()
  end

  local root = find_root(path)
  if not root then
    return nil, "npm"
  end

  local cached = cache[root]
  if cached then
    return root, cached
  end

  local manager = detect_manager(root)
  cache[root] = manager
  return root, manager
end

---@param bufnr integer
---@return boolean
function M.is_pnpm(bufnr)
  local _, manager = M.get(bufnr)
  return manager == "pnpm"
end

function M.clear_cache()
  cache = {}
end

return M

local package_manager = require("blink-cmp-pnpm.utils.package_manager")

describe("package_manager", function()
  local tmpdir

  before_each(function()
    tmpdir = vim.fn.fnamemodify(".tmp_package_manager_spec", ":p")
    vim.fn.delete(tmpdir, "rf")
    vim.fn.mkdir(tmpdir .. "/sub", "p")
    package_manager.clear_cache()
  end)

  after_each(function()
    vim.fn.delete(tmpdir, "rf")
  end)

  local function open_buffer(path)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, path)
    vim.api.nvim_set_current_buf(buf)
    return buf
  end

  it("should detect pnpm from pnpm-lock.yaml", function()
    vim.fn.writefile({ '{ "name": "root" }' }, tmpdir .. "/package.json")
    vim.fn.writefile({ "" }, tmpdir .. "/pnpm-lock.yaml")

    local buf = open_buffer(tmpdir .. "/sub/file.json")
    local root, manager = package_manager.get(buf)

    assert.are.equal(tmpdir, root)
    assert.are.equal("pnpm", manager)
  end)

  it("should detect pnpm from packageManager field", function()
    vim.fn.writefile({ '{ "name": "root", "packageManager": "pnpm@9.0.0" }' }, tmpdir .. "/package.json")

    local buf = open_buffer(tmpdir .. "/sub/file.json")
    local root, manager = package_manager.get(buf)

    assert.are.equal(tmpdir, root)
    assert.are.equal("pnpm", manager)
  end)

  it("should fall back to npm", function()
    vim.fn.writefile({ '{ "name": "root" }' }, tmpdir .. "/package.json")

    local buf = open_buffer(tmpdir .. "/sub/file.json")
    local root, manager = package_manager.get(buf)

    assert.are.equal(tmpdir, root)
    assert.are.equal("npm", manager)
  end)
end)

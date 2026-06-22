local catalogs = require("blink-cmp-pnpm.utils.catalogs")

describe("catalogs", function()
  local tmpdir

  before_each(function()
    tmpdir = vim.fn.fnamemodify(".tmp_catalogs_spec", ":p")
    vim.fn.delete(tmpdir, "rf")
    vim.fn.mkdir(tmpdir, "p")
    catalogs.clear_cache()
  end)

  after_each(function()
    vim.fn.delete(tmpdir, "rf")
  end)

  it("should parse default and named catalogs", function()
    vim.fn.writefile({
      "packages:",
      "  - 'packages/*'",
      "",
      "catalog:",
      "  lodash: ^4.17.21",
      "  react: ^18.0.0",
      "",
      "catalogs:",
      "  default:",
      "    lodash: ^4.17.21",
      "  react18:",
      "    react: ^18.0.0",
      "    react-dom: ^18.0.0",
    }, tmpdir .. "/pnpm-workspace.yaml")

    local parsed = catalogs.load(tmpdir)

    assert.are.equal("^4.17.21", parsed.default["lodash"])
    assert.are.equal("^18.0.0", parsed.default["react"])
    assert.are.equal("^18.0.0", parsed.named["react18"]["react"])
    assert.are.equal("^18.0.0", parsed.named["react18"]["react-dom"])
  end)

  it("should build catalog tags for a dependency", function()
    local parsed = {
      default = { react = "^18.0.0" },
      named = { react18 = { react = "^18.0.0" } },
    }

    local tags = catalogs.get_tags(parsed, "react")

    assert.is_true(vim.tbl_contains(tags, "catalog:"))
    assert.is_true(vim.tbl_contains(tags, "catalog:react18"))
  end)
end)

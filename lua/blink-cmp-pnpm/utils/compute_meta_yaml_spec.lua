local compute_meta_yaml = require("blink-cmp-pnpm.utils.compute_meta_yaml")

describe("compute_meta_yaml", function()
  it("should compute metadata for an unquoted key/value", function()
    local meta = compute_meta_yaml("  lodash: ^4.17.21", { cursor = { 1, 12 } })
    local name, pos_start_name, pos_end_name, pos_second_quote, pos_third_quote, pos_fourth_quote, current_version, current_version_matcher, find_version =
      unpack(meta)

    assert.are.equal("lodash", name)
    assert.are.equal(3, pos_start_name)
    assert.are.equal(8, pos_end_name)
    assert.are.equal(9, pos_second_quote)
    assert.are.equal(11, pos_third_quote)
    assert.are.equal(20, pos_fourth_quote)
    assert.are.equal("4", current_version)
    assert.are.equal("^", current_version_matcher)
    assert.is_true(find_version)
  end)

  it("should compute metadata for a quoted key/value", function()
    local meta = compute_meta_yaml('  "react": "18.0.0"', { cursor = { 1, 16 } })
    local name, pos_start_name, pos_end_name, pos_second_quote, pos_third_quote, pos_fourth_quote, current_version, current_version_matcher, find_version =
      unpack(meta)

    assert.are.equal("react", name)
    assert.are.equal(4, pos_start_name)
    assert.are.equal(8, pos_end_name)
    assert.are.equal(10, pos_second_quote)
    assert.are.equal(12, pos_third_quote)
    assert.are.equal(21, pos_fourth_quote)
    assert.are.equal("18.0.0", current_version)
    assert.are.equal("", current_version_matcher)
    assert.is_true(find_version)
  end)

  it("should handle a missing value", function()
    local meta = compute_meta_yaml("  react:", { cursor = { 1, 10 } })
    local name, _pos_start_name, _pos_end_name, _pos_second_quote, pos_third_quote, pos_fourth_quote, current_version, current_version_matcher, find_version =
      unpack(meta)

    assert.are.equal("react", name)
    assert.are.equal(10, pos_third_quote)
    assert.are.equal(11, pos_fourth_quote)
    assert.are.equal("", current_version)
    assert.are.equal("", current_version_matcher)
    assert.is_true(find_version)
  end)

  it("should handle a partial key without colon", function()
    local meta = compute_meta_yaml("  lo", { cursor = { 1, 4 } })
    local name, pos_start_name, pos_end_name, pos_second_quote, pos_third_quote, pos_fourth_quote, current_version, current_version_matcher, find_version =
      unpack(meta)

    assert.are.equal("lo", name)
    assert.are.equal(3, pos_start_name)
    assert.are.equal(4, pos_end_name)
    assert.are.equal(5, pos_second_quote)
    assert.is_nil(pos_third_quote)
    assert.is_nil(pos_fourth_quote)
    assert.is_nil(current_version)
    assert.is_nil(current_version_matcher)
    assert.is_false(find_version)
  end)
end)

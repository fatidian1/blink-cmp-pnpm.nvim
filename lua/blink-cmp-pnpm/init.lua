local catalogs_module = require("blink-cmp-pnpm.utils.catalogs")
local compute_meta = require("blink-cmp-pnpm.utils.compute_meta")
local compute_meta_yaml = require("blink-cmp-pnpm.utils.compute_meta_yaml")
local extract_line = require("blink-cmp-pnpm.utils.extract_line")
local generate_doc = require("blink-cmp-pnpm.utils.generate_doc")
local ignore_version = require("blink-cmp-pnpm.utils.ignore_version")
local is_cursor_in_catalog_node = require("blink-cmp-pnpm.utils.is_cursor_in_catalog_node")
local is_cursor_in_dependencies_node = require("blink-cmp-pnpm.utils.is_cursor_in_dependencies_node")
local package_manager = require("blink-cmp-pnpm.utils.package_manager")
local registry = require("blink-cmp-pnpm.utils.registry")
local semantic_sort = require("blink-cmp-pnpm.utils.semantic_sort")
local workspaces_module = require("blink-cmp-pnpm.utils.workspaces")

---@module 'blink.cmp'
---@class blink-cmp-pnpm.Source: blink.cmp.Source
---@field opts blink-cmp-pnpm.Options
local source = {}

---@class blink-cmp-pnpm.Options: blink.cmp.PathOpts
---@field ignore? table
---@field only_semantic_versions? boolean
---@field only_latest_version? boolean
local default_opts = {
  ignore = {},
  only_semantic_versions = true,
  only_latest_version = false,
}

---@param opts blink-cmp-pnpm.Options
function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.opts = vim.tbl_deep_extend("force", default_opts, opts)
  return self
end

function source:enabled()
  local filename = vim.fn.expand("%:t")
  return filename == "package.json"
    or filename == "pnpm-workspace.yaml"
    or filename == "pnpm-workspace.yml"
end

function source:get_trigger_characters()
  return { '"' }
end

---@param ctx blink.cmp.Context
---@param callback fun(response: blink.cmp.CompletionResponse)
---@param root? string
---@param manager PackageManager
function source:get_workspace_completions(ctx, callback, root, manager)
  if not is_cursor_in_catalog_node() then
    return function() end
  end

  local line = extract_line(ctx)
  if #line > 200 then
    line = line:sub(1, 200)
  end

  local meta = compute_meta_yaml(line, ctx)
  local name, _pos_start_name, _pos_end_name, _pos_second_quote, _pos_third_quote, pos_fourth_quote, current_version, current_version_matcher, find_version =
    unpack(meta)

  if not name then
    return function() end
  end

  local col = ctx.cursor[2]
  if pos_fourth_quote ~= nil and col >= pos_fourth_quote then
    return function() end
  end

  local kind = require("blink.cmp.types").CompletionItemKind.Module

  if find_version then
    local function build_items(versions)
      ---@type lsp.CompletionItem[]
      local items = {}

      for _, version in ipairs(versions) do
        local version_ignored = ignore_version(version, current_version, self.opts)
        if not version_ignored then
          if not current_version or current_version_matcher == "^" then
            table.insert(items, { label = "^" .. version, kind = kind })
          end
          if not current_version or current_version_matcher == "~" then
            table.insert(items, { label = "~" .. version, kind = kind })
          end
          if not current_version or current_version_matcher == "" then
            table.insert(items, { label = version, kind = kind })
          end
        end
      end

      table.sort(items, semantic_sort)

      for index, item in ipairs(items) do
        items[index] = vim.tbl_deep_extend("force", item, {
          sortText = string.format("%06d", index),
        })
      end

      callback({
        items = items,
        is_incomplete_backward = true,
        is_incomplete_forward = true,
      })
    end

    if self.opts.only_latest_version then
      registry.list_latest_version(name, function(version)
        if version then
          build_items({ version })
        else
          callback({ items = {}, is_incomplete_backward = true, is_incomplete_forward = true })
        end
      end, manager)
    else
      registry.list_all_versions(name, build_items, manager)
    end
  else
    ---@type lsp.CompletionItem[]
    local items = {}
    registry.load_packages(name, function(packages)
      for _, package in ipairs(packages) do
        table.insert(items, {
          kind = kind,
          label = package.name,
          sortText = string.format("%06d", #items + 1),
          documentation = {
            kind = "markdown",
            value = generate_doc(package),
          },
        })
      end
      callback({
        items = items,
        is_incomplete_backward = true,
        is_incomplete_forward = true,
      })
    end, manager)
  end
end

function source:get_completions(ctx, callback)
  local bufnr = vim.api.nvim_get_current_buf()
  local root, manager = package_manager.get(bufnr)
  local filename = vim.fn.expand("%:t")

  if filename == "pnpm-workspace.yaml" or filename == "pnpm-workspace.yml" then
    return self:get_workspace_completions(ctx, callback, root, manager)
  end

  local is_in_dependencies_node = is_cursor_in_dependencies_node()

  if not is_in_dependencies_node then
    return function() end
  end

  local line = extract_line(ctx)
  local meta = compute_meta(line, ctx)
  local name, _pos_start_name, _pos_end_name, _pos_second_quote, _pos_third_quote, pos_fourth_quote, current_version, current_version_matcher, find_version =
    unpack(meta)

  if not name then
    return function() end
  end

  local col = ctx.cursor[2]
  if pos_fourth_quote ~= nil and col >= pos_fourth_quote then
    return function() end
  end

  local kind = require("blink.cmp.types").CompletionItemKind.Module

  workspaces_module.load_workspaces(root, manager, function(workspaces)
    local filtered_workspaces = workspaces_module.filter_workspaces(workspaces, name)

    local catalogs = manager == "pnpm" and catalogs_module.load(root) or { default = {}, named = {} }

    if find_version then
      if self.opts.only_latest_version then
        registry.list_latest_version(name, function(version)
          ---@type lsp.CompletionItem[]
          local items = {}

          workspaces_module.add_workspace_versions(filtered_workspaces, items, kind)
          catalogs_module.add_catalog_tags(catalogs, name, items, kind)

          if not version then
            if items[1] then
              callback({
                items = items,
                is_incomplete_backward = true,
                is_incomplete_forward = true,
              })
            end
            return
          end

          ---@type lsp.CompletionItem
          local item_minor = {
            label = "^" .. version,
            sortText = version .. "_1",
            kind = kind,
          }

          ---@type lsp.CompletionItem
          local item_patch = {
            label = "~" .. version,
            sortText = version .. "_2",
            kind = kind,
          }

          ---@type lsp.CompletionItem
          local item_strict = {
            label = version,
            sortText = version .. "_3",
            kind = kind,
          }

          table.insert(items, item_minor)
          table.insert(items, item_patch)
          table.insert(items, item_strict)

          callback({
            items = items,
            is_incomplete_backward = true,
            is_incomplete_forward = true,
          })
        end, manager)
      else
        registry.list_all_versions(name, function(versions)
          ---@type lsp.CompletionItem[]
          local items = {}

          -- populate items
          for _, version in ipairs(versions) do
            local version_ignored = ignore_version(version, current_version, self.opts)
            if not version_ignored then
              if not current_version or current_version_matcher == "^" then
                table.insert(items, { label = "^" .. version, kind = kind })
              end
              if not current_version or current_version_matcher == "~" then
                table.insert(items, { label = "~" .. version, kind = kind })
              end
              if not current_version or current_version_matcher == "" then
                table.insert(items, { label = version, kind = kind })
              end
            end
          end

          -- order result
          table.sort(items, semantic_sort)

          -- add sorting property for blink.cmp
          for index, item in ipairs(items) do
            items[index] = vim.tbl_deep_extend("force", item, {
              sortText = string.format("%06d", index),
            })
          end

          workspaces_module.add_workspace_versions(filtered_workspaces, items, kind)
          catalogs_module.add_catalog_tags(catalogs, name, items, kind)

          callback({
            items = items,
            is_incomplete_backward = true,
            is_incomplete_forward = true,
          })
        end, manager)
      end
    else
      ---@type lsp.CompletionItem[]
      local items = {}
      local item_key = 1
      registry.load_packages(name, function(packages)
        for _, workspace in ipairs(filtered_workspaces) do
          table.insert(items, {
            kind = kind,
            label = workspace,
            sortText = string.format("%06d", item_key),
            documentation = {
              kind = "markdown",
              value = "Local workspace",
            },
          })
          item_key = item_key + 1
        end

        for _, package in ipairs(packages) do
          table.insert(items, {
            kind = kind,
            label = package.name,
            sortText = string.format("%06d", item_key),
            documentation = {
              kind = "markdown",
              value = generate_doc(package),
            },
          })
          item_key = item_key + 1
        end
        callback({
          items = items,
          is_incomplete_backward = true,
          is_incomplete_forward = true,
        })
      end, manager)
    end
  end)
end

---@param ctx blink.cmp.Context
---@param insert_text string
---@param pos_first_quote integer
---@param pos_second_quote integer | nil
---@param pos_end_line integer
local function replace_text(ctx, insert_text, pos_first_quote, pos_second_quote, pos_end_line)
  local row_1 = ctx.cursor[1]
  local row_0 = row_1 - 1
  if pos_second_quote then
    vim.api.nvim_buf_set_text(0, row_0, pos_first_quote, row_0, pos_second_quote - 1, { insert_text })
  else
    vim.api.nvim_buf_set_text(0, row_0, pos_first_quote, row_0, pos_end_line, { insert_text .. '"' })
  end
  vim.api.nvim_win_set_cursor(0, { row_1, pos_first_quote + #insert_text + 1 })
end

function source:execute(ctx, item, callback)
  local filename = vim.fn.expand("%:t")
  local line = extract_line(ctx)
  local insert_text = item.label
  if item.insertText then
    insert_text = item.insertText
  end
  local line_last_char = line:sub(#line)
  local pos_end_line = line_last_char == "," and (#line - 1) or #line

  if filename == "pnpm-workspace.yaml" or filename == "pnpm-workspace.yml" then
    local meta = compute_meta_yaml(line, ctx)
    local _name, pos_start_name, _pos_end_name, pos_second_quote, pos_third_quote, pos_fourth_quote, _current_version, _current_version_matcher, find_version =
      unpack(meta)

    if find_version then
      replace_text(ctx, insert_text, pos_third_quote, pos_fourth_quote, pos_end_line)
    else
      replace_text(ctx, insert_text, pos_start_name, pos_second_quote, pos_end_line)
    end

    callback()
    return
  end

  local meta = compute_meta(line, ctx)
  local _name, pos_start_name, _pos_end_name, pos_second_quote, pos_third_quote, pos_fourth_quote, _current_version, _current_version_matcher, find_version =
    unpack(meta)

  if find_version then
    replace_text(ctx, insert_text, pos_third_quote, pos_fourth_quote, pos_end_line)
  else
    local pos_first_quote = pos_start_name - 1
    replace_text(ctx, insert_text, pos_first_quote, pos_second_quote, pos_end_line)
  end
  callback()
end

return source

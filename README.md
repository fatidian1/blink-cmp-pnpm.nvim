# blink-cmp-pnpm

A [`blink.cmp`](https://github.com/Saghen/blink.cmp) source that provides
completions for `NPM` and `PNPM` packages and versions in `package.json` and `pnpm-workspace.yaml` files.
It also suggests pnpm workspace protocols (`workspace:*`, `workspace:^`, `workspace:~`) and
[catalog protocols](https://pnpm.io/catalogs) (`catalog:`, `catalog:<name>`) when they apply.

This plugin is an adaptation of [`blink-cmp-npm`](https://github.com/alexandre-abrioux/blink-cmp-npm.nvim),
modified to work with `pnpm`.

[![Demo Gif](https://raw.githubusercontent.com/alexandre-abrioux/blink-cmp-npm.nvim/refs/heads/main/demo.gif)](https://asciinema.org/a/718781?t=2)

## Features

- Automatically detects and uses `pnpm` when it is the project's package manager;
  otherwise falls back to `npm`.
- Package name and version completions in `package.json`.
- Package name and version completions inside `catalog` / `catalogs` blocks of
  `pnpm-workspace.yaml` / `pnpm-workspace.yml`.
- Suggests pnpm workspace protocols (`workspace:*`, `workspace:^`, `workspace:~`)
  for dependencies that match a local workspace package.
- Suggests pnpm catalog protocols (`catalog:`, `catalog:<name>`) for dependencies
  that are listed in a workspace catalog.

## Requirements

- [`neovim`](https://github.com/neovim/neovim) > `0.7.0`
- [`blink.cmp`](https://github.com/Saghen/blink.cmp)
- [`npm`](https://github.com/npm/cli)
- [`pnpm`](https://pnpm.io) (optional - the plugin also works with `npm`)

## Installation

Add the plugin to your packer manager and make sure it is loaded before `blink.cmp`.

### Using [`lazy.nvim`](https://github.com/folke/lazy.nvim)

```lua
{
  "saghen/blink.cmp",
  dependencies = { "fatidian1/blink-cmp-pnpm.nvim" },
  opts = {
    sources = {
      default = {
        -- enable "pnpm" in your sources list
        "pnpm"
      },
      providers = {
        -- configure the provider
        pnpm = {
          name = "pnpm",
          module = "blink-cmp-pnpm",
          async = true,
          -- optional - make blink-cmp-pnpm completions top priority (see `:h blink.cmp`)
          score_offset = 100,
          -- optional - blink-cmp-pnpm config
          ---@module "blink-cmp-pnpm"
          ---@type blink-cmp-pnpm.Options
          opts = {
            ignore = {},
            only_semantic_versions = true,
            only_latest_version = false,
          }
        },
      },
    },
  },
},
```

### Options

| Option                   | Type       | Default | Description                                            |
| ------------------------ | ---------- | ------- | ------------------------------------------------------ |
| `ignore`                 | `string[]` | `{}`    | Ignore versions that match any of these strings.       |
| `only_semantic_versions` | `boolean`  | `true`  | Ignore versions that do not match semantic versioning. |
| `only_latest_version`    | `boolean`  | `false` | When suggesting versions, only show the latest.        |

## Usage

Once installed and enabled, completions are provided automatically in:

- `package.json` inside `dependencies` / `devDependencies`
- `pnpm-workspace.yaml` / `pnpm-workspace.yml` inside `catalog` / `catalogs.*` blocks

### Package manager detection

The plugin decides whether to use `pnpm` or `npm` per project:

1. `pnpm` must be available in `$PATH`.
2. The project must use pnpm, detected by any of:
   - `pnpm-lock.yaml`
   - `pnpm-workspace.yaml` / `pnpm-workspace.yml`
   - `"packageManager": "pnpm@..."` in `package.json`

If pnpm is not detected, all registry lookups use `npm`.

### Workspace and catalog protocols

When a dependency name matches a local pnpm workspace package, version completions
include `workspace:*`, `workspace:^`, and `workspace:~`.

When a dependency is listed in a pnpm catalog, version completions include the
catalog protocols, e.g. `catalog:` and `catalog:react18`.

## Contributing

Contributions are welcome! Feel free to submit a Pull Request.

## Acknowledgements

Special thanks to:

- [@jakub-jarzabek](https://github.com/jakub-jarzabek/blink-cmp-npm.nvim) for adapting the plugin to work with pnpm workspaces [blink-cmp-npm](https://github.com/jakub-jarzabek/blink-cmp-npm.nvim)
- [@alexandre-abrioux](https://github.com/alexandre-abrioux/blink-cmp-npm.nvim) for creating [blink-cmp-npm](https://github.com/alexandre-abrioux/blink-cmp-npm.nvim)
- [@David-Kunz](https://github.com/David-Kunz/cmp-npm) for his work on [`cmp-npm`](https://github.com/David-Kunz/cmp-npm) 🙏
- [@Saghen](https://github.com/Saghen/blink.cmp) for creating and maintaining [`blink.cmp`](https://github.com/Saghen/blink.cmp) 🚀

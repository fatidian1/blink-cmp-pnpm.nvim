# blink-cmp-pnpm

A [`blink.cmp`](https://github.com/Saghen/blink.cmp) source that provides
completions for `NPM` and `PNPM` packages and versions in `package.json` and `pnpm-workspace.yaml` files.

This plugin is an adaptation of [`blink-cmp-npm`](https://github.com/alexandre-abrioux/blink-cmp-npm.nvim),
modified to work with `pnpm`.

[![Demo Gif](https://raw.githubusercontent.com/alexandre-abrioux/blink-cmp-npm.nvim/refs/heads/main/demo.gif)](https://asciinema.org/a/718781?t=2)

## Requirements

- [`neovim`](https://github.com/neovim/neovim) > `0.7.0`
- [`blink.cmp`](https://github.com/Saghen/blink.cmp)
- [`npm`](https://github.com/npm/cli)
- `pnpm` (optional - plugin will work also with `npm`)

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

Once installed and enabled,
completions will automatically be provided when working with `package.json` and `pnpm-workspace.yaml` files.

## Contributing

Contributions are welcome! Feel free to submit a Pull Request.

## Acknowledgements

Special thanks to:

- [@jakub-jarzabek](https://github.com/jakub-jarzabek/blink-cmp-npm.nvim) for adapting the plugin to work with pnpm workspaces [blink-cmp-npm](https://github.com/jakub-jarzabek/blink-cmp-npm.nvim)
- [@alexandre-abrioux](https://github.com/alexandre-abrioux/blink-cmp-npm.nvim) for creating [blink-cmp-npm](https://github.com/alexandre-abrioux/blink-cmp-npm.nvim)
- [@David-Kunz](https://github.com/David-Kunz/cmp-npm) for his work on [`cmp-npm`](https://github.com/David-Kunz/cmp-npm) 🙏
- [@Saghen](https://github.com/Saghen/blink.cmp) for creating and maintaining [`blink.cmp`](https://github.com/Saghen/blink.cmp) 🚀

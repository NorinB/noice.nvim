# 💥 Noice _(cmdline + search)_

A stripped-down fork of [folke/noice.nvim](https://github.com/folke/noice.nvim) built around three UI
features:

- **a floating cmdline** with per-command icons, titles and Treesitter highlighting
- **search count as virtual text** next to the matching line (`/`, `?`, `n`, `N`)
- **LSP progress** as a small notification in the bottom-right corner

Everything else that upstream Noice ships — LSP hover, signature help, the `vim.notify`
replacement, the markdown renderer, the popupmenu (wildmenu) UI and the
desktop-notification backends — has been removed.

What remains besides those three features is the plumbing they force (see below) plus the
`:Noice` commands, the message history with its pickers, the statusline API and the confirm
dialog.

## ⚠️ Messages are still routed through Noice

Neovim only emits the `msg_show` event with kind `search_count` when a UI attaches with
`ext_messages`. That flag makes Neovim hand **every** message to the plugin, so the search count
virtual text is not available without also taking over messages. Returning from the handler does
not hand a message back to Neovim to draw — it only stops propagation to remote UIs.

`ext_messages` also implies `ext_cmdline` and sets `cmdheight=0`. So `messages.enabled = false`
disables the search count, and `cmdline.enabled = false` while messages are on leaves nothing
drawing the cmdline at all.

All non-search messages are therefore forwarded to the `notify` view, which renders through
[snacks.nvim](https://github.com/folke/snacks.nvim) and falls back to the built-in `mini` view.
Set `messages.view*` to any other view to change that.

## ⚡️ Requirements

- Neovim >= 0.9.0 (0.11+ recommended, 0.10+ for LSP progress)
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- [snacks.nvim](https://github.com/folke/snacks.nvim) for the `notify` view (optional, falls back to `mini`)
- a [Nerd Font](https://www.nerdfonts.com/) for the cmdline icons (optional)
- `vim.opt.termguicolors` enabled
- the `vim`, `regex`, `lua` and `bash` Treesitter parsers for cmdline highlighting

## 📦 Installation

```lua
-- lazy.nvim
{
  "NorinB/noice.nvim",
  event = "VeryLazy",
  opts = {},
  dependencies = { "MunifTanjim/nui.nvim" },
}
```

Run `:checkhealth noice` after installing.

## ⚙️ Configuration

<details><summary>Default Settings</summary>

```lua
  cmdline = {
    -- NOTE: `messages` attaches `ext_messages`, which implies `ext_cmdline` and sets `cmdheight=0`.
    -- Disabling the cmdline while messages are enabled leaves nothing drawing the cmdline.
    enabled = true, -- enables the Noice cmdline UI
    view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
    opts = {}, -- global options for the cmdline. See section on views
    ---@type table<string, CmdlineFormat>
    format = {
      -- conceal: (default=true) This will hide the text in the cmdline that matches the pattern.
      -- view: (default is cmdline view)
      -- opts: any options passed to the view
      -- icon_hl_group: optional hl_group for the icon
      -- title: set to anything or empty string to hide
      cmdline = { pattern = "^:", icon = "", lang = "vim" },
      search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
      search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
      filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
      lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
      help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
      calculator = { pattern = "^=", icon = "", lang = "vimnormal" },
      input = { view = "cmdline_input", icon = "󰥻 " }, -- Used by input()
      -- lua = false, -- to disable a format, set to `false`
    },
  },
  messages = {
    -- NOTE: messages are needed for the search count virtual text.
    -- Neovim only emits `msg_show` with kind `search_count` when `ext_messages` is attached,
    -- which also routes every other message through Noice.
    enabled = true, -- enables the Noice messages UI
    view = "notify", -- default view for messages
    view_error = "notify", -- view for errors
    view_warn = "notify", -- view for warnings
    view_history = "messages", -- view for :messages
    view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
    history_max = 1000, -- maximum number of messages kept for `:Noice history` and the pickers
  },
  -- You can add any custom commands below that will be available with `:Noice command`
  ---@type table<string, NoiceCommand>
  commands = {
    history = {
      -- options for the message history that you get with `:Noice`
      view = "split",
      opts = { enter = true, format = "details" },
      filter = {
        any = {
          { error = true },
          { warning = true },
          { event = "msg_show", kind = { "" } },
        },
      },
    },
    -- :Noice last
    last = {
      view = "popup",
      opts = { enter = true, format = "details" },
      filter = {
        any = {
          { error = true },
          { warning = true },
          { event = "msg_show", kind = { "" } },
        },
      },
      filter_opts = { count = 1 },
    },
    -- :Noice errors
    errors = {
      -- options for the message history that you get with `:Noice`
      view = "popup",
      opts = { enter = true, format = "details" },
      filter = { error = true },
      filter_opts = { reverse = true },
    },
    all = {
      -- options for the message history that you get with `:Noice`
      view = "split",
      opts = { enter = true, format = "details" },
      filter = {},
    },
  },
  lsp = {
    progress = {
      enabled = true, -- enables the LSP progress notification
      view = "lsp_progress", -- view for rendering LSP progress
      throttle = 1000 / 10, -- frequency to advance the spinner
    },
  },
  health = {
    checker = true, -- Disable if you don't want health checks to run
  },
  ---@type NoicePresets
  presets = {
    -- you can enable a preset by setting it to true, or a table that will override the preset config
    -- you can also add custom presets that you can enable/disable with enabled=true
    bottom_search = false, -- use a classic bottom cmdline for search
    command_palette = false, -- position the cmdline in the upper half of the screen
    inc_rename = false, -- enables an input dialog for inc-rename.nvim
  },
  throttle = 1000 / 30, -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
  ---@type NoiceConfigViews
  views = {}, ---@see section on views
  ---@type NoiceRouteConfig[]
  routes = {}, --- @see section on routes
  ---@type table<string, NoiceFilter>
  status = {}, --- @see section on statusline components
  ---@type NoiceFormatOptions
  format = {}, --- @see section on formatting
  debug = false,
  log = vim.fn.stdpath("state") .. "/noice.log",
  log_max_size = 1024 * 1024 * 2, -- 10MB
```

</details>

### Presets

| Preset | Description |
| --- | --- |
| `bottom_search` | use a classic bottom cmdline for `/` and `?` |
| `command_palette` | position the cmdline in the upper half of the screen |
| `inc_rename` | input dialog for [inc-rename.nvim](https://github.com/smjonas/inc-rename.nvim) |

Enable a preset with `presets = { bottom_search = true }`, or pass a table to override parts of it.

### LSP Progress

An `LspProgress` autocmd turns each client's progress token into a message and routes it to the
`lsp_progress` view — the `mini` backend in the bottom-right corner. One line per token, with a
spinner, the percentage, the progress title and the client name. The line turns into `✔` when the
token ends and disappears `views.lsp_progress.timeout` ms later.

Move it to the bottom-left corner with:

```lua
require("noice").setup({
  views = { lsp_progress = { position = { col = 0 }, align = "message-left" } },
})
```

Set `lsp.progress.enabled = false` to turn the feature off entirely.

The feature needs Neovim 0.10+, which introduced the `LspProgress` event; on older versions it is
silently skipped.

`lsp_progress` and `mini` are separate windows in the same corner. That is fine as long as messages
render through snacks.nvim, but without it the `notify` view falls back to `mini` and the two
windows overlap. In that case let them share one window, which stacks the lines instead (the shared
view uses `mini`'s 2000 ms timeout):

```lua
require("noice").setup({
  lsp = { progress = { view = "mini" } },
})
```

## 🔍 Filters

Filters select the messages a route applies to. Every field must match, unless it is nested under
`any` or `not`.

| Key | Type | Description |
| --- | --- | --- |
| **cleared** | `boolean` | message was cleared |
| **mode** | `string` | `vim.api.nvim_get_mode().mode` matches |
| **blocking** | `boolean` | Neovim is waiting for input |
| **event** | `string\|string[]` | ui event, for example `msg_show` or `cmdline` |
| **kind** | `string\|string[]` | ui event kind, for example `search_count` |
| **error** | `boolean` | message is an error |
| **warning** | `boolean` | message is a warning |
| **find** | `string` | Lua pattern matched against the message content |
| **message** | `NoiceMessage[]` | message is one of these messages |
| **cond** | `fun(message):boolean` | custom predicate |
| **min_height** / **max_height** | `number` | height of the message |
| **min_width** / **max_width** | `number` | width of the message |
| **min_length** / **max_length** | `number` | length of the message content |
| **cmdline** | `string` | Lua pattern matched against the active cmdline |
| **any** | `filter[]` | at least one filter matches |
| **not** | `filter` | the filter does not match |
| **has** | `boolean` | the message is still active |

## 🌅 Views

A view is a backend plus a set of options. Available backends:

| Backend | Description |
| --- | --- |
| **popup** | a floating window (nui.nvim) |
| **split** | a split (nui.nvim) |
| **mini** | a small window in the corner that fades out |
| **snacks** | notifications through `snacks.nvim` |
| **virtualtext** | virtual text at the end of the cursor line |

Configured views: `virtualtext`, `notify`, `split`, `messages`, `lsp_progress`, `popup`, `cmdline`, `mini`, `cmdline_popup`, `cmdline_input`, `confirm`.

Override or add views with the `views` option:

```lua
require("noice").setup({
  views = {
    cmdline_popup = {
      position = { row = 5, col = "50%" },
      size = { width = 60, height = "auto" },
    },
  },
})
```

### Nui Options

| Option | Type | Description |
| --- | --- | --- |
| **backend** | `"popup"\|"split"` | nui backend |
| **relative** | `"cursor"\|"editor"\|"win"` | what the position is relative to |
| **enter** | `boolean` | enter the window after opening |
| **close** | `{events?, keys?}` | events and keys that close the view |
| **position** / **size** | `number\|string\|table` | position and size of the window |
| **border** | `table` | border style, padding and text |
| **win_options** | `table` | window options, including `winhighlight` |

### Virtual Text Options

| Option | Type | Description |
| --- | --- | --- |
| **hl_group** | `string` | highlight group of the virtual text |

## 🎨 Formatting

A format is a list of format elements. Available elements: `{message}`, `{title}`, `{level}`,
`{event}`, `{kind}`, `{date}`, `{cmdline}`, `{data}`, `{text}`, `{confirm}`, `{debug}`.

Built-in formats: `default`, `notify`, `details`, `telescope`, `telescope_preview`, `fzf`,
`fzf_preview`, `snacks`, `snacks_preview`.

```lua
require("noice").setup({
  format = {
    level = { icons = { error = " ", warn = " ", info = " " } },
  },
})
```

## 🚗 Routes

A route is `{ view, filter, opts }`. Custom routes are prepended to the defaults, so they win.

```lua
require("noice").setup({
  routes = {
    -- skip "written" messages
    { filter = { event = "msg_show", find = "written" }, opts = { skip = true } },
  },
})
```

Route options:

| Option | Type | Description |
| --- | --- | --- |
| **skip** | `boolean` | drop the message |
| **stop** | `boolean` | stop processing further routes (default `true`) |
| **any view option** | | passed to the view |

## 🚥 Statusline Components

```lua
require("noice").api.status.mode.get()
require("noice").api.status.mode.has()
```

Available components: `message`, `command`, `mode`, `search`, `ruler`. Example for lualine:

```lua
lualine_x = {
  {
    function()
      return require("noice").api.status.mode.get()
    end,
    cond = function()
      return package.loaded["noice"] and require("noice").api.status.mode.has()
    end,
  },
}
```

## 🔭 Pickers

Message history can be browsed with `snacks.picker`, `telescope.nvim` or `fzf-lua`:

```vim
:Noice pick
:Noice snacks
:Noice telescope
:Noice fzf
```

For telescope, load the extension first: `require("telescope").load_extension("noice")`.

## 🚀 Usage

| Command | Description |
| --- | --- |
| `:Noice` or `:Noice history` | show the message history |
| `:Noice last` | show the last message |
| `:Noice dismiss` | dismiss all visible messages |
| `:Noice errors` | show the error history |
| `:Noice disable` / `:Noice enable` | stop or start Noice |
| `:Noice all` | show all messages, including the internal ones |
| `:Noice stats` | show debugging stats |
| `:Noice routes` / `:Noice config` / `:Noice viewstats` | dump the resolved routes, config or view stats |
| `:Noice debug` | toggle debug mode |
| `:Noice log` | open the Noice log file |

Every command is also available as `:Noice<Name>`, for example `:NoiceDismiss`.

## 🌈 Highlight Groups

<!-- hl_start -->
| Highlight Group | Default Group | Description |
| --- | --- | --- |
| **NoiceCmdline** | _MsgArea_ | Normal for the classic cmdline area at the bottom" |
| **NoiceCmdlineIcon** | _DiagnosticSignInfo_ | Cmdline icon |
| **NoiceCmdlineIconCalculator** | _NoiceCmdlineIcon_ |  |
| **NoiceCmdlineIconCmdline** | _NoiceCmdlineIcon_ |  |
| **NoiceCmdlineIconFilter** | _NoiceCmdlineIcon_ |  |
| **NoiceCmdlineIconHelp** | _NoiceCmdlineIcon_ |  |
| **NoiceCmdlineIconInput** | _NoiceCmdlineIcon_ |  |
| **NoiceCmdlineIconLua** | _NoiceCmdlineIcon_ |  |
| **NoiceCmdlineIconSearch** | _DiagnosticSignWarn_ | Cmdline search icon (`/` and `?`) |
| **NoiceCmdlinePopup** | _Normal_ | Normal for the cmdline popup |
| **NoiceCmdlinePopupBorder** | _DiagnosticSignInfo_ | Cmdline popup border |
| **NoiceCmdlinePopupBorderCalculator** | _NoiceCmdlinePopupBorder_ |  |
| **NoiceCmdlinePopupBorderCmdline** | _NoiceCmdlinePopupBorder_ |  |
| **NoiceCmdlinePopupBorderFilter** | _NoiceCmdlinePopupBorder_ |  |
| **NoiceCmdlinePopupBorderHelp** | _NoiceCmdlinePopupBorder_ |  |
| **NoiceCmdlinePopupBorderInput** | _NoiceCmdlinePopupBorder_ |  |
| **NoiceCmdlinePopupBorderLua** | _NoiceCmdlinePopupBorder_ |  |
| **NoiceCmdlinePopupBorderSearch** | _DiagnosticSignWarn_ | Cmdline popup border for search |
| **NoiceCmdlinePopupTitle** | _DiagnosticSignInfo_ | Cmdline popup border |
| **NoiceCmdlinePopupTitleCalculator** | _NoiceCmdlinePopupBorderCalculator_ |  |
| **NoiceCmdlinePopupTitleCmdline** | _NoiceCmdlinePopupBorderCmdline_ |  |
| **NoiceCmdlinePopupTitleFilter** | _NoiceCmdlinePopupBorderFilter_ |  |
| **NoiceCmdlinePopupTitleHelp** | _NoiceCmdlinePopupBorderHelp_ |  |
| **NoiceCmdlinePopupTitleInput** | _NoiceCmdlinePopupBorderInput_ |  |
| **NoiceCmdlinePopupTitleLua** | _NoiceCmdlinePopupBorderLua_ |  |
| **NoiceCmdlinePopupTitleSearch** | _NoiceCmdlinePopupBorderSearch_ |  |
| **NoiceCmdlinePrompt** | _Title_ | prompt for input() |
| **NoiceConfirm** | _Normal_ | Normal for the confirm view |
| **NoiceConfirmBorder** | _DiagnosticSignInfo_ | Border for the confirm view |
| **NoiceCursor** | _Cursor_ | Fake Cursor |
| **NoiceFormatConfirm** | _CursorLine_ |  |
| **NoiceFormatConfirmDefault** | _Visual_ |  |
| **NoiceFormatDate** | _Special_ |  |
| **NoiceFormatEvent** | _NonText_ |  |
| **NoiceFormatKind** | _NonText_ |  |
| **NoiceFormatLevelDebug** | _NonText_ |  |
| **NoiceFormatLevelError** | _DiagnosticVirtualTextError_ |  |
| **NoiceFormatLevelInfo** | _DiagnosticVirtualTextInfo_ |  |
| **NoiceFormatLevelOff** | _NonText_ |  |
| **NoiceFormatLevelTrace** | _NonText_ |  |
| **NoiceFormatLevelWarn** | _DiagnosticVirtualTextWarn_ |  |
| **NoiceFormatTitle** | _Title_ |  |
| **NoiceLspProgressClient** | _Title_ | Lsp progress client name |
| **NoiceLspProgressSpinner** | _Constant_ | Lsp progress spinner |
| **NoiceLspProgressTitle** | _NonText_ | Lsp progress title |
| **NoiceMini** | _MsgArea_ | Normal for mini view |
| **NoicePopup** | _NormalFloat_ | Normal for popup views |
| **NoicePopupBorder** | _FloatBorder_ | Border for popup views |
| **NoiceScrollbar** | _PmenuSbar_ | Normal for scrollbar |
| **NoiceScrollbarThumb** | _PmenuThumb_ | Scrollbar thumb |
| **NoiceSplit** | _NormalFloat_ | Normal for split views |
| **NoiceSplitBorder** | _FloatBorder_ | Border for split views |
| **NoiceVirtualText** | _DiagnosticVirtualTextInfo_ | Default hl group for virtualtext views |
<!-- hl_end -->

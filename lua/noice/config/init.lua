---@diagnostic disable: missing-fields
local require = require("noice.util.lazy")

local Routes = require("noice.config.routes")

local M = {}

M.ns = vim.api.nvim_create_namespace("noice")

function M.defaults()
  ---@class NoiceConfig
  local defaults = {
    cmdline = {
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
    },
    -- default options for require('noice').redirect
    -- see the section on Command Redirection
    ---@type NoiceRouteConfig
    redirect = {
      view = "popup",
      filter = { event = "msg_show" },
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
  }
  return defaults
end

--- @type NoiceConfig
M.options = {}

M._running = false
function M.is_running()
  return M._running
end

function M.setup(options)
  options = options or {}

  M.fix_legacy(options)

  M.options = vim.tbl_deep_extend("force", {}, M.defaults(), {
    views = require("noice.config.views").defaults,
    status = require("noice.config.status").defaults,
    format = require("noice.config.format").defaults,
  })

  M.truncate_log()

  require("noice.config.preset").setup(options)

  local routes = M.options.routes
  M.options = vim.tbl_deep_extend("force", M.options, options)
  vim.list_extend(M.options.routes, routes)

  require("noice.config.cmdline").setup()

  M.options.routes = Routes.get(M.options.routes)

  require("noice.config.highlights").setup()
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      require("noice.config.highlights").setup()
    end,
  })

  if Snacks and pcall(require, "snacks.picker") then
    Snacks.picker.sources.noice = require("noice.integrations.snacks").source
  end

  M._running = true
end

function M.truncate_log()
  local stat = (vim.uv or vim.loop).fs_stat(M.options.log)
  if stat and stat.size > M.options.log_max_size then
    io.open(M.options.log, "w+"):close()
  end
end

---@param opts NoiceConfig
function M.fix_legacy(opts)
  if opts.history then
    opts.commands = opts.commands or {}
    opts.commands.history = opts.history
    opts.history = nil
  end
end

return M

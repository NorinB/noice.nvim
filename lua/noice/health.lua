local require = require("noice.util.lazy")

local Config = require("noice.config")
local Treesitter = require("noice.text.treesitter")
local Util = require("noice.util")

local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local warn = vim.health.warn or vim.health.report_warn
local error = vim.health.error or vim.health.report_error

local M = {}

M.checks = {}

M.log = {
  ---@class NoiceHealthLog
  checkhealth = {
    start = function(msg)
      start(msg or "noice.nvim")
    end,
    info = function(msg, ...)
      info(msg:format(...))
    end,
    ok = function(msg, ...)
      ok(msg:format(...))
    end,
    warn = function(msg, ...)
      warn(msg:format(...))
    end,
    error = function(msg, ...)
      error(msg:format(...))
    end,
  },
  ---@type NoiceHealthLog
  notify = {
    start = function(msg) end,
    info = function(msg, ...)
      Util.info(msg:format(...))
    end,
    ok = function(msg, ...) end,
    warn = function(msg, ...)
      Util.warn_once(msg:format(...))
    end,
    error = function(msg, ...)
      Util.error_once(msg:format(...))
    end,
  },
}

---@param opts? {checkhealth?: boolean}
function M.check(opts)
  opts = opts or {}
  opts.checkhealth = opts.checkhealth == nil and true or opts.checkhealth

  local log = opts.checkhealth and M.log.checkhealth or M.log.notify

  log.start()

  if vim.fn.has("nvim-0.9.0") ~= 1 then
    log.error("Noice requires Neovim >= 0.9.0")
    -- require("noice.util").error("Noice needs Neovim >= 0.9.0 (nightly)")
    if not opts.checkhealth then
      return
    end
  else
    log.ok("*Neovim* >= 0.9.0")
    if opts.checkhealth and vim.fn.has("nvim-0.11.0") ~= 1 then
      log.warn("*Neovim* >= 0.11 is highly recommended, since it fixes some issues related to `vim.ui_attach`")
    end
  end

  local uis = vim.api.nvim_list_uis()
  for _, ui in ipairs(uis) do
    local ok = true
    for _, ext in ipairs({ "ext_cmdline", "ext_messages" }) do
      if ui[ext] then
        ok = false
        log.error(
          "You're using a GUI that uses " .. ext .. ". Noice can't work when the GUI has " .. ext .. " enabled."
        )
      end
    end
    if ok then
      if ui.chan == 0 then
        log.ok("You're not using a GUI")
      else
        log.ok("You're using a GUI that should work ok")
      end
    end
  end

  if vim.go.lazyredraw then
    if not Config.is_running() then
      log.warn(
        "You have enabled 'lazyredraw' (see `:h 'lazyredraw'`)\nThis is only meant to be set temporarily.\nYou'll experience issues using Noice."
      )
    end
  else
    log.ok("*vim.go.lazyredraw* is not enabled")
  end

  if opts.checkhealth then
    if Util.module_exists("snacks.notifier") then
      log.ok("`snacks.nvim` is installed")
    else
      log.warn("Noice needs `snacks.nvim` for routes using the `notify` view")
    end

    if vim.o.shortmess:find("S") then
      log.warn(
        "You added `S` to `vim.opt.shortmess`. Search count messages will not be handled by Noice. So no virtual text for search count."
      )
    end

    for _, lang in ipairs({ "vim", "regex", "lua", "bash" }) do
      if Treesitter.has_lang(lang) then
        log.ok("{TreeSitter} `" .. lang .. "` parser is installed")
      else
        log.warn(
          "{TreeSitter} `"
            .. lang
            .. "` parser is not installed. Highlighting of the cmdline for `"
            .. lang
            .. "` might be broken"
        )
      end
    end
  end

  return true
end

M.checker = Util.interval(1000, function()
  if Config.is_running() then
    M.check({ checkhealth = false })
  end
end, {
  enabled = function()
    return Config.is_running()
  end,
})

return M

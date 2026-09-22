local require = require("noice.util.lazy")

local Util = require("noice.util")

-- HACK: a bunch of hacks to make Noice behave
local M = {}

---@type fun()[]
M._disable = {}

function M.reset_augroup()
  M.group = vim.api.nvim_create_augroup("noice.hacks", { clear = true })
end

function M.enable()
  M.reset_augroup()
  M.fix_vim_sleuth()
end

function M.fix_vim_sleuth()
  vim.g.sleuth_noice_heuristics = 0
end

function M.disable()
  M.reset_augroup()
  for _, fn in pairs(M._disable) do
    fn()
  end
  M._disable = {}
end

-- start a timer that checks for vim.v.hlsearch.
-- Clears search count and stops timer when hlsearch==0
function M.fix_nohlsearch()
  M.fix_nohlsearch = Util.interval(30, function()
    if vim.o.hlsearch and vim.v.hlsearch == 0 then
      local m = require("noice.ui.msg").get("msg_show", "search_count")
      require("noice.message.manager").remove(m)
    end
  end, {
    enabled = function()
      return vim.o.hlsearch and vim.v.hlsearch == 1
    end,
  })
  M.fix_nohlsearch()
end

M.SPECIAL = "Þ"
---@deprecated
function M.cmdline_force_redraw()
  if vim.fn.has("nvim-0.11") == 1 then
    -- no longer needed on nightly
    return
  end
  if not require("noice.util.ffi").cmdpreview then
    return
  end

  -- HACK: this will trigger redraw during substitute and cmdpreview
  vim.api.nvim_feedkeys(M.SPECIAL .. Util.BS, "n", true)
end

---@type string?
M._guicursor = nil
---@deprecated
function M.hide_cursor()
  if M._guicursor == nil then
    M._guicursor = vim.go.guicursor
  end
  -- schedule this, since otherwise Neovide crashes
  vim.schedule(function()
    if M._guicursor then
      vim.go.guicursor = "a:NoiceHiddenCursor"
    end
  end)
  M._disable.guicursor = M.show_cursor
end

---@deprecated
function M.show_cursor()
  if M._guicursor then
    if not Util.is_exiting() then
      vim.schedule(function()
        if M._guicursor and not Util.is_exiting() then
          -- we need to reset all first and then wait for some time before resetting the guicursor. See #114
          vim.go.guicursor = "a:"
          vim.cmd.redrawstatus()
          vim.go.guicursor = M._guicursor
          M._guicursor = nil
        end
      end)
    end
  end
end

return M

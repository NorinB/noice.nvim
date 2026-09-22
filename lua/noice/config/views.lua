local require = require("noice.util.lazy")

local Config = require("noice.config")
local Util = require("noice.util")

local M = {}

---@param view string
---@return NoiceViewOptions
function M.get_options(view)
  if not view then
    Util.panic("View is missing?")
  end

  local opts = { view = view }

  local done = {}
  while opts.view and not done[opts.view] do
    done[opts.view] = true

    local view_opts = vim.deepcopy(Config.options.views[opts.view] or {})
    opts = vim.tbl_deep_extend("keep", opts, view_opts)
    opts.view = view_opts.view
  end

  return opts
end

---@class NoiceConfigViews: table<string, NoiceViewOptions>
M.defaults = {
  virtualtext = {
    backend = "virtualtext",
    format = { "{message}" },
    hl_group = "NoiceVirtualText",
  },
  notify = {
    backend = { "snacks" },
    fallback = "mini",
    format = "notify",
    replace = false,
    merge = false,
  },
  split = {
    backend = "split",
    enter = false,
    relative = "editor",
    position = "bottom",
    size = "20%",
    close = {
      keys = { "q" },
    },
    win_options = {
      winhighlight = { Normal = "NoiceSplit", FloatBorder = "NoiceSplitBorder" },
      wrap = true,
    },
  },
  cmdline_output = {
    format = "details",
    view = "split",
  },
  messages = {
    view = "split",
    enter = true,
  },
  popup = {
    backend = "popup",
    relative = "editor",
    close = {
      events = { "BufLeave" },
      keys = { "q" },
    },
    enter = true,
    border = {
      style = "rounded",
    },
    position = "50%",
    size = {
      width = "120",
      height = "20",
    },
    win_options = {
      winhighlight = { Normal = "NoicePopup", FloatBorder = "NoicePopupBorder" },
      winbar = "",
      foldenable = false,
    },
  },
  cmdline = {
    backend = "popup",
    relative = "editor",
    position = {
      row = "100%",
      col = 0,
    },
    size = {
      height = "auto",
      width = "100%",
    },
    border = {
      style = "none",
    },
    win_options = {
      winhighlight = {
        Normal = "NoiceCmdline",
        IncSearch = "",
        CurSearch = "",
        Search = "",
      },
    },
  },
  mini = {
    backend = "mini",
    relative = "editor",
    align = "message-right",
    timeout = 2000,
    reverse = true,
    focusable = false,
    position = {
      row = -1,
      col = "100%",
      -- col = 0,
    },
    size = {
      width = "auto",
      height = "auto",
      max_height = 10,
    },
    border = {
      style = "none",
    },
    zindex = 60,
    win_options = {
      winbar = "",
      foldenable = false,
      winblend = 30,
      winhighlight = {
        Normal = "NoiceMini",
        IncSearch = "",
        CurSearch = "",
        Search = "",
      },
    },
  },
  cmdline_popup = {
    backend = "popup",
    relative = "editor",
    focusable = false,
    enter = false,
    zindex = 200,
    position = {
      row = "50%",
      col = "50%",
    },
    size = {
      min_width = 60,
      width = "auto",
      height = "auto",
    },
    border = {
      style = "rounded",
      padding = { 0, 1 },
    },
    win_options = {
      winhighlight = {
        Normal = "NoiceCmdlinePopup",
        FloatTitle = "NoiceCmdlinePopupTitle",
        FloatBorder = "NoiceCmdlinePopupBorder",
        IncSearch = "",
        CurSearch = "",
        Search = "",
      },
      winbar = "",
      foldenable = false,
      cursorline = false,
    },
  },
  cmdline_input = {
    view = "cmdline_popup",
    border = {
      style = "rounded",
      padding = { 0, 1 },
    },
  },
  confirm = {
    backend = "popup",
    relative = "editor",
    focusable = false,
    align = "center",
    enter = false,
    zindex = 210,
    format = { "{confirm}" },
    position = {
      row = 3,
      col = "50%",
    },
    size = "auto",
    border = {
      style = "rounded",
      padding = { 0, 1 },
      text = {
        top = " Confirm ",
      },
    },
    win_options = {
      winhighlight = {
        Normal = "NoiceConfirm",
        FloatBorder = "NoiceConfirmBorder",
      },
      winbar = "",
      foldenable = false,
    },
  },
}

return M

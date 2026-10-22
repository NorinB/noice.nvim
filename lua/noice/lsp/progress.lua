local require = require("noice.util.lazy")

local Config = require("noice.config")
local Manager = require("noice.message.manager")
local Message = require("noice.message")
local Router = require("noice.message.router")
local Util = require("noice.util")

local M = {}

M.spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
M.done = "✔"

---@class NoiceLspProgress
---@field message NoiceMessage
---@field client_id integer
---@field client string
---@field title? string
---@field text? string
---@field percentage? number
---@field done? boolean

---@type table<string, NoiceLspProgress>
M._progress = {}
---@type fun()|Interval?
M._timer = nil

function M.enable()
  -- the LspProgress event only exists since Neovim 0.10, and creating an autocmd
  -- for an unknown event throws, which would abort the rest of noice.enable()
  if vim.fn.has("nvim-0.10") == 0 then
    return
  end
  vim.api.nvim_create_autocmd("LspProgress", {
    group = vim.api.nvim_create_augroup("noice.lsp.progress", { clear = true }),
    callback = M.on_progress,
  })
  if M._timer then
    M._timer.stop()
  end
  M._timer = Util.interval(Config.options.lsp.progress.throttle, M.update, {
    enabled = function()
      return not vim.tbl_isempty(M._progress)
    end,
  })
end

function M.disable()
  vim.api.nvim_create_augroup("noice.lsp.progress", { clear = true })
  for id in pairs(M._progress) do
    M.close(id)
  end
end

---@param id string
function M.close(id)
  local progress = M._progress[id]
  if progress then
    M._progress[id] = nil
    Manager.remove(progress.message)
  end
end

-- The mini view keeps a routed message visible for `timeout` ms after it was
-- last rendered, so the finished message can leave the history right away.
---@param id string
function M.finish(id)
  local progress = M._progress[id]
  if progress then
    progress.done = true
    progress.percentage = nil
    M._progress[id] = nil
    M.render(progress)
    Router.update()
    Manager.remove(progress.message)
  end
end

function M.on_progress(event)
  local value = event.data.params.value
  if type(value) ~= "table" or not value.kind then
    return
  end

  local id = event.data.client_id .. ":" .. tostring(event.data.params.token)
  local progress = M._progress[id]

  if value.kind == "end" then
    if progress then
      progress.text = value.message or progress.text
      M.finish(id)
    end
    return
  end

  if not progress then
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      return
    end
    progress = {
      message = Message("lsp", "progress"),
      client_id = event.data.client_id,
      client = client.name,
    }
    M._progress[id] = progress
  end

  progress.title = value.title or progress.title
  progress.text = value.message or progress.text
  progress.percentage = value.percentage or progress.percentage

  M.render(progress)
  M._timer()
end

---@param progress NoiceLspProgress
function M.render(progress)
  local message = progress.message
  message:clear()

  if progress.done then
    message:append(M.done, "NoiceLspProgressSpinner")
  else
    local frame = math.floor((vim.uv or vim.loop).hrtime() / (1e6 * Config.options.lsp.progress.throttle)) % #M.spinner
      + 1
    message:append(M.spinner[frame], "NoiceLspProgressSpinner")
  end
  message:append(" ")

  if progress.percentage then
    message:append(("%3d%% "):format(progress.percentage))
  end
  if progress.title then
    message:append(progress.title, "NoiceLspProgressTitle")
    message:append(" ")
  end
  if progress.text then
    message:append(progress.text .. " ")
  end
  message:append(progress.client, "NoiceLspProgressClient")

  Manager.add(message)
end

function M.update()
  for id, progress in pairs(M._progress) do
    -- a client that dies between `begin` and `end` never clears its own token
    if not vim.lsp.get_client_by_id(progress.client_id) then
      M.close(id)
    else
      M.render(progress)
    end
  end
end

return M

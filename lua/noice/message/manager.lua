local require = require("noice.util.lazy")

local M = {}

local _tick = 1
local _history_count = 0

local function next_tick()
  _tick = _tick + 1
  return _tick
end

---@type table<number, NoiceMessage>
M._history = {}

---@type table<number, NoiceMessage>
M._messages = {}

function M.tick()
  return _tick
end

---@param message NoiceMessage
function M.add(message)
  if not (message:is_empty() and vim.tbl_isempty(message.opts)) then
    message.tick = next_tick()
    message.mtime = vim.fn.localtime()
    if M._history[message.id] == nil then
      _history_count = _history_count + 1
    end
    M._history[message.id] = message
    M._messages[message.id] = message
    M.prune_history()
  end
end

-- `ext_messages` routes every message through Noice, so the history would grow
-- for the whole session without this.
function M.prune_history()
  local max = require("noice.config").options.messages.history_max
  if _history_count <= max * 1.5 then
    return
  end
  local messages = {}
  for _, message in pairs(M._history) do
    messages[#messages + 1] = message
  end
  M.sort(messages)
  M._history = {}
  _history_count = 0
  for i = math.max(1, #messages - max + 1), #messages do
    M._history[messages[i].id] = messages[i]
    _history_count = _history_count + 1
  end
end

---@param message NoiceMessage
---@param opts? { history: boolean } # defaults to `{ history = false }`
function M.has(message, opts)
  opts = opts or {}
  return (opts.history and M._history or M._messages)[message.id] ~= nil
end

---@param message NoiceMessage
function M.remove(message)
  if M._history[message.id] then
    M._history[message.id] = nil
    _history_count = _history_count - 1
    next_tick()
  end
  if M._messages[message.id] then
    M._messages[message.id] = nil
    next_tick()
  end
  message:on_remove()
end

---@param filter? NoiceFilter
function M.clear(filter)
  M.with(function(message)
    M._messages[message.id] = nil
    next_tick()
  end, filter)
end

-- Sorts messages in-place by mtime & id
---@param messages NoiceMessage[]
function M.sort(messages, reverse)
  table.sort(
    messages,
    ---@param a NoiceMessage
    ---@param b NoiceMessage
    function(a, b)
      local ret = (a.mtime == b.mtime) and (a.id < b.id) or (a.mtime < b.mtime)
      if reverse then
        ret = not ret
      end
      return ret
    end
  )
end

function M.get_by_id(id)
  return M._history[id]
end

---@class NoiceMessageOpts
---@field history? boolean
---@field sort? boolean
---@field reverse? boolean
---@field count? number
---@field messages? NoiceMessage[]

---@param filter? NoiceFilter
---@param opts? NoiceMessageOpts
---@return NoiceMessage[]
function M.get(filter, opts)
  opts = opts or {}
  local messages = opts.messages or opts.history and M._history or M._messages
  local ret = {}
  for _, message in pairs(messages) do
    if not filter or message:is(filter) then
      table.insert(ret, message)
    end
  end
  if opts.sort then
    M.sort(ret, opts.reverse)
  end
  if opts.count and #ret > opts.count then
    local last = {}
    for i = #ret - opts.count + 1, #ret do
      table.insert(last, ret[i])
    end
    ret = last
  end
  return ret
end

---@param fn fun(message: NoiceMessage)
---@param filter? NoiceFilter
---@param opts? { history: boolean, sort: boolean } # defaults to `{ history = false, sort = false }`
function M.with(fn, filter, opts)
  for _, message in ipairs(M.get(filter, opts)) do
    fn(message)
  end
end

return M

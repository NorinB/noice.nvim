local require = require("noice.util.lazy")

local Block = require("noice.text.block")
local Filter = require("noice.message.filter")

---@alias NotifyLevel "trace"|"debug"|"info"|"warn"|"error"|"off"

local _id = 0

---@class NoiceMessage: NoiceBlock
---@field super NoiceBlock
---@field id number
---@field event NoiceEvent
---@field title? string
---@field ctime number
---@field mtime number
---@field tick number
---@field level? NotifyLevel
---@field kind? NoiceKind
---@field cmdline? NoiceCmdline
---@field _debug? boolean
---@field opts table<string, any>
---@field _buf_messages table<integer, table<number, true>>
---@overload fun(event: NoiceEvent, kind?: NoiceKind, content?: NoiceContent|NoiceContent[]): NoiceMessage
---@diagnostic disable-next-line: undefined-field
local Message = Block:extend("NoiceBlock")

Message._buf_messages = {}
vim.api.nvim_create_autocmd("BufDelete", {
  group = vim.api.nvim_create_augroup("noice.message", { clear = true }),
  callback = function(args)
    Message._buf_messages[args.buf] = nil
  end,
})

---@param event NoiceEvent
---@param kind? NoiceKind
---@param content? NoiceContent|NoiceContent[]
function Message:init(event, kind, content)
  _id = _id + 1
  self.id = _id
  self.tick = 1
  self.ctime = os.time()
  self.mtime = os.time()
  self.event = event
  self.kind = kind
  self.opts = {}
  Message.super.init(self, content)
end

function Message:on_remove()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if self:on_buf(buf) then
      self._buf_messages[buf][self.id] = nil
    end
  end
end

function Message:on_buf(buf)
  return self._buf_messages[buf] and not not self._buf_messages[buf][self.id]
end

function Message:_add_buf(buf)
  local msgs = self._buf_messages[buf] or {}
  msgs[self.id] = true
  self._buf_messages[buf] = msgs
end

---@param bufnr number buffer number
---@param ns_id number namespace id
---@param linenr_start? number line number (1-indexed)
function Message:highlight(bufnr, ns_id, linenr_start)
  self:_add_buf(bufnr)
  return Message.super.highlight(self, bufnr, ns_id, linenr_start)
end

---@param bufnr number buffer number
---@param ns_id number namespace id
---@param linenr_start? number start line number (1-indexed)
---@param linenr_end? number end line number (1-indexed)
function Message:render(bufnr, ns_id, linenr_start, linenr_end)
  self:_add_buf(bufnr)
  return Message.super.render(self, bufnr, ns_id, linenr_start, linenr_end)
end

Message.is = Filter.is

return Message

---The context a prompt is being made in.
---Stores editor state prior to showing input/select UI.
---@class AntigravityContext
---@field win integer
---@field buf integer
---@field cursor integer[] The cursor position: { row, col } (1,0-based)
---@field range? table Range of the selection: { from = { line, col }, to = { line, col }, kind = "char"|"line"|"block" }
local Context = {}
Context.__index = Context

local ns_id = vim.api.nvim_create_namespace("AntigravityContext")

---Get visual selection range
---@param buf integer
---@return table|nil
local function selection(buf)
  local mode = vim.fn.mode()
  local kind = (mode == "V" and "line") or (mode == "v" and "char") or (mode == "\22" and "block")
  if not kind then
    return nil
  end

  -- Exit visual mode for consistent marks
  if vim.fn.mode():match("[vV\22]") then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
  end

  local from = vim.api.nvim_buf_get_mark(buf, "<")
  local to = vim.api.nvim_buf_get_mark(buf, ">")
  if from[1] > to[1] or (from[1] == to[1] and from[2] > to[2]) then
    from, to = to, from
  end
  if kind == "block" and from[2] > to[2] then
    from[2], to[2] = to[2], from[2]
  end

  return {
    from = { from[1], from[2] },
    to = { to[1], to[2] },
    kind = kind,
  }
end

---Highlight the range in the editor buffer
---@param buf integer
---@param range table
local function highlight(buf, range)
  local from_row = range.from[1] - 1
  local from_col = range.from[2]

  if range.kind == "block" then
    local start_row = range.from[1] - 1
    local end_row = range.to[1] - 1
    local start_col = range.from[2]
    local end_col = range.to[2]
    for row = start_row, end_row do
      local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
      local clamp_col = math.min(end_col + 1, #line)
      if clamp_col > start_col then
        vim.api.nvim_buf_set_extmark(buf, ns_id, row, start_col, {
          end_col = clamp_col,
          hl_group = "Visual",
        })
      end
    end
  else
    local end_row = range.kind ~= "line" and range.to[1] - 1 or range.to[1]
    local end_col = nil
    if range.kind ~= "line" then
      local line = vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, false)[1] or ""
      end_col = math.min(range.to[2] + 1, #line)
    end
    vim.api.nvim_buf_set_extmark(buf, ns_id, from_row, from_col, {
      end_row = end_row,
      end_col = end_col,
      hl_group = "Visual",
    })
  end
end

---Create a new Context
---@param range? table
---@return AntigravityContext
function Context.new(range)
  local self = setmetatable({}, Context)
  self.win = vim.api.nvim_get_current_win()
  self.buf = vim.api.nvim_get_current_buf()
  self.cursor = vim.api.nvim_win_get_cursor(self.win)
  self.range = range or selection(self.buf)

  if self.range then
    highlight(self.buf, self.range)
  end

  return self
end

---Clear context highlights
function Context:clear()
  vim.api.nvim_buf_clear_namespace(self.buf, ns_id, 0, -1)
end

---Format file paths with line/col details
---@param loc string|integer Buffer ID or file path
---@param args? { start_line?: integer, start_col?: integer, end_line?: integer, end_col?: integer }
---@return string?
function Context.format(loc, args)
  local filepath = (type(loc) == "string" and loc) or (type(loc) == "number" and vim.api.nvim_buf_get_name(loc)) or nil
  if not filepath or filepath == "" then
    return nil
  end

  local result = vim.fn.fnamemodify(filepath, ":p")

  if args and args.start_line then
    if args.end_line and args.start_line > args.end_line then
      args.start_line, args.end_line = args.end_line, args.start_line
      if args.start_col and args.end_col then
        args.start_col, args.end_col = args.end_col, args.start_col
      end
    end

    result = result .. ":" .. string.format("L%d", args.start_line)
    if args.start_col then
      result = result .. string.format(":C%d", args.start_col)
    end
    if args.end_line then
      result = result .. string.format("-L%d", args.end_line)
      if args.end_col then
        result = result .. string.format(":C%d", args.end_col)
      end
    end
  end

  return result
end

---Get current code context (@this)
---@return string?
function Context:this()
  if self.range then
    return Context.format(self.buf, {
      start_line = self.range.from[1],
      start_col = (self.range.kind ~= "line") and self.range.from[2] or nil,
      end_line = (self.range.kind ~= "line" or self.range.from[1] ~= self.range.to[1]) and self.range.to[1] or nil,
      end_col = (self.range.kind ~= "line") and self.range.to[2] or nil,
    })
  else
    return Context.format(self.buf, {
      start_line = self.cursor[1],
      start_col = self.cursor[2] + 1,
    })
  end
end

---Get current buffer path (@buffer)
---@return string?
function Context:buffer()
  return Context.format(self.buf)
end

---Get list of all open buffers (@buffers)
---@return string?
function Context:buffers()
  local file_list = {}
  for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    local path = Context.format(buf.bufnr)
    if path then
      table.insert(file_list, path)
    end
  end
  if #file_list == 0 then
    return nil
  end
  return table.concat(file_list, ", ")
end

---Get visible text region of all open windows (@visible)
---@return string?
function Context:visible_text()
  local visible = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local location = Context.format(buf, {
        start_line = vim.fn.line("w0", win),
        end_line = vim.fn.line("w$", win),
      })
      if location then
        table.insert(visible, location)
      end
    end
  end
  if #visible == 0 then
    return nil
  end
  return table.concat(visible, ", ")
end

---Format single diagnostic
---@param diag vim.Diagnostic
---@return string
function Context.format_diagnostic(diag)
  local location = Context.format(diag.bufnr, {
    start_line = diag.lnum + 1,
    start_col = diag.col + 1,
    end_line = diag.end_lnum + 1,
    end_col = diag.end_col + 1,
  })
  return string.format(
    "%s (%s): %s",
    location or "unknown location",
    diag.source or "LSP",
    diag.message:gsub("%s+", " "):gsub("^%s", ""):gsub("%s$", "")
  )
end

---Get current buffer diagnostics (@diagnostics)
---@return string?
function Context:diagnostics()
  local diagnostics = vim.diagnostic.get(self.buf)
  if #diagnostics == 0 then
    return nil
  end

  local diag_strings = {}
  for _, diag in ipairs(diagnostics) do
    table.insert(diag_strings, "- " .. Context.format_diagnostic(diag))
  end

  return #diagnostics .. " diagnostics:\n" .. table.concat(diag_strings, "\n")
end

---Get current quickfix list entries (@quickfix)
---@return string?
function Context:quickfix()
  local qflist = vim.fn.getqflist()
  if #qflist == 0 then
    return nil
  end
  local lines = {}
  for _, entry in ipairs(qflist) do
    if entry.bufnr ~= 0 and vim.api.nvim_buf_get_name(entry.bufnr) ~= "" then
      table.insert(
        lines,
        Context.format(entry.bufnr, {
          start_line = entry.lnum,
          start_col = entry.col,
        })
      )
    end
  end
  if #lines == 0 then
    return nil
  end
  return table.concat(lines, ", ")
end

---Get git diff of current repository (@diff)
---@return string?
function Context:git_diff()
  local res = vim.system({ "git", "--no-pager", "diff" }, { text = true }):wait()
  if res.code ~= 0 or res.stdout == "" then
    return nil
  end
  return res.stdout
end

---Get global uppercase marks (@marks)
---@return string?
function Context:marks()
  local marks = {}
  for _, mark in ipairs(vim.fn.getmarklist()) do
    if mark.mark:match("^'[A-Z]$") then
      table.insert(
        marks,
        Context.format(mark.pos[1], {
          start_line = mark.pos[2],
          start_col = mark.pos[3],
        })
      )
    end
  end
  if #marks == 0 then
    return nil
  end
  return table.concat(marks, ", ")
end

---Render the prompt, replacing placeholders with their actual values
---@param prompt string
---@return string
function Context:render(prompt)
  local contexts = require("antigravity.config").opts.contexts or {}
  local rendered = prompt

  -- Sort keys descending by length so longer placeholders are matched first
  local sorted_keys = vim.tbl_keys(contexts)
  table.sort(sorted_keys, function(a, b) return #a > #b end)

  for _, placeholder in ipairs(sorted_keys) do
    if rendered:find(placeholder, 1, true) then
      local ok, val = pcall(contexts[placeholder], self)
      if ok and val then
        rendered = rendered:gsub(placeholder, vim.pesc(val))
      else
        -- Replace with empty or keep placeholder if failed/nil
        rendered = rendered:gsub(placeholder, "")
      end
    end
  end

  return rendered
end

return Context

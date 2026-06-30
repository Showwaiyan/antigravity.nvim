local M = {}

local function float_input(opts, on_confirm)
  local prompt = opts.prompt or " Ask Antigravity: "
  local default = opts.default or ""

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  local max_width = 80
  local width = math.min(max_width, vim.o.columns - 4)
  if width < 20 then width = 20 end

  local height = 1
  local row = math.floor((vim.o.lines - height) / 2) - 1
  if row < 0 then row = 0 end
  local col = math.floor((vim.o.columns - width) / 2)
  if col < 0 then col = 0 end

  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  }
  if vim.fn.has("nvim-0.9") == 1 then
    win_opts.title = " " .. vim.trim(prompt) .. " "
    win_opts.title_pos = "center"
  end

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  vim.wo[win].winhl = "Normal:NormalFloat,FloatBorder:FloatBorder"
  vim.wo[win].wrap = false
  vim.wo[win].sidescrolloff = 8

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { default })
  vim.api.nvim_win_set_cursor(win, { 1, #default })

  vim.cmd("startinsert!")

  local closed = false
  local function close(submit_val)
    if closed then return end
    closed = true

    if vim.fn.mode():sub(1, 1) == "i" then
      vim.cmd("stopinsert")
    end

    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end

    on_confirm(submit_val)
  end

  local map_opts = { buffer = buf, silent = true }

  vim.keymap.set({ "n", "i" }, "<CR>", function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    close(lines[1] or "")
  end, map_opts)

  vim.keymap.set("n", "<Esc>", function()
    close(nil)
  end, map_opts)

  vim.keymap.set("n", "q", function()
    close(nil)
  end, map_opts)

  vim.keymap.set({ "n", "i" }, "<C-c>", function()
    close(nil)
  end, map_opts)

  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    buffer = buf,
    callback = function()
      close(nil)
    end,
  })
end

---Prompt the user to ask Antigravity a custom question with editor context.
---@param default? string Optional default text to fill the input with.
---@param use_range? boolean Whether to capture visual selection range.
function M.ask(default, use_range)
  local context = require("antigravity.context").new(use_range)
  local ask_opts = require("antigravity.config").opts.ask or {}

  local default_val = default
  if not default_val or default_val == "" then
    default_val = "@this "
  end

  float_input({
    prompt = ask_opts.prompt or "Ask Antigravity: ",
    default = default_val,
  }, function(input)
    context:clear()

    if not input or vim.trim(input) == "" then
      context:clear()
      return
    end

    local query = input
    -- Auto-prepend @this if a selection range is active and no context placeholder is used
    if use_range and not query:find("@this", 1, true) and not query:find("@buffer", 1, true) and not query:find("@buffers", 1, true) then
      query = "@this " .. query
    end

    local rendered = context:render(query)
    if require("antigravity.config").opts.disable_links then
      rendered = rendered .. "\n(IMPORTANT: Do not generate markdown links or file:// URIs. Just output plain text names of files, classes, methods, and functions.)"
    end
    -- Launch agy interactively with the rendered prompt
    require("antigravity.terminal").open({ "-i", "--prompt", rendered })
  end)
end

---Select a predefined prompt to send to Antigravity.
---@param use_range? boolean Whether to capture visual selection range.
function M.select(use_range)
  local context = require("antigravity.context").new(use_range)
  local select_opts = require("antigravity.config").opts.select or {}
  local prompts = select_opts.prompts or {}

  local prompt_keys = vim.tbl_keys(prompts)
  table.sort(prompt_keys)

  local display_items = {}
  for _, key in ipairs(prompt_keys) do
    table.insert(display_items, string.format("%s: %s", key, prompts[key]))
  end

  vim.ui.select(display_items, {
    prompt = select_opts.prompt or "Antigravity prompt: ",
  }, function(choice)
    context:clear()

    if not choice then
      return
    end

    -- Extract prompt key
    local selected_key = choice:match("^([^:]+):")
    local selected_prompt = prompts[selected_key]

    if selected_prompt then
      local rendered = context:render(selected_prompt)
      if require("antigravity.config").opts.disable_links then
        rendered = rendered .. "\n(IMPORTANT: Do not generate markdown links or file:// URIs. Just output plain text names of files, classes, methods, and functions.)"
      end
      require("antigravity.terminal").open({ "-i", "--prompt", rendered })
    end
  end)
end

return M

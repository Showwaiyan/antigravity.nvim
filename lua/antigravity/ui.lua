local M = {}

---Prompt the user to ask Antigravity a custom question with editor context.
---@param default? string Optional default text to fill the input with.
---@param use_range? boolean Whether to capture visual selection range.
function M.ask(default, use_range)
  local context = require("antigravity.context").new(use_range)
  local ask_opts = require("antigravity.config").opts.ask or {}

  vim.ui.input({
    prompt = ask_opts.prompt or "Ask Antigravity: ",
    default = default or "",
  }, function(input)
    context:clear()

    if not input or vim.trim(input) == "" then
      context:clear()
      return
    end

    local rendered = context:render(input)
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
      require("antigravity.terminal").open({ "-i", "--prompt", rendered })
    end
  end)
end

return M

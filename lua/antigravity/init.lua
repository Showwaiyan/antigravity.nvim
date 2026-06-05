local M = {}

---Initialize the plugin config
---@param opts? AntigravityOpts
function M.setup(opts)
  require("antigravity.config").setup(opts)
end

---Prompt the user to ask a question with editor context
---@param default? string
---@param use_range? boolean
function M.ask(default, use_range)
  require("antigravity.ui").ask(default, use_range)
end

---Select from predefined prompts
---@param use_range? boolean
function M.select(use_range)
  require("antigravity.ui").select(use_range)
end

---Toggle the Antigravity CLI terminal split
---@param args? string[]
function M.toggle(args)
  require("antigravity.terminal").toggle(args)
end

---Force close the Antigravity CLI terminal split
function M.close()
  require("antigravity.terminal").close()
end

return M

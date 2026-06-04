local M = {}

---Initialize the plugin config
---@param opts? AntigravityOpts
function M.setup(opts)
  require("antigravity.config").setup(opts)
end

---Prompt the user to ask a question with editor context
---@param default? string
function M.ask(default)
  require("antigravity.ui").ask(default)
end

---Select from predefined prompts
function M.select()
  require("antigravity.ui").select()
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

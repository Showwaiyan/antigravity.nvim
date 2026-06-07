local M = {}

---@class AntigravityOpts
---@field cmd? string The command to invoke the Antigravity CLI (defaults to "agy").
---@field disable_links? boolean Whether to instruct the model to use plain text instead of clickable markdown links.
---@field contexts? table<string, fun(context: AntigravityContext): string|nil> Context functions.
---@field ask? { prompt?: string, split?: string, width?: number, height?: number } Ask options.
---@field select? { prompt?: string, prompts?: table<string, string> } Predefined prompt select options.

---@type AntigravityOpts
local defaults = {
  cmd = "agy",
  disable_links = false,
  contexts = {
    ["@this"] = function(ctx) return ctx:this() end,
    ["@buffer"] = function(ctx) return ctx:buffer() end,
    ["@buffers"] = function(ctx) return ctx:buffers() end,
    ["@visible"] = function(ctx) return ctx:visible_text() end,
    ["@diagnostics"] = function(ctx) return ctx:diagnostics() end,
    ["@quickfix"] = function(ctx) return ctx:quickfix() end,
    ["@diff"] = function(ctx) return ctx:git_diff() end,
    ["@marks"] = function(ctx) return ctx:marks() end,
  },
  ask = {
    prompt = "Ask Antigravity: ",
    split = "right",
    width = 0.4, -- 40% of columns
    height = 0.4, -- 40% of rows (if split is horizontal)
  },
  select = {
    prompt = "Antigravity prompt: ",
    prompts = {
      explain = "Explain @this and its context",
      fix = "Fix @diagnostics in @this",
      optimize = "Optimize @this for performance and readability",
      review = "Review @this for correctness and readability",
      test = "Add tests for @this",
      diff = "Review the following git diff for correctness and readability: @diff",
    },
  },
}

---@type AntigravityOpts
M.opts = vim.deepcopy(defaults)

---Setup the plugin options.
---@param user_opts? AntigravityOpts
function M.setup(user_opts)
  M.opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), user_opts or {})
end

return M

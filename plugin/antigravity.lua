if vim.g.loaded_antigravity == 1 then
  return
end
vim.g.loaded_antigravity = 1

-- Register user commands
vim.api.nvim_create_user_command("AntigravityAsk", function(opts)
  local default_text = opts.args
  if default_text == "" then
    default_text = nil
  end
  require("antigravity").ask(default_text)
end, {
  nargs = "?",
  range = true,
  desc = "Ask Antigravity a question with editor context",
})

vim.api.nvim_create_user_command("AntigravitySelect", function()
  require("antigravity").select()
end, {
  range = true,
  desc = "Select and run a predefined Antigravity prompt",
})

vim.api.nvim_create_user_command("AntigravityToggle", function()
  require("antigravity").toggle()
end, {
  desc = "Toggle the Antigravity terminal split",
})

vim.api.nvim_create_user_command("AntigravityClose", function()
  require("antigravity").close()
end, {
  desc = "Force close the Antigravity terminal split",
})

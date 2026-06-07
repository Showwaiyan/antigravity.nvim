local M = {}

local win_id = nil
local buf_id = nil
local job_id = nil

---Create the window split based on config
---@private
function M.create_window()
  local config = require("antigravity.config").opts.ask
  local split = config.split or "right"
  local width = config.width or 0.4
  local height = config.height or 0.4

  local columns = vim.o.columns
  local rows = vim.o.lines

  local win_w = (width < 1) and math.floor(columns * width) or width
  local win_h = (height < 1) and math.floor(rows * height) or height

  local split_cmd = ""
  if split == "right" then
    split_cmd = "vertical botright " .. win_w .. "split"
  elseif split == "left" then
    split_cmd = "vertical topleft " .. win_w .. "split"
  elseif split == "above" then
    split_cmd = "topleft " .. win_h .. "split"
  elseif split == "below" then
    split_cmd = "botright " .. win_h .. "split"
  else
    split_cmd = "vertical botright " .. win_w .. "split"
  end

  vim.cmd(split_cmd)
  win_id = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win_id, buf_id)
end

---Open a terminal running the antigravity CLI
---@param args? string[] Arguments to pass to agy (e.g. {"-i", "--prompt", "..."})
function M.open(args)
  -- If buffer already exists and is valid, show it
  -- If buffer already exists and is valid, show it
  if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
    if job_id then
      if not win_id or not vim.api.nvim_win_is_valid(win_id) then
        M.create_window()
      else
        vim.api.nvim_set_current_win(win_id)
      end
      vim.cmd("startinsert")

      -- Send the new prompt if provided
      if args then
        local prompt_val = nil
        for i, arg in ipairs(args) do
          if arg == "--prompt" then
            prompt_val = args[i + 1]
            break
          end
        end
        if prompt_val then
          vim.api.nvim_chan_send(job_id, prompt_val .. "\r")
        end
      end
      return
    else
      -- Job is dead, clean up before starting a new one
      M.close()
    end
  end

  -- Build cmd array
  local base_cmd = require("antigravity.config").opts.cmd or "agy"
  local cmd = { base_cmd }
  local final_args = args or {}
  if #final_args == 0 and require("antigravity.config").opts.disable_links then
    final_args = { "-i", "--prompt", "(IMPORTANT: Do not generate markdown links or file:// URIs. Just output plain text names of files, classes, methods, and functions.)" }
  end
  for _, arg in ipairs(final_args) do
    table.insert(cmd, arg)
  end

  -- Create a new scratch buffer for the terminal
  buf_id = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf_id, "Antigravity")

  -- Create the window split and set the buffer
  M.create_window()

  -- Run termopen
  job_id = vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code, _)
      job_id = nil
      if exit_code ~= 0 then
        vim.notify("Antigravity process exited with code " .. exit_code, vim.log.levels.ERROR)
      else
        M.close()
      end
    end
  })

  -- Set buffer properties
  vim.bo[buf_id].filetype = "antigravity"

  -- Allow standard window navigation directly from terminal mode
  local map_opts = { buffer = buf_id, silent = true }
  vim.keymap.set("t", "<C-w>h", [[<C-\><C-n><C-w>h]], map_opts)
  vim.keymap.set("t", "<C-w>j", [[<C-\><C-n><C-w>j]], map_opts)
  vim.keymap.set("t", "<C-w>k", [[<C-\><C-n><C-w>k]], map_opts)
  vim.keymap.set("t", "<C-w>l", [[<C-\><C-n><C-w>l]], map_opts)
  vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], map_opts)
  vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], map_opts)

  -- Start in terminal insert mode
  vim.cmd("startinsert")
end

---Toggle the antigravity terminal window
---@param args? string[] Arguments to pass if spawning
function M.toggle(args)
  if win_id and vim.api.nvim_win_is_valid(win_id) then
    vim.api.nvim_win_close(win_id, true)
    win_id = nil
  else
    M.open(args)
  end
end

---Force close and clean up terminal job and buffer
function M.close()
  if job_id then
    pcall(vim.fn.jobstop, job_id)
    job_id = nil
  end
  if win_id and vim.api.nvim_win_is_valid(win_id) then
    pcall(vim.api.nvim_win_close, win_id, true)
    win_id = nil
  end
  if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
    pcall(vim.api.nvim_buf_delete, buf_id, { force = true })
    buf_id = nil
  end
end

return M

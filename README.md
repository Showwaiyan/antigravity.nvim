# antigravity.nvim

An elegant Neovim integration for Google's agentic AI coding assistant, **Antigravity** (CLI command: `agy`).

`antigravity.nvim` allows you to interact with the Antigravity agent directly from your Neovim session. It automatically gathers editor context (like visual selections, diagnostic lists, buffers, and git diffs) and formats it as placeholders for the CLI prompts.

## Features

- **Interactive Terminal Split**: Runs the `agy` CLI within a Neovim `:terminal` buffer, allowing you to see the agent's actions and chat with it in real-time.
- **Context-Aware Prompts**: Automatically replaces placeholders with your active editor state:
  - `@this` - Current line/range under cursor (or active visual selection)
  - `@buffer` - Path of the current buffer
  - `@buffers` - Path of all open buffers
  - `@visible` - Visible text range across all open windows
  - `@diagnostics` - Diagnostics (LSP errors/warnings) in the current buffer
  - `@quickfix` - Active quickfix list entries
  - `@diff` - Output of `git diff`
  - `@marks` - Uppercase global marks
- **Interactive UI Input (`:AntigravityAsk`)**: Type a question, use placeholders, and the plugin renders the context and executes `agy` in a split.
- **Preset Selection (`:AntigravitySelect`)**: Select from customizable preset commands like code explanation, diagnostic fixing, optimization, tests, and diff review.

---

## Installation

### Dependencies

Ensure you have the Antigravity CLI (`agy`) installed and authenticated on your machine:
```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

### Neovim Setup

Install using your preferred package manager (e.g. `lazy.nvim`):

```lua
-- lazy.nvim
{
  "Showwaiyan/antigravity.nvim",
  config = function()
    require("antigravity").setup({
      -- Optional configuration overrides
      cmd = "agy",
      ask = {
        split = "right", -- "right", "left", "above", "below"
        width = 0.4,     -- fractional width (40%) or absolute column count
      }
    })
  end,
  keys = {
    { "<leader>aa", "<cmd>AntigravityAsk<cr>", desc = "Ask Antigravity (Normal Mode)" },
    { "<leader>aa", ":AntigravityAsk ", mode = "v", desc = "Ask Antigravity (Visual Selection)" },
    { "<leader>as", "<cmd>AntigravitySelect<cr>", desc = "Select Preset Prompt (Normal Mode)" },
    { "<leader>as", ":AntigravitySelect<cr>", mode = "v", desc = "Select Preset Prompt (Visual Selection)" },
    { "<leader>at", "<cmd>AntigravityToggle<cr>", desc = "Toggle Antigravity Terminal" },
  }
}
```

---

## Commands

- `:AntigravityAsk [<prompt>]`: Asks Antigravity a custom question. If a prompt is provided, it is sent directly; otherwise, a dialog asks for your input. Supports visual mode range.
- `:AntigravitySelect`: Opens a selection menu with predefined prompts. Supports visual mode range.
- `:AntigravityToggle`: Opens or closes the terminal split running the current `agy` session.
- `:AntigravityClose`: Closes the terminal split and terminates the current `agy` session.

---

## Testing inside Docker

A `Dockerfile` is included in the repository for sandbox testing with both Neovim (v0.10.0) and the Antigravity CLI installed.

### 1. Build the Docker Image
```bash
docker build -t antigravity-nvim .
```

### 2. Run the Container Interactively
To run the container and automatically launch Neovim with the plugin loaded:
```bash
docker run -it antigravity-nvim
```

Inside Neovim, you can run commands like:
- `:AntigravityAsk Explain this repository structure`
- `:AntigravitySelect`
- `:AntigravityToggle`
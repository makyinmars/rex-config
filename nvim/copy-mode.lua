-- Minimal Neovim for Rex's copy mode (the copy_mode action, Leader [). It
-- loads no plugins, so it opens instantly.
--
--   v / V / Ctrl-V, then move   select
--   y or Enter                  copy the selection to the clipboard and close
--   yy, yiw, y}, ...            copy and close, as any yank does
--   / ? n N                     search
--   q                           close without copying

---@diagnostic disable: undefined-global -- this file runs in Neovim, which provides `vim`

vim.o.clipboard = "unnamedplus"
vim.o.swapfile = false
vim.o.shadafile = "NONE"
vim.o.number = false
vim.o.relativenumber = true
vim.o.signcolumn = "no"
vim.o.shortmess = vim.o.shortmess .. "FIWc"
vim.o.laststatus = 2
vim.o.statusline = "%#Comment# COPY  v select · y/Enter copy and close · q close%=%l/%L "
vim.o.wrap = false
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = true
vim.o.scrolloff = 4
vim.o.termguicolors = true
vim.o.background = "dark"
pcall(vim.cmd.colorscheme, "retrobox") -- Neovim's built-in Gruvbox

vim.keymap.set("x", "<CR>", "y")
vim.keymap.set("n", "q", "<Cmd>qa!<CR>")
vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR>")

-- Any yank closes copy mode once the clipboard has the text.
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    if vim.v.event.operator == "y" then
      vim.schedule(function()
        vim.cmd("qa!")
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.bo.modifiable = false
  end,
})

-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Usar Telescope como picker
vim.g.lazyvim_picker = "telescope"

-- El "proyecto" es siempre la carpeta con la que abres nvim (como IntelliJ/VSCode),
-- en vez de cambiar de raíz según el archivo/LSP
vim.g.root_spec = { "cwd" }

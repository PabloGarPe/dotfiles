-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Al abrir una carpeta (`nvim .` o `nvim ~/proyecto`): fijarla como directorio
-- de trabajo, restaurar la sesión anterior de esa carpeta y abrir el explorador
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("ide_open_folder", { clear = true }),
  nested = true,
  callback = function()
    local arg = vim.fn.argv(0)
    if vim.fn.argc() ~= 1 or vim.fn.isdirectory(arg) == 0 then
      return
    end
    local dirbuf = vim.api.nvim_get_current_buf()
    vim.cmd.cd(vim.fn.fnameescape(arg))
    require("persistence").load()
    -- Quitar el buffer de la carpeta (si la sesión no tenía archivos, queda uno vacío)
    if vim.api.nvim_get_current_buf() == dirbuf then
      vim.cmd.enew()
    end
    pcall(vim.api.nvim_buf_delete, dirbuf, { force = true })
    vim.cmd("Neotree show")
  end,
})

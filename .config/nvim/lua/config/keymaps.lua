-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Ir directamente a la pestaña N con Alt+1..9 (Alt+0 = última)
for i = 1, 9 do
  map("n", "<A-" .. i .. ">", "<cmd>BufferLineGoToBuffer " .. i .. "<cr>", { desc = "Ir al buffer " .. i })
end
map("n", "<A-0>", "<cmd>BufferLineGoToBuffer -1<cr>", { desc = "Ir al último buffer" })

-- Pestaña siguiente/anterior y moverlas de sitio
map("n", "<A-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Buffer siguiente" })
map("n", "<A-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Buffer anterior" })
map("n", "<A-L>", "<cmd>BufferLineMoveNext<cr>", { desc = "Mover buffer a la derecha" })
map("n", "<A-H>", "<cmd>BufferLineMovePrev<cr>", { desc = "Mover buffer a la izquierda" })

-- Cerrar la pestaña actual sin romper la ventana
map("n", "<A-w>", function()
  Snacks.bufdelete()
end, { desc = "Cerrar buffer" })

-- Atajos estilo VSCode
map("n", "<C-p>", "<cmd>Telescope find_files<cr>", { desc = "Buscar archivo" })
map("n", "<A-e>", "<cmd>Telescope buffers<cr>", { desc = "Buffers abiertos" })
map("n", "<C-b>", "<cmd>Neotree toggle<cr>", { desc = "Mostrar/ocultar explorador" })

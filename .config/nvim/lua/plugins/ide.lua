return {
  -- Explorador lateral fijo en la carpeta del proyecto
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        bind_to_cwd = true,
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        hijack_netrw_behavior = "disabled",
        filtered_items = { visible = true, hide_dotfiles = false, hide_gitignored = false },
      },
      window = { width = 32 },
    },
  },

  -- Pestañas de buffers siempre visibles, con números para saltar con Alt+N
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        always_show_bufferline = true,
        numbers = "ordinal",
      },
    },
  },

  -- Telescope: la lista de buffers ordenada por uso reciente, saltando el actual
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      pickers = {
        buffers = {
          sort_mru = true,
          ignore_current_buffer = true,
          mappings = { i = { ["<C-d>"] = "delete_buffer" }, n = { ["dd"] = "delete_buffer" } },
        },
      },
    },
  },
}

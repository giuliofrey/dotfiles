-- Explorer as a big centred float, same shape as the lazygit window.
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          -- The sidebar is meant to stay open; a float that lingers after you
          -- pick a file is just in the way.
          auto_close = true,
          jump = { close = true },
          layout = {
            preset = "default", -- tree left, preview right, backdrop on
            preview = true, -- the sidebar preset draws preview in the main window
            -- min_width overrides the preset's hardcoded 120 columns, which
            -- would otherwise overflow a narrow tmux pane.
            layout = { width = 0.9, height = 0.9, min_width = 0 },
          },
        },
      },
    },
  },
}

return {
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        per_filetype = {
          tex = function()
            local line = vim.api.nvim_get_current_line()
            local col = vim.api.nvim_win_get_cursor(0)[2]
            return line:sub(1, col):match("\\[%a@]*$") and { "lsp", "snippets" } or {}
          end,
        },
      },
    },
  },
}

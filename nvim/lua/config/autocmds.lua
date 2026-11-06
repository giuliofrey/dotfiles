-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Autosave: write real file buffers as soon as an edit lands (leaving insert, normal-mode edits, focus loss).
-- ponytail: plain autocmd; switch to okuuva/auto-save.nvim if you want debounce or per-keystroke saves.
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "FocusLost", "BufLeave" }, {
  group = vim.api.nvim_create_augroup("autosave", { clear = true }),
  callback = function(ev)
    local bo = vim.bo[ev.buf]
    if bo.buftype == "" and bo.modifiable and not bo.readonly and vim.api.nvim_buf_get_name(ev.buf) ~= "" then
      vim.api.nvim_buf_call(ev.buf, function() vim.cmd("silent! lockmarks update") end)
    end
  end,
})

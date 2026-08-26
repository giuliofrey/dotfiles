-- herdr's nvim side: comment a line, then push those comments into the agent's
-- input. The herdr half is installed separately (`herdr plugin install
-- ChmaraX/herdr-nvim`) and bound to prefix+e / prefix+o in herdr/config.toml.
return {
  "ChmaraX/herdr-nvim",
  -- The default prefix is <leader>a, which is LazyVim's +ai group: the
  -- claudecode extra already owns <leader>ac and <leader>as, the exact two keys
  -- this plugin wants. <leader>h is free here (harpoon2 is the only extra that
  -- claims it, and it is not enabled).
  opts = { prefix = "<leader>h" },
}

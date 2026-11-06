-- herdr's nvim side: comment a line, then push those comments into the agent's
-- input. The herdr half is installed separately (`herdr plugin install
-- ChmaraX/herdr-nvim`) and bound to prefix+e / prefix+o in herdr/config.toml.
return {
  "ChmaraX/herdr-nvim",
  -- Keep herdr separate from Sidekick's <leader>a shortcuts.
  -- <leader>h is free here (the harpoon2 extra is not enabled).
  opts = { prefix = "<leader>h" },
}

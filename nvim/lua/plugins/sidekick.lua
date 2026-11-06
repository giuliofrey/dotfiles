return {
  "folke/sidekick.nvim",
  cmd = "Sidekick",
  opts = {
    nes = { enabled = false },
  },
  keys = {
    {
      "<leader>aa",
      function() require("sidekick.cli").toggle() end,
      desc = "Toggle Sidekick",
    },
    {
      "<leader>as",
      function() require("sidekick.cli").select({ filter = { installed = true } }) end,
      desc = "Select Sidekick CLI",
    },
    {
      "<leader>at",
      function() require("sidekick.cli").send({ msg = "{this}" }) end,
      mode = { "n", "x" },
      desc = "Send this to Sidekick",
    },
    {
      "<leader>ap",
      function() require("sidekick.cli").prompt() end,
      mode = { "n", "x" },
      desc = "Sidekick prompt",
    },
  },
}

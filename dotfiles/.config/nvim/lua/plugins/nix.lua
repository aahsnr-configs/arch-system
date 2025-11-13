return {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, { "nix" })
      end
    end,
  },
  {
    "AstroNvim/astrolsp",
    optional = true,
    opts = function(_, opts)
      opts.servers = require("astrocore").list_insert_unique(opts.servers, { "nil_ls" })
      -- Add LSP configuration for nil_ls
      opts.config = opts.config or {}
      opts.config.nil_ls = {
        settings = {
          ["nil"] = {
            nix = {
              flake = {
                autoArchive = false, -- Disable automatic archiving
              },
            },
          },
        },
      }
    end,
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        nix = { "statix", "deadnix" },
      },
    },
  },
}

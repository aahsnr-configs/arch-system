return {
  {
    "AstroNvim/astrolsp",
    opts = {
      -- FIX: Explicitly register bashls so lspconfig attaches to the system binary
      -- (Since Mason is no longer auto-setting it up)
      servers = { "bashls" },
      config = {
        bashls = {
          filetypes = { "sh", "bash", "zsh" },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      -- NOTE: Treesitter parsers are internal to Neovim (not external tools).
      -- We keep this to ensure syntax highlighting works.
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, { "bash" })
      end
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    optional = true,
    opts = function(_, opts)
      -- Removed ensure_installed logic. Mason will not install bashls.
    end,
  },
  {
    "jay-babu/mason-null-ls.nvim",
    optional = true,
    opts = function(_, opts)
      -- Removed ensure_installed logic. Mason will not install shfmt/shellcheck.
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = function(_, opts)
      -- Removed ensure_installed logic. Mason will not install debug adapters.
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        sh = { "shfmt", "shellcheck" },
        zsh = { "shfmt", "shellcheck" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        sh = { "shellcheck" },
        zsh = { "shellcheck" },
      },
    },
  },
}

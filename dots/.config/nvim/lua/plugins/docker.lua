return {
  -- Treesitter: Syntax highlighting for Dockerfile and YAML
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "dockerfile",
        "yaml",
      },
    },
  },

  -- -- Mason: Ensure hadolint is installed
  -- {
  --   "williamboman/mason.nvim",
  --   opts = {
  --     ensure_installed = {
  --       "hadolint",
  --     },
  --   },
  -- },

  -- LSP: Docker Language Servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Docker Language Server for Dockerfiles
        dockerls = {
          settings = {
            docker = {
              languageserver = {
                formatter = {
                  ignoreMultilineInstructions = true,
                },
              },
            },
          },
        },
        -- Docker Compose Language Service
        docker_compose_language_service = {},
      },
    },
  },

  -- Linting: Hadolint for Dockerfile best practices (none-ls)
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local nls = require "null-ls"
      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.diagnostics.hadolint,
      })
    end,
  },

  -- Linting: Hadolint for Dockerfile best practices (nvim-lint)
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        dockerfile = { "hadolint" },
      },
    },
  },

  -- Filetype detection for docker-compose files
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = {
          "docker-compose.yml",
          "docker-compose.yaml",
          "compose.yml",
          "compose.yaml",
          "**/docker-compose*.yml",
          "**/docker-compose*.yaml",
        },
        callback = function() vim.bo.filetype = "yaml.docker-compose" end,
      })
    end,
  },
}

--if true then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return function()
  -- 1. Custom Filetype Detection
  -- Maps .container files to the 'ini' parser (standard for systemd/Quadlet formats)
  vim.filetype.add {
    extension = {
      container = "ini",
    },
  }

  -- 2. Your Existing Keymaps
  -- Note: Moving this inside the polish function ensures it runs correctly during setup
  vim.api.nvim_set_keymap("x", "p", '"_dp', { noremap = true, silent = true })

  -- You can add any other pure Lua code below
end
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

--if true then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  vim.api.nvim_set_keymap("x", "p", '"_dp', { noremap = true, silent = true }),
}

-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

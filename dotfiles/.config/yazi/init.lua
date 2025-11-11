-- ===========================
-- Full Border Configuration
-- ===========================
require("full-border"):setup {
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
}

-- ===========================
-- Starship Prompt Configuration
-- ===========================
require("starship"):setup({
  -- Hide flags for cleaner look with full-width starship themes
  hide_flags = false,
  -- Place flags after the starship prompt
  flags_after_prompt = true,
  -- Custom starship config file (optional)
  -- config_file = "~/.config/starship.toml",
})

-- ===========================
-- Git Plugin Configuration
-- ===========================
require("git"):setup({
  -- Use Git linemode for showing git status
})

-- ===========================
-- Yamb Bookmarks Configuration
-- ===========================
-- Configure yamb with your preferred bookmarks
local bookmarks = {}
local path_sep = package.config:sub(1, 1)
local home_path = os.getenv("HOME")

-- Add your custom bookmarks here
-- Syntax: { tag = "Label", path = "/full/path/", key = "x" }
table.insert(bookmarks, { tag = "Home", path = home_path .. path_sep, key = "h" })
table.insert(bookmarks, { tag = "Downloads", path = home_path .. path_sep .. "Downloads" .. path_sep, key = "d" })
table.insert(bookmarks, { tag = "Documents", path = home_path .. path_sep .. "Documents" .. path_sep, key = "D" })
table.insert(bookmarks, { tag = "Desktop", path = home_path .. path_sep .. "Desktop" .. path_sep, key = "t" })
table.insert(bookmarks, { tag = "Config", path = home_path .. path_sep .. ".config" .. path_sep, key = "c" })
table.insert(bookmarks, { tag = "Projects", path = home_path .. path_sep .. "Projects" .. path_sep, key = "p" })
table.insert(bookmarks, { tag = "Root", path = path_sep, key = "r" })

require("yamb"):setup {
  bookmarks = bookmarks,
  jump_notify = true,  -- Show notification when jumping to bookmark
  cli = "fzf",  -- Use fzf for fuzzy finding
  keys = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
  path = home_path .. "/.config/yazi/bookmark",  -- Persistence path
}

-- ===========================
-- Yatline Status Line Configuration
-- ===========================
require("yatline"):setup({
	-- Custom theme (optional, uncomment to use)
	--theme = my_theme,

	-- Separators
	section_separator = { open = "", close = "" },
	part_separator = { open = "", close = "" },
	inverse_separator = { open = "", close = "" },

	-- Style configurations
	style_a = {
		fg = "black",
		bg_mode = {
			normal = "white",
			select = "brightyellow",
			un_set = "brightred"
		}
	},
	style_b = { bg = "brightblack", fg = "brightwhite" },
	style_c = { bg = "black", fg = "brightwhite" },

	-- Permission colors
	permissions_t_fg = "green",
	permissions_r_fg = "yellow",
	permissions_w_fg = "red",
	permissions_x_fg = "cyan",
	permissions_s_fg = "white",

	-- Tab settings
	tab_width = 20,
	tab_use_inverse = false,

	-- Icon configurations
	selected = { icon = "", fg = "yellow" },
	copied = { icon = "", fg = "green" },
	cut = { icon = "", fg = "red" },
	total = { icon = "", fg = "yellow" },
	succ = { icon = "", fg = "green" },
	fail = { icon = "", fg = "red" },
	found = { icon = "", fg = "blue" },
	processed = { icon = "", fg = "green" },

	-- Display settings
	show_background = true,
	display_header_line = true,
	display_status_line = true,

	-- Component positioning
	component_positions = { "header", "tab", "status" },

	-- Header line configuration
	header_line = {
		left = {
			section_a = {
        			{type = "line", custom = false, name = "tabs", params = {"left"}},
			},
			section_b = {},
			section_c = {}
		},
		right = {
			section_a = {
        			{type = "string", custom = false, name = "date", params = {"%A, %d %B %Y"}},
			},
			section_b = {
        			{type = "string", custom = false, name = "date", params = {"%X"}},
			},
			section_c = {}
		}
	},

	-- Status line configuration
	status_line = {
		left = {
			section_a = {
        			{type = "string", custom = false, name = "tab_mode"},
			},
			section_b = {
        			{type = "string", custom = false, name = "hovered_size"},
			},
			section_c = {
        			{type = "string", custom = false, name = "hovered_path"},
        			{type = "coloreds", custom = false, name = "count"},
			}
		},
		right = {
			section_a = {
        			{type = "string", custom = false, name = "cursor_position"},
			},
			section_b = {
        			{type = "string", custom = false, name = "cursor_percentage"},
			},
			section_c = {
        			{type = "string", custom = false, name = "hovered_file_extension", params = {true}},
        			{type = "coloreds", custom = false, name = "permissions"},
			}
		}
	},
})

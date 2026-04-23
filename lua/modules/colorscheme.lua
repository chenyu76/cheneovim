-- State management for theme rotation
local state_path = vim.fn.stdpath("data") .. "/theme_state.json"

local function load_state()
	local f = io.open(state_path, "r")
	if not f then
		return { family_idx = 1, variant_indices = {} }
	end
	local content = f:read("*a")
	f:close()
	local ok, state = pcall(vim.fn.json_decode, content)
	if not ok or type(state) ~= "table" then
		return { family_idx = 1, variant_indices = {} }
	end
	return state
end

local function save_state(state)
	local f = io.open(state_path, "w")
	if f then
		f:write(vim.fn.json_encode(state))
		f:close()
	end
end

-- Theme configuration: Add more families or variants here for extensibility
local theme_groups = {
	{
		family = "tokyonight",
		variants = { "tokyonight-storm", "tokyonight-moon" },
		link = "https://github.com/folke/tokyonight.nvim",
		setup = function()
			require("tokyonight").setup({
				style = "storm",
			})
		end,
	},
	{
		family = "catppuccin",
		variants = { "catppuccin-frappe", "catppuccin-macchiato", "catppuccin-mocha" },
		link = "https://github.com/catppuccin/nvim",
		setup = function()
			require("catppuccin").setup({
				term_colors = true,
			})
		end,
	},
	{
		family = "nord",
		variants = { "nord" },
		link = "https://github.com/shaunsingh/nord.nvim",
		setup = function() end,
	},
}

-- Selection logic to alternate families and rotate variants
local function get_next_theme()
	local state = load_state()
	local family_idx = state.family_idx or 1
	if family_idx > #theme_groups then
		family_idx = 1
	end

	local variant_indices = state.variant_indices or {}
	local group = theme_groups[family_idx]

	local family_key = tostring(family_idx)
	local variant_idx = variant_indices[family_key] or 1
	if variant_idx > #group.variants then
		variant_idx = 1
	end

	local selected_theme = group.variants[variant_idx]

	-- Update state for next startup
	state.family_idx = (family_idx % #theme_groups) + 1
	variant_indices[family_key] = (variant_idx % #group.variants) + 1
	state.state_version = (state.state_version or 0) + 1
	state.variant_indices = variant_indices
	save_state(state)

	return group, selected_theme
end

-- Build the list of plugin specifications for lazy.nvim
local links = {}
for _, group in ipairs(theme_groups) do
	table.insert(links, group.link)
end
vim.pack.add(links)

-- Identify the theme for the current session
local group, current_variant = get_next_theme()
group.setup()
vim.cmd.colorscheme(current_variant)
-- pcall(vim.cmd.colorscheme, current_variant)

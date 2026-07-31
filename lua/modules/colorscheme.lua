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
	-- {
	-- 	family = "nord",
	-- 	variants = { "nord" },
	-- 	link = "https://github.com/shaunsingh/nord.nvim",
	-- 	setup = function() end,
	-- },
}

local function get_theme()
	local themes = {}
	for _, group in ipairs(theme_groups) do
		for _, variant in ipairs(group.variants) do
			table.insert(themes, { group = group, variant = variant })
		end
	end

	local first_arg = vim.fn.argv(0)
	local selection_key
	if first_arg ~= "" then
		selection_key = vim.fn.fnamemodify(first_arg, ":t")
	else
		selection_key = vim.fn.getcwd()
	end

	local theme_idx = (vim.fn.strchars(selection_key) % #themes) + 1
	return themes[theme_idx].group, themes[theme_idx].variant
end

-- Build the list of plugin specifications for lazy.nvim
local links = {}
for _, group in ipairs(theme_groups) do
	table.insert(links, group.link)
end
vim.pack.add(links)

-- Select a stable theme from the first file name, or the current directory
-- when Neovim starts without a file.
local group, current_variant = get_theme()
group.setup()
vim.cmd.colorscheme(current_variant)
-- pcall(vim.cmd.colorscheme, current_variant)

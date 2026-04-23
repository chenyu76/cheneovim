-- INFO: fuzzy finder
vim.pack.add({
	"https://github.com/nvim-lua/plenary.nvim", -- library dependency
	"https://github.com/nvim-tree/nvim-web-devicons", -- icons (nerd font)
	"https://github.com/nvim-telescope/telescope.nvim", -- the fuzzy finder
}, { confirm = false })

require("telescope").setup({})

local pickers = require("telescope.builtin")

vim.keymap.set("n", "<leader>sp", pickers.builtin, { desc = "[S]earch Builtin [P]ickers" })
vim.keymap.set("n", "<leader>sb", pickers.buffers, { desc = "[S]earch [B]uffers" })
vim.keymap.set("n", "<leader>sf", pickers.find_files, { desc = "[S]earch [F]iles" })
vim.keymap.set("n", "<leader>sw", pickers.grep_string, { desc = "[S]earch Current [W]ord" })
vim.keymap.set("n", "<leader>sg", pickers.live_grep, { desc = "[S]earch by [G]rep" })
vim.keymap.set("n", "<leader>sr", pickers.resume, { desc = "[S]earch [R]esume" })

vim.keymap.set("n", "<leader>sh", pickers.help_tags, { desc = "[S]earch [H]elp" })
vim.keymap.set("n", "<leader>sm", pickers.man_pages, { desc = "[S]earch [M]anuals" })

-- INFO: better statusline
vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" }, { confirm = false })

require("lualine").setup({
	options = {
		section_separators = { left = "", right = "" },
		component_separators = { left = "", right = "" },
	},
})

vim.pack.add({
	-- auto pairs
	"https://github.com/windwp/nvim-autopairs",
	-- This plugin adds indentation guides to Neovim. It uses Neovim's virtual text feature and no conceal
	"https://github.com/lukas-reineke/indent-blankline.nvim",
}, { confirm = false })

require("nvim-autopairs").setup()
require("ibl").setup()

vim.pack.add({
	--denpendencies
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/MunifTanjim/nui.nvim",
	"https://github.com/s1n7ax/nvim-window-picker",
	-- file manager
	"https://github.com/nvim-neo-tree/neo-tree.nvim",
}, { confirm = false })

require("neo-tree").setup({
	filesystem = {
		filtered_items = {
			hide_by_pattern = {
				"*.aux",
				"*.log",
				"*.out",
				"*.toc",
				"*.nav",
				"*.snm",
				"*.dvi",
				"*.fdb_latexmk",
				"*.fls",
				"*.synctex",
				"*.synctex.gz",
			},
		},
		window = {
			width = 25,
			mappings = {
				["\\"] = "close_window",
			},
		},
	},
	default_component_configs = {
		modified = {
			symbol = "",
			highlight = "NeoTreeModified",
		},
		name = {
			trailing_slash = false,
			use_git_status_colors = true,
			highlight = "NeoTreeFileName",
		},
		git_status = {
			symbols = {
				-- Change type
				added = "", -- or "✚", but this is redundant info if you use git_status_colors on the name
				modified = "", -- or "", but this is redundant info if you use git_status_colors on the name
				deleted = "✖", -- this can only be used in the git_status source
				renamed = "󰁕", -- this can only be used in the git_status source
				-- Status type
				untracked = "?",
				ignored = "",
				unstaged = "󰄱",
				staged = "",
				conflict = "",
			},
		},
	},
})

-- INFO: format
vim.pack.add({
	"https://github.com/stevearc/conform.nvim",
})

require("conform").setup({
	notify_on_error = true,
	format_on_save = function(bufnr)
		-- Disable "format_on_save lsp_fallback" for languages that don't
		-- have a well standardized coding style. You can add additional
		-- languages here or re-enable it for the disabled ones.
		local disable_filetypes = { c = true, cpp = true, tex = true }
		if disable_filetypes[vim.bo[bufnr].filetype] then
			return nil
		else
			return {
				timeout_ms = 500,
				lsp_format = "fallback",
			}
		end
	end,
	formatters = {
		-- 配置 shfmt 的参数 (默认是 -w)
		shfmt = {
			prepend_args = { "-i", "2" }, -- 缩进 2 空格
		},
		["tex-fmt"] = {
			-- 使用 vim.fn.stdpath("config") 获取 nvim 配置目录路径
			-- 最终拼接成：--config /home/user/.config/nvim/tex-fmt.toml
			prepend_args = { "--config", vim.fn.stdpath("config") .. "/tool-configs/tex-fmt.toml" },

			-- 在我的pr合并前先使用我自己编译的版本
			command = "/home/yuchen/Documents/tex-fmt/target/release/tex-fmt",
		},
		["cbfmt"] = {
			prepend_args = { "--config", vim.fn.stdpath("config") .. "/tool-configs/cbfmt.toml" },
		},
		["black"] = {
			prepend_args = { "--config", vim.fn.stdpath("config") .. "/tool-configs/black.toml" },
		},
	},
	formatters_by_ft = {
		lua = { "stylua" },
		-- Conform can also run multiple formatters sequentially
		python = { "black" },
		--
		-- You can use 'stop_after_first' to run the first available formatter from the list
		-- javascript = { "prettierd", "prettier", stop_after_first = true },
		javascript = { "clang-format" },
		typescript = { "prettier" },
		javascriptreact = { "prettier" },
		typescriptreact = { "prettier" },
		css = { "prettier" },
		html = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },
		graphql = { "prettier" },

		-- C / C++ / C# -> Clang-format
		c = { "clang-format" },
		cpp = { "clang-format" },
		cs = { "clang-format" },

		-- Go -> 先整理 import，再进行严格格式化
		go = { "goimports", "gofumpt" },

		-- Haskell
		haskell = { "ormolu" },

		-- Shell / Bash
		sh = { "shfmt" },
		bash = { "shfmt" },

		-- LaTeX 相关
		tex = { "tex-fmt" },
		bib = { "bibtex-tidy" },

		-- Typst
		typst = { "prettypst" },

		-- Markdown (组合拳)
		-- 1. 先用 prettier 整理 Markdown 文本结构
		-- 2. 再用 cbfmt 整理 Markdown 内部的代码块
		-- (注意：markdownlint 是 linter，不放在这里)
		markdown = { "prettier", "cbfmt" },

		-- 对所有未指定的文件类型，尝试使用 LSP 格式化
		-- ["*"] = { "codespell" },
	},
})

vim.pack.add({
	"https://github.com/lewis6991/gitsigns.nvim",
	--[[
f, t, F, T motions:

    After typing f{char} or F{char}, you can repeat the motion with f or go to the previous match with F to undo a jump.
    Similarly, after typing t{char} or T{char}, you can repeat the motion with t or go to the previous match with T.
    You can also go to the next match with ; or previous match with ,
    Any highlights clear automatically when moving, changing buffers, or pressing <esc>.

--]]
	"https://github.com/folke/flash.nvim",
	-- Using regexes and extmarks to highlight uses of the word under the cursor.
	-- Keeps updates local to currently visible lines, thus enabling blazingly fast performance.
	"https://github.com/tzachar/local-highlight.nvim",
	-- "https://github.com/echasnovski/mini.nvim",
	--
	-- A sidebar with a tree-like outline of symbols from your code, powered by LSP.
	"https://github.com/hedyhli/outline.nvim",
	--
	-- NOTE: This plugin may cause lag?
	--
	-- This Neovim plugin provides alternating syntax highlighting (“rainbow parentheses”) for Neovim.
	"https://github.com/HiPhish/rainbow-delimiters.nvim",
	"https://github.com/mrjones2014/smart-splits.nvim",
}, { confirm = false })

require("gitsigns").setup()
require("flash").setup()
require("outline").setup()
require("local-highlight").setup({
	-- file_types = { 'python', 'cpp' }, -- If this is given only attach to this
	-- OR attach to every filetype except:
	disable_file_types = { "tex" },
	hlgroup = "LocalHighlight",
	cw_hlgroup = nil,
	-- Whether to display highlights in INSERT mode or not
	insert_mode = false,
	min_match_len = 1,
	max_match_len = math.huge,
	highlight_single_match = true,
	animate = {
		-- only support when snacks.nvim is installed
		enabled = false, -- true,
		easing = "linear",
		duration = {
			step = 10, -- ms per step
			total = 100, -- maximum duration
		},
	},
	debounce_timeout = 200,
})
vim.g.rainbow_delimiters = {
	strategy = {
		[""] = "rainbow-delimiters.strategy.global",
		vim = "rainbow-delimiters.strategy.local",
	},
	query = {
		-- [''] = 'rainbow-blocks',
		[""] = "rainbow-delimiters",
		lua = "rainbow-blocks",
		latex = "rainbow-blocks",
		-- python = 'rainbow-blocks',
	},
	priority = {
		[""] = 110,
		lua = 210,
		latex = 211,
	},
	highlight = {
		"RainbowDelimiterRed",
		"RainbowDelimiterYellow",
		"RainbowDelimiterBlue",
		"RainbowDelimiterOrange",
		"RainbowDelimiterGreen",
		"RainbowDelimiterViolet",
		"RainbowDelimiterCyan",
	},
}

local smart_splits = require("smart-splits")
-- resizing splits
-- these keymaps will also accept a range,
-- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
vim.keymap.set("n", "<A-h>", smart_splits.resize_left)
vim.keymap.set("n", "<A-j>", smart_splits.resize_down)
vim.keymap.set("n", "<A-k>", smart_splits.resize_up)
vim.keymap.set("n", "<A-l>", smart_splits.resize_right)
-- moving between splits
vim.keymap.set("n", "<C-h>", smart_splits.move_cursor_left)
vim.keymap.set("n", "<C-j>", smart_splits.move_cursor_down)
vim.keymap.set("n", "<C-k>", smart_splits.move_cursor_up)
vim.keymap.set("n", "<C-l>", smart_splits.move_cursor_right)
vim.keymap.set("n", "<C-\\>", smart_splits.move_cursor_previous)

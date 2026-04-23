-- INFO: fuzzy finder
vim.pack.add({
	"https://github.com/nvim-lua/plenary.nvim", -- library dependency
	"https://github.com/nvim-tree/nvim-web-devicons", -- icons (nerd font)
	"https://github.com/nvim-tree/ahmedkhalf/project.nvim", -- cmd "telescope project" dep
	"https://github.com/nvim-telescope/telescope.nvim", -- the fuzzy finder
}, { confirm = false })

require("project_nvim").setup({})
require("telescope").setup({})
require("telescope").load_extension("projects")
pcall(require("telescope").load_extension, "fzf")
pcall(require("telescope").load_extension, "ui-select")

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
	--denpendencies
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/MunifTanjim/nui.nvim",
	"https://github.com/s1n7ax/nvim-window-picker",
	-- file manager
	"https://github.com/nvim-neo-tree/neo-tree.nvim",
}, { confirm = false })

require("window-picker").setup({
	hint = "floating-big-letter",
})
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
	-- auto pairs
	"https://github.com/windwp/nvim-autopairs",
	-- This plugin adds indentation guides to Neovim. It uses Neovim's virtual text feature and no conceal
	"https://github.com/lukas-reineke/indent-blankline.nvim",
	-- highlight TODO/INFO/WARN comments
	"https://github.com/folke/todo-comments.nvim",
	-- Deep buffer integration for Git
	"https://github.com/lewis6991/gitsigns.nvim",
	-- git diff view
	-- "https://github.com/sindrets/diffview.nvim",
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
	-- Alt hjkl resize
	"https://github.com/mrjones2014/smart-splits.nvim",
	"https://github.com/chenyu76/draftsman.nvim",
	-- A polished, IDE-like, highly-customizable winbar for Neovim with drop-down menus and multiple backends.
	-- For more information see :h dropbar.
	"https://github.com/Bekaboo/dropbar.nvim",
	-- A search panel for neovim.
	-- Spectre find the enemy and replace them with dark power.
	"https://github.com/nvim-pack/nvim-spectre",
	-- A collection of small QoL plugins for Neovim.
	"https://github.com/folke/snacks.nvim",
	-- A pretty list for showing diagnostics, references, telescope results,
	-- quickfix and location lists to help you solve all the trouble your code is causing.
	"https://github.com/folke/trouble.nvim",
	-- A fancy, configurable, notification manager for NeoVim
	"https://github.com/rcarriga/nvim-notify",
	-- nvim-scrollview is a Neovim plugin that displays interactive vertical scrollbars and signs.
	-- The plugin is customizable (see :help scrollview-configuration).
	"https://github.com/dstein64/nvim-scrollview",
}, { confirm = false })

require("nvim-autopairs").setup()
require("trouble").setup()
require("ibl").setup()
require("todo-comments").setup()
require("gitsigns").setup()
require("flash").setup()
require("outline").setup()
require("draftsman").setup({})
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
local highlight = {
	"RainbowRed",
	"RainbowYellow",
	"RainbowBlue",
	"RainbowOrange",
	"RainbowGreen",
	"RainbowViolet",
	"RainbowCyan",
}
-- rainbow-delimiters.nvim integration
local hooks = require("ibl.hooks")
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
	vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
	vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
	vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
	vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
	vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
	vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
	vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
end)
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
	highlight = highlight,
}
require("ibl").setup({ scope = { highlight = highlight } })
hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

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

require("snacks").setup({
	terminal = { enabled = true },
	lazygit = { enabled = true },
	dashboard = {
		width = 60,
		row = nil, -- dashboard position. nil for center
		col = nil, -- dashboard position. nil for center
		pane_gap = 4, -- empty columns between vertical panes
		autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", -- autokey sequence
		-- These settings are used by some built-in sections
		preset = {
			-- Defaults to a picker that supports `fzf-lua`, `telescope.nvim` and `mini.pick`
			---@type fun(cmd:string, opts:table)|nil
			pick = nil,
			-- Used by the `keys` section to show keymaps.
			-- Set your custom keymaps here.
			-- When using a function, the `items` argument are the default keymaps.
			---@type snacks.dashboard.Item[]
			keys = {
				{ icon = "󰋚 ", key = ".", desc = "Oldfiles", action = ":Telescope oldfiles" },
				{ icon = " ", key = "c", desc = "Create a new file", action = ":ene | startinsert" },
				{ icon = "󱉟 ", key = "p", desc = "Projects", action = ":Telescope projects" },
				{ icon = "󰩍 ", key = "o", desc = "Open a file", action = ":Open" },
				{ icon = " ", key = "t", desc = "Terminal", action = ":terminal" },
				{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
			},
			-- Used by the `header` section
			header = [[
                     -=-                               
                   4"   "h                             
                  $      {@                            
                          L                            
                  -aF`````vF"``""Vkw-                  
              -sF`                   {h,               
           ~F`  <P``    ~--,           `Q-             
         ~}  ,d`            `Q=          `h            
        :}  /                  {@          $           
       .} c`       ,             {@         $          
       $ /        d        \      L          &         
       }    {    d   L      |    ]      $     {@       
      ]L   |     [  {       |    $     } @{@{@$        
      ]L     ..  [  $       |    }     [  {}$ \        
       [ Lg$}m>.    ``V@- --=---.L     {-} L { }       
         }d'  ]`@        o"`Qk= }      / | |  }        
         { @ ~`         |   [ `L}     /  | |  }        
         { `$,,"        ]@-/  , [    .   | |  L        
         }               "--s" ]     $   | | ]         
         }    |`\              {    :{-  | ` }         
         } \   h ]   .--       $    }`L      \         
         $   `@,``""`       .-<$   /  {      `-        
         $     .}"^mwwpy^""`}  }   }   Q      $        
         { L  4}      }    /   [  ] `- {@      L       
           L  }       L  ~"    L  {  {@ \      $       
          d  d        {,/      L  }   {  Q.    }       
          {  {                 L  }   {   {    `       
]],
		},
		-- item field formatters
		formats = {
			icon = function(item)
				if item.file and item.icon == "file" or item.icon == "directory" then
					return Snacks.dashboard.icon(item.file, item.icon)
				end
				return { item.icon, width = 2, hl = "icon" }
			end,
			footer = { "%s", align = "center" },
			header = { "%s", align = "center" },
			file = function(item, ctx)
				local fname = vim.fn.fnamemodify(item.file, ":~")
				fname = ctx.width and #fname > ctx.width and vim.fn.pathshorten(fname) or fname
				if #fname > ctx.width then
					local dir = vim.fn.fnamemodify(fname, ":h")
					local file = vim.fn.fnamemodify(fname, ":t")
					if dir and file then
						file = file:sub(-(ctx.width - #dir - 2))
						fname = dir .. "/…" .. file
					end
				end
				local dir, file = fname:match("^(.*)/(.+)$")
				return dir and { { dir .. "/", hl = "dir" }, { file, hl = "file" } } or { { fname, hl = "file" } }
			end,
		},
		sections = {
			{
				pane = 1,
				{
					section = "header",
				},
			},
			{
				pane = 2,
				-- { section = "keys", gap = 1, padding = 1 },
				{ title = "NEOVIM", padding = 1 },
				{ icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
				{ icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
				{ icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
			},
			-- { section = "keys", gap = 1, padding = 1 },
			-- start up only works for lazy.nvim
			-- { section = "startup" },
		},
	},
})

local notify = require("notify")
-- notify.setup {
--   -- 其他配置项...
--   stages = 'fade_in_slide_out',
--   timeout = 3000,
--   max_width = 80,
--   max_height = 20,
--   background_colour = '#000000',
-- }
-- 将 notify 函数覆盖全局的 vim.notify，
-- 这样所有调用 vim.notify 的地方都会使用 nvim-notify 来显示通知
vim.notify = notify

-- INFO: keybinding helper
vim.pack.add({ "https://github.com/folke/which-key.nvim" }, { confirm = false })
local wk = require("which-key")
local gitsigns = require("gitsigns")
-- 0 代表当前活跃的缓冲区
local bufnr = 0

wk.setup({
	spec = {
		{ "<leader>s", group = "[S]earch", icon = { icon = "", color = "green" } },
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			icon = { icon = "󰉣", color = "green" },
			desc = "[F]ormat",
		},
		{ "<leader>t", group = "[T]oggle" },
		{ "<leader>x", group = "Trouble" },
		{ "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
		{
			"<leader>tc",
			'<cmd>lua require("copilot.suggestion").toggle_auto_trigger()<CR>',
			desc = "[T]oggle [C]opilt",
			mode = "n",
			icon = "",
		},
		-- { '<leader>tf', '<cmd>LspTexlabForward<CR>', desc = '[T]exlab [F]orward', mode = 'n', icon = '' },
		-- { '<leader>tm', '<cmd>MathScriptsToggle<CR>', desc = '[T]oggle [M]ath scripts', mode = 'n', icon = '␚' },
		-- { '<leader>w', '<cmd>HopWord<CR>', desc = 'Jump by [W]ord', mode = { 'n', 'v' }, icon = '󰈭' },
		-- { '<leader>ca', '<cmd>:lua vim.lsp.buf.code_action()<CR>', desc = 'Code Actions / Quick Fix', mode = { 'n', 'v' }, icon = '󰀬' },
		-- { '<leader>n', '<cmd>Neotree reveal toggle dir=./<CR>', desc = '[N]eotree', mode = 'n', icon = '' },
		{ "<C-n>", "<cmd>Neotree reveal toggle dir=./<CR>", desc = "[N]eotree", mode = "n", icon = "" },
		-- { '<leader>e', '<cmd>ToggleTerm<CR>', desc = 'Terminal [e]mulator', mode = 'n', icon = '' },
		-- { '<C-n>', '<cmd>Neotree reveal toggle dir=./<CR>', desc = '[N]eotree', mode = { 'n', 'i' }, icon = '' },
		-- { '<C-\\>', '<cmd>ToggleTerm<CR>', desc = 'Terminal', mode = { 'n', 'i', 't' }, icon = '' },
		-- { '<F4>', '<cmd>ToggleTerm<CR>', desc = 'Terminal', mode = { 'n', 'i', 't' }, icon = '' },
		-- INFO: modules.view_corresponding_pdf
		{ "<leader>tp", "<cmd>lua ViewCorrespondingPDF()<CR>", desc = "[Trigger] PDF", mode = "n", icon = "" },
		-- INFO: modules.lazygit
		{ "<leader>tl", "<cmd>lua ToggleLazygit()<CR>", desc = "[T]oggle [L]azygit", mode = "n", icon = "" },
		-- INFO: modules.quick_run
		{ "<leader>r", "<cmd>lua RunCurrentFile()<CR>", desc = "[R]un file", mode = "n", icon = "" },
		{
			"<leader>R",
			"<cmd>lua RunCurrentFileWithArg()<CR>",
			desc = "[R]un file with args",
			mode = "n",
			icon = "",
		},
		-- INFO: modules.format_and_wrap
		{
			"<leader>w",
			"<Esc><cmd>lua FormatSelectionAndWrap()<CR>",
			mode = "v",
			desc = "[W]rap selection",
			icon = "󰖶",
		},
		-- INFO: modules.number_enter_mode
		{
			"<leader>0",
			NumberEnterMode,
			desc = "Enter Number Mode",
			mode = "n",
			noremap = true,
			silent = true,
		},
		--
		-- INFO: Debug
		--
		{ "<leader>d", group = "[D]bug", icon = { icon = "", color = "red" } },
		{
			"<leader>dc",
			function()
				require("dap").continue()
			end,
			desc = "Debug: Start/[C]ontinue",
			icon = "",
		},
		{
			"<leader>di",
			function()
				require("dap").step_into()
			end,
			desc = "Debug: Step [I]nto",
			icon = { color = "red", icon = "" },
		},
		{
			"<leader>do",
			function()
				require("dap").step_over()
			end,
			desc = "Debug: Step [O]ver",
			icon = { color = "red", icon = "" },
		},
		{
			"<leader>ds",
			function()
				require("dap").step_out()
			end,
			desc = "Debug: [S]tep Out",
			icon = { color = "red", icon = "󰆸" },
		},
		{
			"<leader>db",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Debug: Toggle [B]reakpoint",
			icon = { color = "red", icon = "" },
		},
		{
			"<leader>dB",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			desc = "Debug: Set [B]reakpoint",
			icon = { color = "red", icon = "" },
		},
		-- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
		{
			"<leader>dr",
			function()
				require("dapui").toggle()
			end,
			desc = "Debug: See last session [r]esult.",
			icon = { color = "red", icon = "" },
		},
		--
		-- NOTE: Keymaps of gitsigns located in plugins.editor
		--
		--
		-- INFO: gitsigns.nvim
		--
		-- 导航 (Navigation)
		{
			"]c",
			function()
				if vim.wo.diff then
					vim.cmd.normal({ "]c", bang = true })
				else
					gitsigns.nav_hunk("next")
				end
			end,
			desc = "Next Change",
			buffer = bufnr,
		},

		{
			"[c",
			function()
				if vim.wo.diff then
					vim.cmd.normal({ "[c", bang = true })
				else
					gitsigns.nav_hunk("prev")
				end
			end,
			desc = "Prev Change",
			buffer = bufnr,
		},

		-- Git 操作分组 (Actions)
		{ "<leader>h", group = "Git Hunk", buffer = bufnr },

		-- Visual 模式下的操作 (需要单独指定 mode)
		{
			"<leader>hs",
			function()
				gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end,
			desc = "Stage Hunk",
			mode = "v",
			buffer = bufnr,
		},
		{
			"<leader>hr",
			function()
				gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end,
			desc = "Reset Hunk",
			mode = "v",
			buffer = bufnr,
		},

		-- Normal 模式下的操作
		{ "<leader>hs", gitsigns.stage_hunk, desc = "Stage Hunk", buffer = bufnr },
		{ "<leader>hr", gitsigns.reset_hunk, desc = "Reset Hunk", buffer = bufnr },
		{ "<leader>hS", gitsigns.stage_buffer, desc = "Stage Buffer", buffer = bufnr },
		{ "<leader>hu", gitsigns.undo_stage_hunk, desc = "Undo Stage", buffer = bufnr },
		{ "<leader>hR", gitsigns.reset_buffer, desc = "Reset Buffer", buffer = bufnr },
		{ "<leader>hp", gitsigns.preview_hunk, desc = "Preview Hunk", buffer = bufnr },
		{
			"<leader>hb",
			function()
				gitsigns.blame_line({ full = true })
			end,
			desc = "Blame Line",
			buffer = bufnr,
		},
		{ "<leader>hd", gitsigns.diffthis, desc = "Diff Index", buffer = bufnr },
		{
			"<leader>hD",
			function()
				gitsigns.diffthis("~")
			end,
			desc = "Diff Last Commit",
			buffer = bufnr,
		},

		-- 开关 (Toggles)
		{ "<leader>tb", gitsigns.toggle_current_line_blame, desc = "Toggle Blame", buffer = bufnr },
		{ "<leader>tD", gitsigns.toggle_deleted, desc = "Toggle Deleted", buffer = bufnr },

		-- INFO: plugin outline.nvim
		{
			"<leader>o",
			"<cmd>Outline<CR>",
			desc = "Toggle Outline",
			icon = "",
		},
	},
})
--vim.keymap.set()
-- vim.keymap.set('v', '<leader>tw', '<Esc><cmd>lua FormatSelectionAndWrap()<CR>', { desc = '[T]rigger [W]rap' })

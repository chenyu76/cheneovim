-- INFO: keybinding helper
-- Icon Cheat Sheet: https://www.nerdfonts.com/cheat-sheet
vim.pack.add({ "https://github.com/folke/which-key.nvim" }, { confirm = false })
local wk = require("which-key")
-- local gitsigns = require("gitsigns")
-- 0 代表当前活跃的缓冲区
local bufnr = 0

wk.setup({
	spec = {
		{ "<leader>s", group = "[S]earch", icon = { icon = "", color = "green" } },
		{ "<leader>t", group = "[T]oggle", icon = { icon = "󰦭", color = "orange" } },
		{ "<leader>g", group = "[G]it", icon = { icon = "", color = "orange" } },
		-- {
		-- 	"<leader>tc",
		-- 	'<cmd>lua require("copilot.suggestion").toggle_auto_trigger()<CR>',
		-- 	desc = "[T]oggle [C]opilt",
		-- 	mode = "n",
		-- 	icon = "",
		-- },
		-- { '<leader>tf', '<cmd>LspTexlabForward<CR>', desc = '[T]exlab [F]orward', mode = 'n', icon = '' },
		-- { '<leader>tm', '<cmd>MathScriptsToggle<CR>', desc = '[T]oggle [M]ath scripts', mode = 'n', icon = '␚' },
		-- { '<leader>w', '<cmd>HopWord<CR>', desc = 'Jump by [W]ord', mode = { 'n', 'v' }, icon = '󰈭' },
		-- { '<leader>ca', '<cmd>:lua vim.lsp.buf.code_action()<CR>', desc = 'Code Actions / Quick Fix', mode = { 'n', 'v' }, icon = '󰀬' },
		-- { '<leader>n', '<cmd>Neotree reveal toggle dir=./<CR>', desc = '[N]eotree', mode = 'n', icon = '' },
		{ "<C-n>", "<cmd>Neotree reveal toggle dir=./<CR>", desc = "[N]eotree", mode = "n", icon = "" },
		{ "<C-.>", "<cmd>lua Snacks.terminal.toggle()<CR>", desc = "Terminal", mode = "n", icon = "" },
		-- { "<F4>", "<cmd>lua Snacks.terminal.toggle()<CR>", desc = "Terminal", mode = "n", icon = "" },
		-- { '<leader>e', '<cmd>ToggleTerm<CR>', desc = 'Terminal [e]mulator', mode = 'n', icon = '' },
		-- { '<C-n>', '<cmd>Neotree reveal toggle dir=./<CR>', desc = '[N]eotree', mode = { 'n', 'i' }, icon = '' },
		-- { '<C-\\>', '<cmd>ToggleTerm<CR>', desc = 'Terminal', mode = { 'n', 'i', 't' }, icon = '' },
		-- { '<F4>', '<cmd>ToggleTerm<CR>', desc = 'Terminal', mode = { 'n', 'i', 't' }, icon = '' },
		-- INFO: modules.view_corresponding_pdf
		{ "<leader>tp", "<cmd>lua ViewCorrespondingPDF()<CR>", desc = "[Trigger] PDF", mode = "n", icon = "" },
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
		-- INFO: format
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			icon = { icon = "󰉣", color = "green" },
			desc = "[F]ormat",
		},
		-- INFO: Debug
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
		-- INFO: gitsigns.nvim
		--
		-- 导航 (Navigation)
		-- {
		-- 	"]c",
		-- 	function()
		-- 		if vim.wo.diff then
		-- 			vim.cmd.normal({ "]c", bang = true })
		-- 		else
		-- 			gitsigns.nav_hunk("next")
		-- 		end
		-- 	end,
		-- 	desc = "Next Change",
		-- 	buffer = bufnr,
		-- },
		--
		-- {
		-- 	"[c",
		-- 	function()
		-- 		if vim.wo.diff then
		-- 			vim.cmd.normal({ "[c", bang = true })
		-- 		else
		-- 			gitsigns.nav_hunk("prev")
		-- 		end
		-- 	end,
		-- 	desc = "Prev Change",
		-- 	buffer = bufnr,
		-- },
		--
		-- -- Git 操作分组 (Actions)
		-- -- { "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
		-- { "<leader>h", group = "Git Hunk", buffer = bufnr },
		--
		-- -- Visual 模式下的操作 (需要单独指定 mode)
		-- {
		-- 	"<leader>hs",
		-- 	function()
		-- 		gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		-- 	end,
		-- 	desc = "Stage Hunk",
		-- 	mode = "v",
		-- 	buffer = bufnr,
		-- },
		-- {
		-- 	"<leader>hr",
		-- 	function()
		-- 		gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		-- 	end,
		-- 	desc = "Reset Hunk",
		-- 	mode = "v",
		-- 	buffer = bufnr,
		-- },
		--
		-- -- Normal 模式下的操作
		-- { "<leader>hs", gitsigns.stage_hunk, desc = "Stage Hunk", buffer = bufnr },
		-- { "<leader>hr", gitsigns.reset_hunk, desc = "Reset Hunk", buffer = bufnr },
		-- { "<leader>hS", gitsigns.stage_buffer, desc = "Stage Buffer", buffer = bufnr },
		-- { "<leader>hu", gitsigns.undo_stage_hunk, desc = "Undo Stage", buffer = bufnr },
		-- { "<leader>hR", gitsigns.reset_buffer, desc = "Reset Buffer", buffer = bufnr },
		-- { "<leader>hp", gitsigns.preview_hunk, desc = "Preview Hunk", buffer = bufnr },
		-- {
		-- 	"<leader>hb",
		-- 	function()
		-- 		gitsigns.blame_line({ full = true })
		-- 	end,
		-- 	desc = "Blame Line",
		-- 	buffer = bufnr,
		-- },
		-- { "<leader>hd", gitsigns.diffthis, desc = "Diff Index", buffer = bufnr },
		-- {
		-- 	"<leader>hD",
		-- 	function()
		-- 		gitsigns.diffthis("~")
		-- 	end,
		-- 	desc = "Diff Last Commit",
		-- 	buffer = bufnr,
		-- },
		--
		-- -- 开关 (Toggles)
		-- { "<leader>tb", gitsigns.toggle_current_line_blame, desc = "Toggle Blame", buffer = bufnr },
		-- { "<leader>tD", gitsigns.toggle_deleted, desc = "Toggle Deleted", buffer = bufnr },
		-- INFO: https://github.com/sindrets/diffview.nvim
		{
			"<leader>gd",
			"<cmd>DiffviewOpen<CR>",
			desc = "[G]it [D]iff",
			icon = "",
		},

		-- INFO: plugin outline.nvim
		{
			"<leader>o",
			"<cmd>Outline<CR>",
			desc = "[O]utline",
			icon = "",
		},
		-- INFO: plugin 'let-def/texpresso.vim'
		{ "<leader>tx", "<cmd>TeXpresso %<CR>", desc = "TeXpresso %" },
		-- INFO: plugin 'nvim-pack/nvim-spectre'
		{
			"<leader>S",
			'<cmd>lua require("spectre").toggle()<CR>',
			mode = "n",
			desc = "[S]pectre",
			icon = "󰥨",
		},
		{
			"<leader>sw",
			'<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
			mode = "n",
			desc = "Search current word",
			icon = "󰩉",
		},
		{
			"<leader>sw",
			'<esc><cmd>lua require("spectre").open_visual()<CR>',
			mode = "v",
			desc = "Search current word",
			icon = "󰩉",
		},
		{
			"<leader>sp",
			'<cmd>lua require("spectre").open_file_search({select_word=true})<CR>',
			mode = "n",
			desc = "Search on current file",
			icon = "󰱼",
		},
		-- INFO: plugin 'folke/snacks.nvim'
		{
			"<leader>gl",
			'<cmd>lua require("snacks").lazygit()<CR>',
			desc = "[G]it [L]azy",
			mode = "n",
			icon = "",
		},
		{
			"<leader>z",
			"<cmd>lua Snacks.zen()<CR>",
			desc = "[Z]en mode",
			mode = "n",
			icon = {
				color = "blue",
				icon = "󰼀",
			},
		},
		-- INFO: plugin 'folke/trouble.nvim'
		{ "<leader>x", group = "Trouble", icon = "" },
		{
			"<leader>xx",
			"<cmd>Trouble diagnostics toggle<cr>",
			desc = "Diagnostics (Trouble)",
		},
		{
			"<leader>xX",
			"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
			desc = "Buffer Diagnostics (Trouble)",
		},
		{
			"<leader>xs",
			"<cmd>Trouble symbols toggle focus=false<cr>",
			desc = "Symbols (Trouble)",
		},
		{
			"<leader>xl",
			"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
			desc = "LSP Definitions / references / ... (Trouble)",
		},
		{
			"<leader>xL",
			"<cmd>Trouble loclist toggle<cr>",
			desc = "Location List (Trouble)",
		},
		{
			"<leader>xQ",
			"<cmd>Trouble qflist toggle<cr>",
			desc = "Quickfix List (Trouble)",
		},
	},
})
-- INFO: telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
vim.keymap.set("n", "<leader>sp", "<cmd>Telescope projects<cr>", { desc = "[S]earch [P]roject" })
vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

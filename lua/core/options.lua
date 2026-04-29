-- INFO: options
-- these change the default neovim behaviours using the 'vim.opt' API.
-- see `:h vim.opt` for more details.
-- run `:h '{option_name}'` to see what they do and what values they can take.
-- for example, `:h 'number'` for `vim.opt.number`.

-- set <space> as the leader key
-- must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- enable true color support
vim.opt.termguicolors = true

-- make line numbers default
vim.opt.number = true
vim.opt.relativenumber = true

-- enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

-- don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- sync clipboard between OS and Neovim.
--  remove this option if you want your OS clipboard to remain independent.
--  see `:help 'clipboard'`
vim.opt.clipboard = "unnamedplus"

-- enable break indent
vim.opt.breakindent = true

-- save undo history
vim.opt.undofile = true

-- case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- decrease update time
vim.opt.updatetime = 250

-- decrease mapped sequence wait time
-- displays which-key popup sooner
vim.opt.timeoutlen = 300

-- configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- show which line your cursor is on
vim.opt.cursorline = true

-- set conceal level to 2 to show symbols
vim.opt.conceallevel = 2

-- set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true

-- enable line wrapping
vim.opt.wrap = true

-- formatting
vim.opt.tabstop = 4
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.textwidth = 80

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.INFO] = " ",
			[vim.diagnostic.severity.HINT] = " ",
		},
	},
	virtual_text = true, -- show inline diagnostics
})

-- clear search highlights with <Esc>
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- 在可视化模式中反复按 > 或 < 来连续调整缩进，而不需要重新选择文本
-- gv: Go Visual，在操作完成后，立即重新进入可视化模式并选中上一次的区域
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true, desc = "Visual Indent and Reselect" })
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true, desc = "Visual Dedent and Reselect" })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--  Already set by 'mrjones2014/smart-splits.nvim' in plugins.editor
-- vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
-- vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
-- vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
-- vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

vim.opt.shell = "/usr/bin/fish"

-- 使用 VSCode 打开当前文件
vim.api.nvim_create_user_command("OpenInVSCode", function()
	local path = vim.fn.expand("%:p")
	vim.cmd("silent !code " .. vim.fn.fnameescape(path))
end, {})

-- 使用 VSCode 打开当前文件所在目录
vim.api.nvim_create_user_command("OpenDirectoryInVSCode", function()
	local path = vim.fn.expand("%:p:h")
	vim.cmd("silent !code " .. vim.fn.fnameescape(path))
end, {})

vim.api.nvim_create_user_command("OpenDirectoryInNautilus", function()
	local path = vim.fn.expand("%:p:h")
	-- nautilus 是Gnome的文件管理器名字
	vim.cmd("silent !nautilus " .. vim.fn.fnameescape(path))
end, {})

vim.api.nvim_create_user_command("OpenConsoleAtCurrentDirectory", function()
	local path = vim.fn.expand("%:p:h")
	vim.cmd("silent !kgx " .. vim.fn.fnameescape(path))
end, {})

-- GUI 文件选择对话框函数 (Functions)
local function open_file_with_dialog()
	-- 调用 zenity 文件选择器
	local cmd = 'zenity --file-selection --title="Select a file"'
	local filename = vim.fn.system(cmd)

	-- 移除末尾换行符
	filename = filename:gsub("\n$", "")

	-- 如果有多行输出（处理某些 shell 环境下的冗余信息），取最后一行
	local lines = vim.split(filename, "\n")
	filename = lines[#lines]

	-- 检查文件名是否非空
	if filename ~= "" and filename ~= nil then
		-- 使用 vim.cmd.edit 打开文件
		-- vim.fn.fnameescape 会处理路径中的空格等特殊字符
		vim.cmd.edit(vim.fn.fnameescape(filename))
	end
end

-- 将函数映射到自定义命令 :Open
vim.api.nvim_create_user_command("Open", open_file_with_dialog, {})

-- haskell 的工具链安装在 ~/.ghcup/bin 下面，添加到 PATH 中
vim.env.PATH = vim.fn.expand("~/.ghcup/bin") .. ":" .. vim.env.PATH

-- Neovide specific settings
if vim.g.neovide then
	vim.o.guifont = "Maple Mono NF CN,JetBrainsMono Nerd Font,苹方:h11"
	vim.opt.linespace = 2
	vim.g.neovide_hide_mouse_when_typing = true
	vim.g.experimental_layer_grouping = true
	vim.g.neovide_cursor_animation_length = 0.3
	vim.g.neovide_cursor_vfx_mode = "railgun"
end

vim.o.colorcolumn = "80,100"

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

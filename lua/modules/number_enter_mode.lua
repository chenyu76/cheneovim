-- ================================================
-- ==         Number Entering Mode             ==
-- ================================================

-- 定义要映射的键和对应的数字
-- 键: n, m, ,, h, j, k, y, u, i, l
-- 值: 1, 2, 3, 4, 5, 6, 7, 8, 9, 0
local number_keys = { "n", "m", ",", "h", "j", "k", "y", "u", "i", "l", "g", "b" }
local number_digits = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "0", "." }

--- 清除数字模式的键位映射
local function clear_number_mappings()
	-- 移除数字键映射
	for _, key in ipairs(number_keys) do
		-- pcall 用于在映射不存在时防止报错
		pcall(vim.api.nvim_del_keymap, "i", key)
	end
	-- 移除自定义的 <Esc> 映射，恢复其默认行为
	pcall(vim.api.nvim_del_keymap, "i", "<Esc>")
end

--- 退出数字模式（必须是全局的，以便 'expr' 映射可以调用）
-- 我们将其放在 _G (全局) 命名空间下
_G.exit_number_mode = function()
	clear_number_mappings()
	-- 返回 <Esc> 的终端代码，
	-- 以便 Neovim 在执行此函数后，能真正执行 <Esc>（即退出插入模式）
	return vim.api.nvim_replace_termcodes("<Esc>", true, true, true)
end

--- 进入数字模式
function NumberEnterMode()
	local map_opts = { noremap = true, silent = true }

	-- 1. 设置数字键映射
	for i, key in ipairs(number_keys) do
		vim.api.nvim_set_keymap("i", key, number_digits[i], map_opts)
	end

	-- 2. 设置 <Esc> 映射以调用我们的清理函数
	--    使用 expr = true, 这样映射会执行函数并使用其返回值
	vim.api.nvim_set_keymap("i", "<Esc>", "v:lua._G.exit_number_mode()", { expr = true, noremap = true })

	-- 3. 进入插入模式
	vim.cmd("startinsert")
end

-- 在 Normal 模式下，将 <leader>0 映射到 `enter_number_mode` 函数
-- vim.api.nvim_set_keymap("n", "<leader>0", "", {
-- 	noremap = true,
-- 	silent = true,
-- 	callback = enter_number_mode, -- 使用 callback 来调用 lua 函数
-- })

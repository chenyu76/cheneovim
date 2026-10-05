local turn_im_on -- 开启输入法函数
local turn_im_off -- 强制关闭输入法 (切回英文) 函数
local is_im_on -- 记录进入数学模式前的状态



-- 不同设备使用不同的输入法方案
if vim.g.current_device == 2 then
	-- ibus输入法: rime 和 xkb:us::eng
	is_im_on = function()
		return vim.trim(vim.fn.system("ibus engine")) == "rime"
	end

	turn_im_on = function()
		vim.fn.system("ibus engine rime")
	end

	turn_im_off = function()
		-- print(vim.fn.system("ibus engine rime"))
		vim.fn.system("ibus engine xkb:us::eng")
	end
elseif vim.g.current_device == 1 then
	-- 使用大写锁定控制中英文，因此大写锁定的状态就是输入法状态
	-- 大写锁定关闭即为输入中文。
	-- 切换前检查大写锁定，避免重复切换
	-- 需要安装ydotool
	--
	-- 是否打开大写锁定，返回 1 打开 或 0 关闭
	local function get_capslock_status()
		local files = vim.fn.glob("/sys/class/leds/*capslock/brightness", false, true)

		for _, file in ipairs(files) do
			local handle = io.open(file, "r")
			if handle then
				local value = handle:read("*l")
				handle:close()

				if value == "1" then
					return 1
				end
			end
		end

		return 0
	end

	-- 输入1打开大写锁定，0关闭
	local function toggle_capslock()
		vim.fn.system({ "ydotool", "key", "58:1", "58:0" })
	end
	local function turn_capslock(state)
		if get_capslock_status() ~= state then
			toggle_capslock()
		end
	end

	-- 输入中文时大写锁定是关闭的
	is_im_on = function()
		local engine = vim.trim(
			vim.fn.system(
				"gdbus call --session --dest org.gnome.Shell --object-path /raiden_fumo/InputSources --method raiden_fumo.InputSources.Get"
			)
		)
		return engine == "('rime',)" and get_capslock_status() == 0
	end
	turn_im_on = function()
		-- 这个status是大写锁定状态
		turn_capslock(0)
		-- 启动rime
		vim.fn.system(
			"gdbus call --session --dest org.gnome.Shell --object-path /raiden_fumo/InputSources --method raiden_fumo.InputSources.Set rime"
		)
	end
	turn_im_off = function()
		-- 需要安装
		-- https://extensions.gnome.org/extension/6547/input-source-d-bus-interface/
		-- 见
		-- https://github.com/herrscher-of-sleeping/gnome-input-source-dbus-interface
		-- system 返回的结果通常带换行符，需要 trim
		local engine = vim.trim(
			vim.fn.system(
				"gdbus call --session --dest org.gnome.Shell --object-path /raiden_fumo/InputSources --method raiden_fumo.InputSources.Get"
			)
		)
		-- rime 下打开大写锁定是关闭输入法，
		-- 不过在us键盘下应该关闭大写锁定
		if engine == "('rime',)" then
			turn_capslock(1)
		else
			turn_capslock(0)
		end
	end
else
	-- fcitx5输入法: pinyin (通过 fcitx5-remote 控制)
	is_im_on = function()
		return vim.trim(vim.fn.system("/usr/bin/fcitx5-remote")) == "2"
	end

	turn_im_on = function()
		vim.fn.system("/usr/bin/fcitx5-remote -o")
	end

	turn_im_off = function()
		vim.fn.system("/usr/bin/fcitx5-remote -c")
	end
end

-- 切换提示：不抢焦点，显示在光标右下方，650 毫秒后关闭。
local indicator_buf
local indicator_win
local indicator_version = 0

local function show_im_indicator(enabled)
	indicator_version = indicator_version + 1
	local version = indicator_version
	vim.schedule(function()
		if version ~= indicator_version or #vim.api.nvim_list_uis() == 0 then
			return
		end
		if indicator_win and vim.api.nvim_win_is_valid(indicator_win) then
			vim.api.nvim_win_close(indicator_win, true)
		end
		if not indicator_buf or not vim.api.nvim_buf_is_valid(indicator_buf) then
			indicator_buf = vim.api.nvim_create_buf(false, true)
		end
		local label = enabled and "中" or "En"
		vim.api.nvim_buf_set_lines(indicator_buf, 0, -1, false, { label })
		indicator_win = vim.api.nvim_open_win(indicator_buf, false, {
			relative = "cursor",
			anchor = "NW",
			row = 1,
			col = 1,
			width = vim.fn.strdisplaywidth(label),
			height = 1,
			style = "minimal",
			border = "rounded",
			focusable = false,
			noautocmd = true,
			zindex = 200,
		})
		vim.defer_fn(function()
			-- 快速连续切换时，旧计时器不能关闭新提示。
			if version == indicator_version and indicator_win and vim.api.nvim_win_is_valid(indicator_win) then
				vim.api.nvim_win_close(indicator_win, true)
				indicator_win = nil
			end
		end, 500)
	end)
end

local function set_im(enabled, show_indicator)
	if enabled then
		turn_im_on()
	else
		turn_im_off()
	end
	if show_indicator then
		show_im_indicator(enabled)
	end
end

-- 只识别未转义的 $ / $$；注释中的分隔符不参与数学模式判断。
local function in_dollar_math()
	local ft = vim.bo.filetype
	if ft ~= "tex" and ft ~= "plaintex" and ft ~= "latex" then
		return false
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local lines = vim.api.nvim_buf_get_lines(0, 0, cursor[1], false)
	lines[#lines] = lines[#lines]:sub(1, cursor[2])
	local delimiter
	for _, line in ipairs(lines) do
		local i = 1
		while i <= #line do
			local char = line:sub(i, i)
			if char == "\\" then
				-- 跳过转义字符，也能正确处理 \\$ 前的偶数个反斜杠。
				i = i + 2
			elseif char == "%" then
				break
			elseif char == "$" then
				local token = line:sub(i, i + 1) == "$$" and "$$" or "$"
				if delimiter == nil then
					delimiter = token
				elseif delimiter == token then
					delimiter = nil
				end
				i = i + #token
			else
				i = i + 1
			end
		end
	end
	return delimiter ~= nil
end

-- 从插入位置向前（包括前面的行）寻找字母或非 ASCII 字符。
local function should_enable_im()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local lines = vim.api.nvim_buf_get_lines(0, 0, cursor[1], false)
	lines[#lines] = lines[#lines]:sub(1, cursor[2])
	for row = #lines, 1, -1 do
		for col = #lines[row], 1, -1 do
			local byte = lines[row]:byte(col)
			if byte >= 128 then
				return true
			elseif (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) then
				return false
			end
		end
	end
	return true
end

local group = vim.api.nvim_create_augroup("AutoInputMethod", { clear = true })
local last_math = false

vim.api.nvim_create_autocmd("InsertLeave", {
	group = group,
	callback = function()
		-- 离开插入模式时静默关闭输入法，同时清除尚未消失的提示。
		indicator_version = indicator_version + 1
		if indicator_win and vim.api.nvim_win_is_valid(indicator_win) then
			vim.api.nvim_win_close(indicator_win, true)
			indicator_win = nil
		end
		set_im(false, false)
	end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
	group = group,
	callback = function()
		-- 等待 a / A / o 等命令将光标移到真正的插入位置。
		vim.schedule(function()
			if vim.api.nvim_get_mode().mode:sub(1, 1) ~= "i" then
				return
			end
			last_math = in_dollar_math()
			if last_math then
				-- 在公式内重新进入插入模式时，保留进入公式前的状态。
				-- 没有记录（例如直接打开已有公式）时，按字符规则初始化。
				if vim.b.im_before_math == nil then
					vim.b.im_before_math = should_enable_im()
				end
			else
				vim.b.im_before_math = nil
			end
			set_im(not last_math and should_enable_im(), true)
		end)
	end,
})

-- 输入、删除分隔符或移动光标时，只在数学模式发生变化时切换。
vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP", "CursorMovedI" }, {
	group = group,
	callback = function()
		local math = in_dollar_math()
		if math ~= last_math then
			last_math = math
			if math then
				vim.b.im_before_math = is_im_on()
				set_im(false, true)
			else
				set_im(vim.b.im_before_math == true, true)
				vim.b.im_before_math = nil
			end
		end
	end,
})

-- 切换 Buffer 或新建文件时：强制切回英文，避免干扰。
vim.api.nvim_create_autocmd({ "BufCreate", "BufEnter", "BufLeave" }, {
	group = group,
	callback = function()
		set_im(false, true)
	end,
})

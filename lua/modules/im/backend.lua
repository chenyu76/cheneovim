-- 输入法后端：只负责"读当前状态 / 设置为中或英"，不含任何判断逻辑。
-- 三种设备方案与旧实现一致，只是换了返回形式（get 返回 boolean 或 nil）。

local M = {}

local is_on, set_on, set_off

if vim.g.current_device == 2 then
	-- ibus：rime 与 xkb:us::eng
	is_on = function()
		return vim.trim(vim.fn.system("ibus engine")) == "rime"
	end
	set_on = function()
		vim.fn.system("ibus engine rime")
	end
	set_off = function()
		vim.fn.system("ibus engine xkb:us::eng")
	end
elseif vim.g.current_device == 1 then
	-- 大写锁定控制中英文：锁关闭即中文。需要 ydotool 与 gnome 扩展。
	local function capslock_on()
		for _, file in ipairs(vim.fn.glob("/sys/class/leds/*capslock/brightness", false, true)) do
			local handle = io.open(file, "r")
			if handle then
				local value = handle:read("*l")
				handle:close()
				if value == "1" then
					return true
				end
			end
		end
		return false
	end

	local function turn_capslock(state)
		if capslock_on() ~= state then
			vim.fn.system({ "ydotool", "key", "58:1", "58:0" })
		end
	end

	local function engine()
		return vim.trim(
			vim.fn.system(
				"gdbus call --session --dest org.gnome.Shell --object-path /raiden_fumo/InputSources --method raiden_fumo.InputSources.Get"
			)
		)
	end

	is_on = function()
		return engine() == "('rime',)" and not capslock_on()
	end
	set_on = function()
		turn_capslock(false)
		vim.fn.system(
			"gdbus call --session --dest org.gnome.Shell --object-path /raiden_fumo/InputSources --method raiden_fumo.InputSources.Set rime"
		)
	end
	set_off = function()
		vim.fn.system(
			"gdbus call --session --dest org.gnome.Shell --object-path /raiden_fumo/InputSources --method raiden_fumo.InputSources.Set us"
		)
		turn_capslock(false)
	end
else
	-- fcitx5
	is_on = function()
		return vim.trim(vim.fn.system("/usr/bin/fcitx5-remote")) == "2"
	end
	set_on = function()
		vim.fn.system("/usr/bin/fcitx5-remote -o")
	end
	set_off = function()
		vim.fn.system("/usr/bin/fcitx5-remote -c")
	end
end

--- 当前是否中文输入。返回 true / false。
function M.get()
	return is_on()
end

--- 设置输入法状态。state 为 "zh" 时打开中文，否则关闭。
--- 会先读一次当前状态，避免重复切换（切换本身有副作用和耗时）。
--- @return boolean changed 是否真的发出了切换
function M.set(state)
	local want = state == "zh"
	if is_on() == want then
		return false
	end
	if want then
		set_on()
	else
		set_off()
	end
	return true
end

--- 启动时先切到英文，避免遗留的中文状态影响普通模式按键。
function M.init()
	set_off()
end

return M

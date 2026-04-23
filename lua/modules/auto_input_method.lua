-- 三个函数
local get_im_status -- 获取当前输入法状态 (返回 1 为中文, 0 为英文)
local recover_im_status -- 根据状态恢复输入法
local close_im_status -- 强制关闭输入法 (切回英文)

if vim.g.current_device == 1 then
  -- ibus输入法: rime 和 xkb:us::eng
  get_im_status = function()
    -- system 返回的结果通常带换行符，需要 trim
    local engine = vim.trim(vim.fn.system 'ibus engine')
    if engine == 'rime' then
      return 1
    else
      return 0
    end
  end

  recover_im_status = function()
    if vim.g.my_im_status == 1 then
      vim.fn.system 'ibus engine rime'
    end
  end

  close_im_status = function()
    print(vim.fn.system 'ibus engine rime')
    vim.fn.system 'ibus engine xkb:us::eng'
  end
else
  -- fcitx5输入法: pinyin (通过 fcitx5-remote 控制)

  get_im_status = function()
    local state = vim.fn.system '/usr/bin/fcitx5-remote -n'
    if state:match 'pinyin' then
      return 1
    else
      return 0
    end
  end

  recover_im_status = function()
    if vim.g.my_im_status == 1 then
      vim.fn.system '/usr/bin/fcitx5-remote -o'
    end
  end

  close_im_status = function()
    vim.fn.system '/usr/bin/fcitx5-remote -c'
  end
end

-- 初始化变量
vim.g.my_im_status = get_im_status()

-- 离开插入模式：保存当前状态，并强制切回英文
vim.api.nvim_create_autocmd('InsertLeave', {
  pattern = '*',
  callback = function()
    vim.g.my_im_status = get_im_status()
    close_im_status()
  end,
})

-- 进入插入模式：如果之前是中文，则恢复中文
vim.api.nvim_create_autocmd('InsertEnter', {
  pattern = '*',
  callback = recover_im_status,
})

-- 切换 Buffer 或新建文件时：强制切回英文，避免干扰
vim.api.nvim_create_autocmd({ 'BufCreate', 'BufEnter', 'BufLeave' }, {
  pattern = '*',
  callback = close_im_status,
})

-- 在插入模式下连续输入两个空格时，自动切换输入法
--[[ vim.api.nvim_create_autocmd({ "InsertEnter" }, {
	pattern = { "*" },
	callback = function()
		vim.api.nvim_buf_set_keymap(0, "i", "  ", " ", {
			callback = function()
				set_fcitx_state(1 - get_fcitx_state())
				vim.g.fcitx_status = get_fcitx_state()
				vim.api.nvim_feedkeys(" ", "n", true)
			end,
		})
	end,
})

local last_space_time = 0
local space_delay = 0.3 -- 双击空格的时间间隔，单位是秒

vim.api.nvim_set_keymap("i", "<Space>", "", {
	noremap = true,
	silent = true,
	callback = function()
		local current_time = vim.fn.reltimefloat(vim.fn.reltime())
		if current_time - last_space_time < space_delay then
			-- 双击空格时切换输入法并删除一个空格
			set_fcitx_state(1 - get_fcitx_state())
			vim.g.fcitx_status = get_fcitx_state()
			-- 删除一个空格
			vim.api.nvim_input("<BS>") -- 模拟按下退格键
		else
			-- 单击空格时正常输入空格
			vim.api.nvim_input("<Space>")
		end
		last_space_time = current_time
	end,
})
-- 连续输入两次空格切换输入法并删除多余的空格
local last_space_time = 0
local space_count = 0
local space_delay = 500 -- 空格之间允许的最大时间间隔（毫秒）

vim.api.nvim_buf_set_keymap(0, "i", "<Space>", "<Nop>", {
	noremap = true,
	silent = true,
	callback = function()
		vim.notify("hit space", vim.log.levels.INFO)
		vim.api.nvim_input("<Space>")
	end,
})
vim.api.nvim_buf_set_keymap(0, "i", "<Space>", "<Nop>", {
	noremap = true,
	silent = true,
	callback = function()
		local current_time = vim.fn.reltimefloat(vim.fn.reltime())
		vim.notify("hit space", vim.log.levels.INFO)
		if current_time - last_space_time < space_delay / 1000 then
			-- 如果两次空格之间的时间间隔小于 space_delay，增加空格计数
			space_count = space_count + 1
		else
			-- 如果间隔时间较长，重置空格计数
			space_count = 1
		end

		if space_count == 2 then
			-- 双击空格时切换输入法并删除一个空格
			set_fcitx_state(1 - get_fcitx_state())
			vim.g.fcitx_status = get_fcitx_state()
			-- 删除一个空格
			-- vim.api.nvim_input("<BS>") -- 模拟按下退格键
			space_count = 0 -- 重置空格计数
		else
			vim.api.nvim_input("<Space>")
		end

		-- 更新最后一次按空格的时间
		last_space_time = current_time
	end,
})

]]
--[[ vim.keymap.set("i", "<Space>", function()
	vim.notify("输入空格", vim.log.levels.INFO)
	-- 继续插入空格
	vim.api.nvim_input("<Space>")
end, {
	noremap = false,
	silent = true,
})
-- 配置 Leader + Leader 切换输入法并进入插入模式
vim.keymap.set("i", "<Leader><Space>", function()
	set_fcitx_state(1 - get_fcitx_state())
	vim.g.fcitx_status = get_fcitx_state()
	-- vim.api.nvim_input("i") -- 进入插入模式
end, { noremap = true, silent = true })
]]

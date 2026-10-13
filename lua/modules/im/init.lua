-- 智能输入法切换：组装 container / evidence / decide / backend，并接上自动命令。
--
-- 只在两个时刻做判断：
--   1. 进入插入模式（含换 buffer 后进入）：恢复记忆或重新推断；
--   2. 插入模式里"容器类别"变了（代码 ↔ 注释 ↔ 公式 ↔ 字符串）：重新推断。
-- 容器内的内容变化不触发判断 —— 这正是"不必每次猜"的关键。
--
-- 普通模式一律保持英文（离开插入模式时切回），避免干扰按键；
-- 但插入模式用的是哪种语言会被记住，下次回到附近时先恢复。

local backend = require("modules.im.backend")
local container = require("modules.im.container")
local fallback = require("modules.im.fallback")
local evidence = require("modules.im.evidence")
local decide = require("modules.im.decide")

local M = {}

local opts = {
	indicator = true,
	window = 2048, -- 每侧最多取多少字节文本
	tau = 0.8, -- evidence 分差阈值：够了才改状态
	manual_ttl_ms = 60000, -- 用户手动切过之后，多久不跟他抢
}

--------------------------------------------------------------------------------
-- 上下文
--------------------------------------------------------------------------------

local function line_len(buf, row)
	return #(vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or "")
end

local function slice(buf, srow, scol, erow, ecol)
	if srow > erow or (srow == erow and scol >= ecol) then
		return ""
	end
	local ok, text = pcall(vim.api.nvim_buf_get_text, buf, srow, scol, erow, ecol, {})
	if not ok then
		return ""
	end
	return table.concat(text, "\n")
end

-- 取窗口文本：容器内优先（不让代码串进注释），再按行数和字节数夹紧。
local function windows(buf, row, col, bounds)
	local budget = opts.window
	local line_count = vim.api.nvim_buf_line_count(buf)

	local srow, scol = math.max(0, row - 20), math.max(0, col - budget)
	if bounds and bounds.srow then
		srow = math.max(bounds.srow, srow)
		scol = bounds.srow == srow and math.max(bounds.scol, math.max(0, col - budget)) or 0
	end

	local erow = math.min(line_count - 1, row + 20)
	if bounds and bounds.srow then
		erow = math.min(bounds.erow, erow)
	end
	local ecol = erow == row and math.min(line_len(buf, row), col + budget) or line_len(buf, erow)
	if bounds and bounds.srow and bounds.erow == erow then
		ecol = math.min(bounds.ecol, ecol)
	end

	return slice(buf, srow, scol, row, col), slice(buf, row, col, erow, ecol)
end

--- 收集一次判断需要的全部上下文（导出便于排查：拿到了什么、算出了什么）。
function M.context(buf, row, col)
	local ft = vim.bo[buf].filetype
	local c = container.at(buf, row, col)
	local kind, bounds = c.kind, c
	if kind == nil and not c.available then
		-- 没有语法树：退化到当前行的最小词法判断
		kind = fallback.kind(buf, row, col, ft)
		local srow, scol, erow, ecol = fallback.range(buf, row)
		bounds = { kind = kind, srow = srow, scol = scol, erow = erow, ecol = ecol }
	end

	local before, after = windows(buf, row, col, bounds)
	local neighbours
	if kind == "comment" or kind == "string" then
		-- 空注释/空字符串：参考附近同类容器的写法
		if #(before:gsub("%s", "")) == 0 and #(after:gsub("%s", "")) == 0 then
			neighbours = container.neighbours(buf, row, col, kind, opts.window)
		end
	end
	local zh, en, pinned = evidence.score(before, after, neighbours)

	return {
		buf = buf,
		row = row,
		col = col,
		ft = ft,
		kind = kind,
		before = before,
		after = after,
		zh = zh,
		en = en,
		pinned = pinned,
		prose = container.prose_ft(ft),
	}
end

--- 推断某个位置该用什么语言（导出给测试）。
--- @return string state, string reason, table ctx
function M.resolve(buf, row, col)
	local ctx = M.context(buf, row, col)
	local state, reason = decide.decide(ctx)
	return state, reason, ctx
end

--------------------------------------------------------------------------------
-- 指示器
--------------------------------------------------------------------------------

local indicator_buf, indicator_win, indicator_version = nil, nil, 0

local function close_indicator()
	indicator_version = indicator_version + 1
	if indicator_win and vim.api.nvim_win_is_valid(indicator_win) then
		vim.api.nvim_win_close(indicator_win, true)
	end
	indicator_win = nil
end

local function flash(state)
	if not opts.indicator then
		return
	end
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
		local label = state == "zh" and "中" or "En"
		vim.api.nvim_buf_set_lines(indicator_buf, 0, -1, false, { label })
		-- 弹窗失败（没有 UI、窗口限制等）不该影响判断本身
		local opened, win = pcall(vim.api.nvim_open_win, indicator_buf, false, {
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
		if not opened then
			return
		end
		indicator_win = win
		vim.defer_fn(function()
			if version == indicator_version and win and vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
				indicator_win = nil
			end
		end, 500)
	end)
end

--------------------------------------------------------------------------------
-- 事件
--------------------------------------------------------------------------------

local group = vim.api.nvim_create_augroup("SmartInputMethod", { clear = true })

local function apply(buf, row, col)
	local state, reason, ctx = M.resolve(buf, row, col)
	backend.set(state)
	decide.applied(buf, state)
	-- 只记容器类别：插入模式里判断是否要重新决策，就是比较它有没有变
	session = { kind = ctx.kind }
	-- 每次都提示（包括切到英文时），和旧实现一致：提示的是"当前判断结果"
	flash(state)
	return state, reason
end

function M.setup(o)
	o = o or {}
	for k, v in pairs(o) do
		opts[k] = v
	end
	decide.setup({ tau = opts.tau, manual_ttl_ms = opts.manual_ttl_ms })
	backend.init()

	vim.api.nvim_create_autocmd("InsertEnter", {
		group = group,
		callback = function()
			-- 等 a / A / o 等命令把光标移到真正的插入位置
			vim.schedule(function()
				if vim.api.nvim_get_mode().mode:sub(1, 1) ~= "i" then
					return
				end
				local buf = vim.api.nvim_get_current_buf()
				local row, col = unpack(vim.api.nvim_win_get_cursor(0))
				apply(buf, row - 1, col)
			end)
		end,
	})

	vim.api.nvim_create_autocmd({ "TextChangedI", "CursorMovedI" }, {
		group = group,
		callback = function()
			if not session then
				return
			end
			local buf = vim.api.nvim_get_current_buf()
			local row, col = unpack(vim.api.nvim_win_get_cursor(0))
			if container.at(buf, row - 1, col).kind == session.kind then
				return -- 容器没变：不做任何判断
			end
			apply(buf, row - 1, col)
		end,
	})

	vim.api.nvim_create_autocmd("InsertLeave", {
		group = group,
		callback = function()
			local buf = vim.api.nvim_get_current_buf()
			local row, col = unpack(vim.api.nvim_win_get_cursor(0))
			local actual = backend.get() and "zh" or "en"

			-- session 为空说明这次插入会话极短（InsertEnter 的延迟判断还没跑完），
			-- 此时 actual 还是切换前的状态，记下来只会污染记忆。
			if session then
				decide.remember(buf, row - 1, col, actual)
				local last = decide.applied_state(buf)
				if last and last ~= actual then
					decide.mark_manual(buf, actual) -- 用户自己切过：记住并尊重
				end
			end
			session = nil
			close_indicator()
			backend.set("en") -- 普通模式保持英文
		end,
	})

	vim.api.nvim_create_autocmd("BufLeave", {
		group = group,
		callback = function()
			session = nil
			close_indicator()
			backend.set("en")
		end,
	})

	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
		group = group,
		callback = function(args)
			session = nil
			decide.forget(args.buf)
			container.forget()
		end,
	})

	return M
end

return M

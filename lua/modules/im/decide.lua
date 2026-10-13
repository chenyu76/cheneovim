-- 决策：由可信度从高到低取第一个能回答的层，并保存"上次状态"这类记忆。
--
--  1. 容器是硬事实（代码/公式/URL）→ 英文，不需要猜。
--  2. 用户刚手动切过 → 听用户的，一段时间内不跟他抢。
--  3. 强信号（光标紧贴英文词 / 紧跟在汉字后）→ 直接采用。
--  4. 打分差超过阈值 TAU → 采用明显占优的那一边。
--  5. 有记忆（上次在这个 buffer 用的语言）→ 沿用，这就是"宁可不切"。
--  6. 都没有 → 按 filetype 默认（正文类中文，代码类英文）。
--
-- TAU 是唯一需要调的魔数，含义明确："证据差多少我才敢改变你正在用的语言"。
-- 它比"每次都重新算一个答案"重要：状态本来通常是对的，改它的门槛必须高。

local container = require("modules.im.container")
local evidence = require("modules.im.evidence")

local M = {}

local TAU = 0.8
local MANUAL_TTL_MS = 60000

-- buf -> { state, row, col, manual_until }
local memory = {}
-- buf -> 我们上一次实际设置的状态，用来识别"用户自己切过"
local applied = {}

function M.setup(opts)
	if opts and opts.tau then
		TAU = opts.tau
	end
	if opts and opts.manual_ttl_ms then
		MANUAL_TTL_MS = opts.manual_ttl_ms
	end
end

function M.tau()
	return TAU
end

--- 记录一次插入会话结束时的真实输入法状态（含用户手动切换的结果）。
function M.remember(buf, row, col, state)
	local m = memory[buf] or {}
	m.state, m.row, m.col = state, row, col
	memory[buf] = m
end

--- 标记"用户手动切过"，之后一段时间不自动改他的状态。
function M.mark_manual(buf, state)
	local m = memory[buf] or {}
	m.state = state
	m.manual_until = vim.uv.now() + MANUAL_TTL_MS
	memory[buf] = m
end

function M.applied(buf, state)
	applied[buf] = state
end

function M.applied_state(buf)
	return applied[buf]
end

function M.forget(buf)
	memory[buf] = nil
	applied[buf] = nil
end

local function manual_state(buf)
	local m = memory[buf]
	if m and m.manual_until and m.manual_until > vim.uv.now() then
		return m.state, true
	end
	return nil, false
end

--- 决策。
--- @param ctx table {
---   buf, row, col, ft,
---   kind = 容器类别或 nil, available = 是否有语法树,
---   before, after, neighbours = 容器内/附近文本,
---   zh, en, pinned = evidence.score 的结果,
---   prose = boolean 这个 filetype 是否整段算正文,
--- }
--- @return string state "zh"|"en", string reason
function M.decide(ctx)
	local kind = ctx.kind

	-- 1. 硬事实：代码/公式/URL
	if kind and container.is_en_kind(kind) then
		return "en", "container:" .. kind
	end

	-- 1b. 代码文件里"不在任何容器里"就是代码位置（空行、行首、缩进位置）。
	--     这里不看文本窗口：否则代码文件里密集的中文注释会把空行拉成中文。
	--     注释后面紧跟的空行/还在写的中文注释行会由 container 当成注释
	--     （见 comment_continuation），所以这一条不会拦住正在写的中文注释。
	if not kind and not ctx.prose then
		return "en", "code"
	end

	-- 字符串里的机器内容（URL、路径）
	if kind == "string" and (evidence.machine_left(ctx.before) or evidence.machine_right(ctx.after)) then
		return "en", "machine"
	end

	-- 2. 用户刚手动切过
	local manual, is_manual = manual_state(ctx.buf)
	if is_manual then
		return manual, "manual"
	end

	-- 3. 强信号
	if ctx.pinned then
		return ctx.pinned, "pinned:" .. ctx.pinned
	end

	-- 4. 打分差超过阈值
	local margin = (ctx.zh or 0) - (ctx.en or 0)
	if margin > TAU then
		return "zh", string.format("margin:%.2f", margin)
	end
	if margin < -TAU then
		return "en", string.format("margin:%.2f", margin)
	end

	-- 5. 沿用记忆（宁可不切）
	local m = memory[ctx.buf]
	if m then
		return m.state, "memory"
	end

	-- 6. 默认。注释按正文处理（混合语言文件里注释通常跟文档一个语言），
	--    字符串按数据/键处理（多数是 ASCII）。两者都会先被上面的记忆层覆盖，
	--    第一次遇到不准时用户手动切一次就会被记住。
	if ctx.prose or ctx.kind == "comment" then
		return "zh", "default:prose"
	end
	return "en", "default:code"
end

return M

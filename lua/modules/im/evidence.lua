-- 语言证据：给定容器内的文本，算出"中文"和"英文"各有多少分。
--
-- 纯函数，不碰 buffer/输入法/语法树，便于单测与调参。
-- 三种输出：
--   1. pinned = "en"：光标紧贴一个 ASCII 词（粘在光标上、且词前是词边界）。
--      这就是"我正在打这个英文词"，比周围正文更可信，直接压过打分。
--   2. pinned = "zh"：光标前一个字符是汉字或中文句末标点 —— 正在中文句子里续写。
--   3. 否则返回两侧加权分，由 decide 用阈值判断"够不够格改状态"。
--
-- 权重沿用旧实现的实测值：汉字 2.8 / 拉丁字母 0.45 / 中文标点 1.2，
-- 距离衰减 1/(1+d/12)^2，换行算 16 的距离，右侧乘 0.85（左侧略优先）。

local M = {}

local SCORE_CHARS = 600
local HAN_WEIGHT = 2.8
local LATIN_WEIGHT = 0.45
local ZH_PUNCT_WEIGHT = 1.2
local DISTANCE_SCALE = 12
local NEWLINE_COST = 16
local RIGHT_FACTOR = 0.85

local byte, sub = string.byte, string.sub

--------------------------------------------------------------------------------
-- 字符解码（与旧实现一致：过长编码、代理区、越界都判为无效）
--------------------------------------------------------------------------------

local function is_continuation(c)
	return c and c >= 128 and c < 192
end

local function decode(s, i)
	local a = byte(s, i)
	if not a then
		return nil, i
	end
	if a < 128 then
		return a, i + 1
	end
	local b, c, d = byte(s, i + 1, i + 3)
	if a >= 194 and a < 224 and is_continuation(b) then
		return (a - 192) * 64 + b - 128, i + 2
	end
	if a >= 224 and a < 240 and is_continuation(b) and is_continuation(c) and (a ~= 224 or b >= 160) and (a ~= 237 or b < 160) then
		return (a - 224) * 4096 + (b - 128) * 64 + c - 128, i + 3
	end
	if
		a >= 240
		and a <= 244
		and is_continuation(b)
		and is_continuation(c)
		and is_continuation(d)
		and (a ~= 240 or b >= 144)
		and (a ~= 244 or b < 144)
	then
		return (a - 240) * 262144 + (b - 128) * 4096 + (c - 128) * 64 + d - 128, i + 4
	end
	return -1, i + 1
end

-- 位置 i 之前那个字符，返回码点与它的起始位置
local function char_before(s, i)
	local at = i - 1
	if at < 1 then
		return nil, 1
	end
	local b = byte(s, at)
	if b < 128 then
		return b, at
	end
	local start, steps = at, 0
	while start > 1 and steps < 3 and is_continuation(byte(s, start)) do
		start = start - 1
		steps = steps + 1
	end
	local cp = decode(s, start)
	return cp, start
end

local function han(c)
	return c
		and (
			(c >= 0x3400 and c <= 0x4dbf)
			or (c >= 0x4e00 and c <= 0x9fff)
			or (c >= 0xf900 and c <= 0xfaff)
			or (c >= 0x20000 and c <= 0x323af)
		)
end

local function cp_set(s)
	local t, i = {}, 1
	while i <= #s do
		local c
		c, i = decode(s, i)
		t[c] = true
	end
	return t
end

local ZH_PUNCT = cp_set("，。！？；：、（）【】《》“”‘’")
local ZH_END = cp_set("，。！？；：、）】》”’")

--------------------------------------------------------------------------------
-- 强信号
--------------------------------------------------------------------------------

local function is_word_byte(b)
	return b
		and (
			(b >= 48 and b <= 57)
			or (b >= 65 and b <= 90)
			or (b >= 97 and b <= 122)
			or b == 95
			or b == 46
			or b == 45
			or b == 47
		)
end

-- 光标左侧紧贴的 ASCII 词的起点（1 基）；没有则返回 nil
local function ascii_token_start(s)
	local at = #s
	while at >= 1 and is_word_byte(byte(s, at)) do
		at = at - 1
	end
	return at + 1 <= #s and at + 1 or nil
end

local function pinned_state(before)
	local start = #before > 0 and ascii_token_start(before) or nil
	if start then
		-- 词开始之前是什么？如果是汉字，这是"中文里夹的英文词"（使用vim），不武断；
		-- 如果是空白/标点/行首，说明光标正贴着一个独立英文词 → 该用英文。
		local prev = start > 1 and char_before(before, start) or nil
		if prev == nil or (not han(prev) and not ZH_PUNCT[prev]) then
			return "en"
		end
	end
	if #before > 0 then
		local last = char_before(before, #before + 1)
		if han(last) or ZH_END[last] then
			return "zh"
		end
	end
	-- 注意：这里故意不看 after 的第一个字母。"光标紧贴右侧英文词的词首"歧义太大
	-- （夹 English|words 这类中英混排里两个方向都说得通），交给打分和阈值。
	return nil
end

--------------------------------------------------------------------------------
-- 字符串里的机器内容
--------------------------------------------------------------------------------

--- 字符串内容以 URL/路径开头 → 机器内容（旧实现的 path 规则）
function M.machine_left(text)
	return sub(text, 1, 7) == "http://"
		or sub(text, 1, 8) == "https://"
		or sub(text, 1, 2) == "./"
		or sub(text, 1, 3) == "../"
		or sub(text, 1, 1) == "/"
end

--- 光标右侧紧接 http(s):// → 正在写 URL
function M.machine_right(text)
	return sub(text, 1, 7) == "http://" or sub(text, 1, 8) == "https://"
end

--------------------------------------------------------------------------------
-- 打分
--------------------------------------------------------------------------------

--- 左侧 [before]、右侧 [after]，neighbours 是更远的同类容器内容（可为 nil）。
--- @return number zh, number en, string|nil pinned
function M.score(before, after, neighbours)
	before = before or ""
	after = after or ""
	local pinned = pinned_state(before)

	-- 左侧上下文 = 附近的同类容器 + 容器内光标前的文本
	local left = neighbours and (neighbours .. "\n" .. before) or before

	local zh, en = 0, 0

	local i, distance = #left + 1, 0
	for _ = 1, SCORE_CHARS do
		if i <= 1 then
			break
		end
		local cp, at = char_before(left, i)
		i = at
		distance = distance + (cp == 10 and NEWLINE_COST or 1)
		local denominator = 1 + distance / DISTANCE_SCALE
		local weight = 1 / (denominator * denominator)
		if han(cp) then
			zh = zh + HAN_WEIGHT * weight
		elseif cp and ((cp >= 65 and cp <= 90) or (cp >= 97 and cp <= 122)) then
			en = en + LATIN_WEIGHT * weight
		elseif ZH_PUNCT[cp] then
			zh = zh + ZH_PUNCT_WEIGHT * weight
		end
	end

	local j, distance = 1, 0
	for _ = 1, SCORE_CHARS do
		if j > #after then
			break
		end
		local cp, next_j = decode(after, j)
		j = next_j
		distance = distance + (cp == 10 and NEWLINE_COST or 1)
		local denominator = 1 + distance / DISTANCE_SCALE
		local weight = RIGHT_FACTOR / (denominator * denominator)
		if han(cp) then
			zh = zh + HAN_WEIGHT * weight
		elseif cp and ((cp >= 65 and cp <= 90) or (cp >= 97 and cp <= 122)) then
			en = en + LATIN_WEIGHT * weight
		elseif ZH_PUNCT[cp] then
			zh = zh + ZH_PUNCT_WEIGHT * weight
		end
	end

	return zh, en, pinned
end

return M

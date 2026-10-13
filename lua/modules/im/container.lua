-- 容器识别：回答"光标现在落在哪种语境里"。
--
-- 这是整个判断里唯一需要语法信息的部分，交给 treesitter（高亮已经在维护这棵树，
-- 查询成本约 0.01 ms）。得到的类别直接决定语言策略：
--
--   code  → 代码（围栏、行内代码、插值、字符字面量、json 键、LaTeX 机器参数）→ 英文
--   math  → 公式 → 英文
--   url   → 链接地址 → 英文
--   comment / string → 内容说什么语言就是什么语言（交给 evidence 打分）
--   无容器（prose）  → 同上，正文按内容打分
--
-- 两类信号都要用，实测缺一不可：
--   * capture（跨语言、对注入有效）：@markup.math、@markup.raw、@markup.link.url…
--   * 节点类型（query 没标注的地方，例如 LaTeX 数学环境内部的 math_environment）：
--     以及 sql 那种"类型名里没有 string、只有 capture 有 @string"的 grammar。
-- 覆盖情况是实测出来的：这两个表都精简到刚好覆盖用到的语法。

local M = {}

local find, sub = string.find, string.sub

-- 节点类型子串 → 类别。按"最内层优先"匹配，所以顺序即优先级。
local TYPE_RULES = {
	{ "math", "math" },
	{ "interpolation", "code" }, -- python f-string 的 {…}
	{ "template_substitution", "code" }, -- JS 模板字符串的 ${…}
	{ "code_fence_content", "code" },
	{ "fenced_code_block", "code" },
	{ "code_span", "code" },
	{ "character", "code" },
	{ "comment", "comment" },
	{ "string", "string" },
}

-- capture → 类别。节点链给不出结论时用（注入语言、markdown 行内代码、LaTeX 公式）。
local CAPTURE_RULES = {
	{ "markup.math", "math" },
	{ "markup.raw.block", "code" },
	{ "markup.raw", "code" },
	{ "markup.link.url", "url" },
	{ "character", "code" },
	{ "punctuation.special", "code" }, -- JS 模板插值
	{ "comment", "comment" },
	{ "string", "string" },
}

-- 只看英文的类别
local EN_KINDS = { code = true, math = true, url = true }

-- 整段都是正文的 filetype：没有容器时按正文处理（而不是代码）。
local PROSE_FT = {
	text = true,
	txt = true,
	plain = true,
	plaintext = true,
	markdown = true,
	md = true,
	pandoc = true,
	rst = true,
	org = true,
	gitcommit = true,
	help = true,
	tex = true,
	plaintex = true,
	latex = true,
}

function M.is_en_kind(kind)
	return kind ~= nil and EN_KINDS[kind] == true
end

function M.prose_ft(ft)
	-- 空 filetype 就是纯文本
	return ft == "" or PROSE_FT[ft] == true
end

local function type_kind(t)
	for _, rule in ipairs(TYPE_RULES) do
		if t:find(rule[1], 1, true) then
			return rule[2]
		end
	end
end

-- 语言相关的例外：capture 名字相同但含义不同。
local function capture_kind(capture, lang, ft)
	if capture == "markup.link" then
		-- LaTeX 的 @markup.link 是 \label{} / \cite{} / \ref{} 的参数（机器内容）；
		-- markdown 的 @markup.link 是链接文字（正文），不能算代码。
		return lang == "latex" and "code" or nil
	end
	if capture == "label" then
		-- LaTeX 的 @label 是 \begin{...} 的环境名之类，属于要写 ASCII 的地方；
		-- markdown 的 @label 是链接文字（正文），不能算代码。
		return lang == "latex" and "code" or nil
	end
	if capture == "property" then
		-- json 的 @property 是键（要写英文）；yaml 的键也带 @property，
		-- 但 yaml 里中文键很常见，仍按内容判断。
		return (ft == "json" or ft == "jsonc") and "code" or nil
	end
	for _, rule in ipairs(CAPTURE_RULES) do
		if capture == rule[1] then
			return rule[2]
		end
	end
end

-- 沿父链向外找同类别的节点，用来把区域的边界扩到最外层（string_content → string）。
local function outer_same_kind(node, kind)
	local outer, n = node, node
	while n do
		if type_kind(n:type()) == kind then
			outer = n
		end
		n = n:parent()
	end
	return outer
end

local cache = {}

-- 有些 grammar 里"节点类型"不足以表达语义：sql 的字符串节点叫 literal，
-- 只有 capture 是 @string；json 的键是 string 节点 + @property capture。
-- 所以两边都算，再按下面的规则合并。
-- 只看基础语法树（ignore_injections）：markdown 围栏里的内容按"围栏=代码"处理，
-- 和旧实现一致；注入语言里的行内代码、公式仍由 capture 路径提供。
local function type_path(buf, row, col)
	local ok, n = pcall(vim.treesitter.get_node, { bufnr = buf, pos = { row, col }, ignore_injections = true })
	if not ok or not n then
		return nil, nil, false
	end
	local node = n
	local cur = n
	while cur do
		local k = type_kind(cur:type())
		if k then
			return k, outer_same_kind(cur, k), true
		end
		cur = cur:parent()
	end
	return nil, node, true
end

-- 注意：没有 parser 时 get_captures_at_pos 也会"成功"返回空表，所以不能拿它
-- 判断有没有树；只有真的查出 capture 才算数。
local function capture_path(buf, row, col)
	local ok, caps = pcall(vim.treesitter.get_captures_at_pos, buf, row, col)
	if not ok or not caps then
		return nil, nil, {}, false
	end
	local ft = vim.bo[buf].filetype
	-- 同类 capture 可能重复出现，取优先级最高的那一条
	local found = #caps > 0
	for _, rule in ipairs(CAPTURE_RULES) do
		for _, c in ipairs(caps) do
			if c.capture == rule[1] then
				return capture_kind(c.capture, c.lang, ft) or rule[2], c.lang, caps, found
			end
		end
	end
	for _, c in ipairs(caps) do
		local k = capture_kind(c.capture, c.lang, ft)
		if k then
			return k, c.lang, caps, found
		end
	end
	return nil, nil, caps, found
end

local function query(buf, row, col)
	local kind, node, available = type_path(buf, row, col)
	local cap_kind, _, _, caps_ok = capture_path(buf, row, col)
	available = available or caps_ok

	if not kind then
		kind = cap_kind
	elseif cap_kind == "code" or cap_kind == "math" or cap_kind == "url" then
		-- capture 只能把"字符串/注释"升级成机器内容（json 键 → @property、
		-- 字符字面量 → @character、行内代码 → @markup.raw），不能反向降级：
		-- python 的 f-string 插值节点类型已经是 code，不会被 @string 拉回字符串。
		if kind == "string" or kind == "comment" then
			kind = cap_kind
			node = nil -- capture 不带节点，边界退化为窗口夹紧
		end
	end

	return kind, node, available
end

-- 插入点的容器可能"正好结束在光标处"：空注释（`x = 1  # |`）、注释行尾。
-- 注释没有闭合分隔符，可以安全地往左看一个字符；字符串/公式有闭合分隔符，
-- 往左看会把"刚打完引号"误判成还在字符串里，所以只对注释做这个延伸。
local function comment_ending_here(buf, row, col)
	if col <= 0 then
		return nil
	end
	local kind, node = type_path(buf, row, col - 1)
	if kind == "comment" and node then
		local erow, ecol = select(3, node:range()), select(4, node:range())
		if erow == row and ecol == col then
			return node
		end
	end
	return nil
end

-- 注释续行：前一行是注释（或它本身也是这样的续行），且当前行没有任何 ASCII
-- 字母数字 → 当作还在写注释。
--
-- 为什么需要它：在注释块里按 o 开新行，用户往往直接开始输入中文（Lua 要打 --，
-- 中文注释也可能整段不加前缀）。这时语法树里那一行还不是注释节点，光看容器会
-- 落回"代码位置 = 英文"，把正在写的中文判回英文。一旦行里出现 ASCII 字母数字，
-- 说明在写代码/标识符，立刻交回代码语境。
local function comment_continuation(buf, row, col)
	if row <= 0 then
		return nil
	end
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
	if line:find("[%w]") then
		return nil
	end
	for r = row - 1, math.max(0, row - 20), -1 do
		local prev = vim.api.nvim_buf_get_lines(buf, r, r + 1, false)[1] or ""
		local last = #prev
		while last > 0 and prev:sub(last, last):match("%s") do
			last = last - 1
		end
		if last > 0 then
			local kind, node = type_path(buf, r, last - 1)
			if kind == "comment" then
				return node
			end
			if kind ~= nil then
				return nil -- 上一行落在别的容器里（字符串等），不算注释续行
			end
		end
		if prev:find("[%w]") then
			return nil -- 上一层是代码行：注释块到此为止
		end
	end
	return nil
end

-- TeX 特有的两条文本规则。语法树对这两种情况都不能直接给出结论：
--   * 刚敲下第一个 $（还没闭合）时还不是公式节点，而用户正是靠这一步切英文；
--   * 命令名中间（\sect|）没有任何 capture。
local TEX_FT = { tex = true, plaintex = true, latex = true }

-- 光标前是"\ + 一串字母（或刚打完反斜杠）"→ 正在打命令名，用英文
local function tex_command(buf, row, col)
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
	return line:sub(1, col):match("\\[%a@]*$") ~= nil
end

-- 光标是否落在未闭合的 $ … $ / $$ … $$ / \(…\) / \[…\] 里。
-- 与旧实现一致：% 注释和 \x 转义里的分隔符不参与判断（所以 \$ 不是数学）。
local function tex_math(buf, row, col)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, row + 1, false)
	local text = table.concat(lines, "\n")
	if #lines > 0 then
		text = text:sub(1, #text - (#lines[#lines] - col))
	end
	local i, math = 1, nil
	while i <= #text do
		local j = find(text, "[%%$\\]", i)
		if not j then
			break
		end
		local c = sub(text, j, j)
		if c == "%" then
			local nl = find(text, "\n", j, true)
			if not nl then
				break
			end
			i = nl + 1
		elseif c == "\\" then
			local nxt = sub(text, j + 1, j + 1)
			if nxt == "(" or nxt == ")" or nxt == "[" or nxt == "]" then
				local token = sub(text, j, j + 1)
				if not math and (token == "\\(" or token == "\\[") then
					math = token
				elseif (math == "\\(" and token == "\\)") or (math == "\\[" and token == "\\]") then
					math = nil
				end
				i = j + 2
			else
				i = j + 2 -- 转义字符整个跳过（\$ 里的 $ 不算数学）
			end
		else
			local token = sub(text, j, j + 1) == "$$" and "$$" or "$"
			if not math then
				math = token
			elseif math == token then
				math = nil
			end
			i = j + #token
		end
	end
	return math and "math" or nil
end

--- 查询光标所在的容器。
--- @param buf integer
--- @param row integer 0 基行号
--- @param col integer 0 基字节列
--- @return table { kind = string|nil, available = boolean, srow, scol, erow, ecol, node }
---   kind 为 nil 表示"不在任何容器里"（正文或代码，由调用方按 filetype 决定）。
---   available 为 false 表示这个 buffer 拿不到语法树（没有 parser/没开高亮），应走 fallback。
function M.at(buf, row, col)
	local c = cache
	if c.buf == buf and c.tick == vim.b[buf].changedtick and c.row == row and c.col == col then
		return c.result
	end

	local kind, node, available = query(buf, row, col)
	if kind and node then
		local srow, scol = node:range()
		if srow == row and scol == col then
			-- 光标正好在容器的起始分隔符上（注释的 #、字符串的开引号）：
			-- 插入发生在分隔符之前，属于容器外。
			kind, node = nil, nil
		end
	end
	if not kind then
		node = comment_ending_here(buf, row, col) or comment_continuation(buf, row, col)
		if node then
			kind = "comment"
		end
	end
	if not kind and TEX_FT[vim.bo[buf].filetype] then
		if tex_command(buf, row, col) then
			kind = "code"
		else
			kind = tex_math(buf, row, col)
		end
	end
	local result = { kind = kind, available = available }
	if node then
		local srow, scol, erow, ecol = node:range()
		result.srow, result.scol, result.erow, result.ecol = srow, scol, erow, ecol
		result.node = node
	end

	cache = { buf = buf, tick = vim.b[buf].changedtick, row = row, col = col, result = result }
	return result
end

--- 同类相邻容器的内容（用于空注释/空字符串：参考附近同类区域的写法）。
--- 只在 budget 字节内查找，找不到返回 nil。
--- @return string|nil
function M.neighbours(buf, row, col, kind, budget)
	budget = budget or 2048
	local ok, node = pcall(vim.treesitter.get_node, { bufnr = buf, pos = { row, col } })
	if not ok or not node then
		return nil
	end
	local cur = node
	while cur do
		for _, dir in ipairs({ "prev", "next" }) do
			local sib = dir == "prev" and cur:prev_named_sibling() or cur:next_named_sibling()
			local steps = 0
			while sib and steps < 8 do
				local srow = select(1, sib:range())
				local erow = select(3, sib:range())
				if math.abs(srow - row) > 60 then
					break
				end
				if type_kind(sib:type()) == kind then
					local text = table.concat(vim.api.nvim_buf_get_text(buf, srow, select(2, sib:range()), erow, select(4, sib:range()), {}), "\n")
					if #text <= budget then
						return text
					end
					return nil
				end
				sib = dir == "prev" and sib:prev_named_sibling() or sib:next_named_sibling()
				steps = steps + 1
			end
		end
		cur = cur:parent()
	end
	return nil
end

function M.forget()
	cache = {}
end

return M

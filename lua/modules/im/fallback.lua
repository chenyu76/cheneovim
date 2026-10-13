-- 没有语法树时的容器判断（没有 parser，或这个缓冲区没开高亮）。
--
-- 只做"当前行的最小区分"：从左到右扫一遍当前行，跟踪引号状态，
-- 遇到注释标记就判断光标在不在注释里。对 fallback 来说够用了——
-- 它只负责不把中文注释当代码、不把代码当注释；正文filetype直接按正文处理。
-- 多行块注释、嵌套注释、注入语言都不处理，那些交给 treesitter 那条路。

local M = {}

local function set(words)
	local t = {}
	for w in words:gmatch("%S+") do
		t[w] = true
	end
	return t
end

-- 反斜杠注释家族（最常见的配置类文件都在这里）
local HASH = set("python py ruby rb julia sh bash zsh fish yaml yml toml r perl elixir conf dosini ini "
	.. "dockerfile make makefile nix cmake gitconfig desktop systemd terraform apache nginx tmux kitty alacritty sshconfig")

local DASH = set("lua sql haskell hs")
local PERCENT = set("tex latex plaintex matlab octave")
local SEMICOLON = set("lisp scheme clojure asm")
local BANG = set("fortran")
local MD_LIKE = set("markdown md pandoc rst org")

local function line_markers(ft)
	if HASH[ft] then
		return { "#" }
	elseif DASH[ft] then
		return { "--" }
	elseif PERCENT[ft] then
		return { "%" }
	elseif SEMICOLON[ft] then
		return { ";" }
	elseif BANG[ft] then
		return { "!" }
	elseif ft == "vim" or ft == "vimscript" then
		return { '"' }
	end
	return { "//" }
end

local function is_continuation(b)
	return b and b >= 128 and b < 192
end

-- 行首到 col 之间，光标是否在注释里；返回注释起点（1 基）或 nil
local function comment_start(line, col, markers, quotes)
	local i, quote = 1, nil
	while i <= col do
		local b = line:byte(i)
		if quote then
			if b == 92 then
				i = i + 2
			elseif b == quote then
				quote = nil
				i = i + 1
			else
				-- 跳过整个字符，避免把多字节字符的后续字节当成 ASCII
				local next_b = line:byte(i + 1)
				i = is_continuation(next_b) and i + 2 or i + 1
			end
		else
			local matched
			for _, m in ipairs(markers) do
				if line:sub(i, i + #m - 1) == m then
					matched = m
					break
				end
			end
			if matched then
				return i
			elseif quotes[b] then
				quote = b
				i = i + 1
			else
				i = i + 1
			end
		end
	end
	return nil
end

-- 光标是否在某个未闭合的引号里
local function in_quote(line, col, quotes)
	local i, quote = 1, nil
	while i <= col do
		local b = line:byte(i)
		if quote then
			if b == 92 then
				i = i + 2
			elseif b == quote then
				quote = nil
				i = i + 1
			else
				i = i + 1
			end
		elseif quotes[b] then
			quote = b
			i = i + 1
		else
			i = i + 1
		end
	end
	return quote ~= nil
end

-- markdown 家族：反引号行内代码 + 围栏
local function markdown_container(buf, row, col)
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
	if select(2, line:sub(1, col):gsub("`", "")) % 2 == 1 then
		return "code"
	end
	local fences = 0
	local from = math.max(0, row - 200)
	for _, l in ipairs(vim.api.nvim_buf_get_lines(buf, from, row, false)) do
		if l:match("^%s*```") or l:match("^%s*~~~") then
			fences = fences + 1
		end
	end
	if fences % 2 == 1 then
		return "code"
	end
end

--- 判断当前行里的容器。
--- @return string|nil "comment" | "string" | "code" | nil（无容器）
function M.kind(buf, row, col, ft)
	if MD_LIKE[ft] then
		return markdown_container(buf, row, col)
	end
	if require("modules.im.container").prose_ft(ft) then
		-- 纯正文：没有"注释/字符串"这回事，别拿 // 去误判 URL
		return nil
	end
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
	local markers = line_markers(ft)
	if ft == "vim" or ft == "vimscript" then
		-- vim 的双引号是注释，单引号才是字符串
		if comment_start(line, col, markers, { [39] = true }) then
			return "comment"
		end
	elseif comment_start(line, col, markers, { [34] = true, [39] = true }) then
		return "comment"
	end
	if in_quote(line, col, { [34] = true, [39] = true }) then
		return "string"
	end
	-- 注释续行：上一行是注释，且本行还没有 ASCII 字母数字（在写中文注释）
	if not line:find("[%w]") and row > 0 then
		local prev = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
		if comment_start(prev, #prev, markers, { [34] = true, [39] = true }) then
			return "comment"
		end
	end
	return nil
end

--- 容器范围（fallback 用当前行近似，够 evidence 取窗口用）。
function M.range(buf, row)
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
	return row, 0, row, #line
end

return M

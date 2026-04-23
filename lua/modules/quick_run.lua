-- quickly run code snippets or files based on their file type.

-- different file types use different commands to run
-- Three ways to define commands:
-- 1. string:
--      a command pattern with optional variables:
--        $dir
--        $dirWithoutTrailingSlash
--        $fullFileName
--        $fileName
--        $fileNameWithoutExt
--        $arg
-- 2. function:
--      a Lua function that executes the desired command(s)
-- 3. table:
--      a table with a 'cmd' field (string or function)
--      and optional field:
--        reload(boolean): reload the file after running the command
--        shebang(boolean): use shebang line if present
local ft_cmds = {
	python = {
		cmd = 'cd "$dir" && python "$fileName" $arg',
		-- reload = true,
		shebang = true,
	},
	typst = 'cd "$dir" && typst compile "$fileName"',
	sh = {
		cmd = 'cd "$dir" && bash "$fullFileName"',
		-- reload = true,
		shebang = true,
	},
	c = 'cd "$dir" && gcc ./$fileName -o ./$fileNameWithoutExt.o && ./$fileNameWithoutExt.o $arg',
	cpp = 'cd "$dir" && g++ ./$fileName -o ./$fileNameWithoutExt.o && ./$fileNameWithoutExt.o $arg',
	fortran = 'cd "$dir" && gfortran ./$fileName -o ./$fileNameWithoutExt.o && ./$fileNameWithoutExt.o $arg',
	java = "javac $fullFileName",
	javascript = "node $fullFileName",
	tex = function()
		RunProject(".latexmkrc", "latexmk && exit", function()
			TryBibTeX()
			RunCommand('cd "$dir" && xelatex -synctex=1 --shell-escape -interaction=nonstopmode "$fileName" && exit')
		end, { cd = true })
	end,
	rust = function()
		RunProject(
			"Cargo.toml",
			"cargo run",
			"rustc $fullFileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
			{ cd = true }
		)
	end,
	haskell = function()
		RunProject(
			"*.cabal",
			"cabal run",
			'runhaskell "$fullFileName"',
			{ glob = true, cd = true } -- glob 模式查找 *.cabal 文件
		)
	end,
	html = "xdg-open $fullFileName && exit",
	go = "go run $fileName",
	ruby = "ruby $fullFileName",
	php = "php $fullFileName",
	swift = "swift $fullFileName",
	lua = "lua $fullFileName",
	perl = "perl $fullFileName",
	r = "Rscript $fullFileName",
	groovy = "groovy $fullFileName",
	kotlin = "kotlinc $fullFileName -include-runtime -d $fileNameWithoutExt.jar && java -jar $fileNameWithoutExt.jar",
	dart = "dart run $fullFileName",
	elixir = "elixir $fullFileName",
	clojure = "clojure -M $fullFileName",
	scala = "scala $fullFileName",
	julia = "julia $fullFileName",
	ocaml = "ocaml $fullFileName",
	nim = "nim c -r $fullFileName",
	v = "v run $fullFileName",
	zig = "zig run $fullFileName",
}

-- @param marker: 标志文件 (如 "Cargo.toml") 或通配符 (如 "*.cabal")
-- @param cmd_project: 找到 marker 时执行的命令字符串
-- @param cmd_fallback: 没找到时执行的命令字符串或函数
-- @param opts: 配置表 { glob = boolean, cd = boolean }
function RunProject(marker, cmd_project, cmd_fallback, opts)
	opts = opts or {}
	local use_glob = opts.glob or false
	local auto_cd = opts.cd or true

	local current_file = vim.fn.expand("%:p")
	local dir = vim.fn.fnamemodify(current_file, ":h")
	local home = vim.fn.expand("$HOME")
	local found = false

	while true do
		local match = false
		if use_glob then
			if vim.fn.glob(dir .. "/" .. marker) ~= "" then
				match = true
			end
		else
			if vim.fn.filereadable(dir .. "/" .. marker) == 1 then
				match = true
			end
		end

		if match then
			found = true
			break -- 此时 dir 变量即为找到 marker 的目录
		end

		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir or parent == home then
			break
		end
		dir = parent
	end

	if found then
		local final_cmd = cmd_project
		-- 如果开启了 auto_cd，则组合 cd 命令
		if auto_cd then
			final_cmd = 'cd "' .. dir .. '" && ' .. cmd_project
		end
		RunCommand(final_cmd)
	else
		if type(cmd_fallback) == "function" then
			cmd_fallback()
		else
			RunCommand(cmd_fallback)
		end
	end
end

-- 通用命令执行函数（支持 TermExec 和路径格式化）
function RunCommand(cmd_pattern, arg)
	-- 获取文件路径信息
	local file_info = {
		dir = vim.fn.expand("%:p:h"), -- 文件所在目录（含末尾斜杠）
		dirWithoutTrailingSlash = vim.fn.expand("%:p:h:gs?/?$??"), -- 去除末尾斜杠的目录
		fullFileName = vim.fn.expand("%:p"), -- 完整文件路径
		fileName = vim.fn.expand("%:t"), -- 带扩展名的文件名
		fileNameWithoutExt = vim.fn.expand("%:t:r"), -- 不带扩展名的文件名
		arg = arg or "", -- 传递给脚本的参数
	}

	-- 路径转义处理函数（处理空格和特殊字符）
	local escape_shell = function(s)
		return s:gsub('"', '\\"'):gsub("'", "\\'")
	end

	-- 替换格式化变量
	local cmd = cmd_pattern:gsub("$(%w+)", function(var)
		local value = file_info[var]
		if value then
			-- 特殊处理目录末尾斜杠
			if var == "dirWithoutTrailingSlash" then
				value = value:gsub("/+$", "")
			end
			return value
		end
		return "$" .. var -- 未识别的变量保持原样
	end)

	-- 执行 TermExec 命令
	-- vim.notify('TermExec cmd="' .. escape_shell(cmd) .. '"')
	-- vim.cmd 'ToggleTerm' -- 打开终端窗口
	-- vim.cmd("TermExec cmd='" .. cmd .. "' dir='" .. file_info.dir .. "'")
	local opts = {
		cwd = file_info.dir,
		-- auto_close = false,
		-- auto_insert = true,
		-- start_insert = true,
	}
	-- Snacks.terminal.toggle(cmd, opts)
	if string.sub(cmd, -4) == "exit" then
		Snacks.terminal.toggle(cmd, opts)
	else
		Snacks.terminal.toggle('fish -C "' .. cmd .. '"', opts)
	end
end

-- Shebang 检测函数
local function get_shebang_command()
	local file_path = vim.fn.expand("%:p")
	local file = io.open(file_path, "r")
	if not file then
		return nil
	end
	local first_line = file:read("*l")
	file:close()

	if not first_line or first_line:sub(1, 2) ~= "#!" then
		return nil
	end

	local shebang = first_line:sub(3)
	-- 清理 Shebang 行的换行符和尾部空格
	shebang = shebang:gsub("%s+$", "")
	-- 获取完整文件路径并拼接命令
	local fullFileName = vim.fn.expand("%:p")
	return shebang .. " " .. fullFileName
end

-- 检查所有窗口中的缓冲区并重载
local function reload_modified_buffers()
	-- 遍历所有窗口
	for _, winid in ipairs(vim.api.nvim_list_wins()) do
		-- 获取该窗口中的缓冲区 ID
		local bufnr = vim.api.nvim_win_get_buf(winid)

		-- 检查该缓冲区是否有一个关联的文件（非 scratch/unlisted 缓冲区）
		-- 并且该文件是可见的（即在某个窗口中显示）
		if
			vim.api.nvim_get_option_value("buflisted", { buf = bufnr })
			and vim.api.nvim_get_option_value("filetype", { buf = bufnr }) ~= ""
		then
			-- 在该窗口执行 :checktime
			-- :checktime 会检查该缓冲区文件在磁盘上的修改时间。
			-- 如果文件在外部修改了，且缓冲区未修改，它会自动重新加载。
			vim.api.nvim_win_call(winid, function()
				vim.cmd("checktime")
			end)
		end
	end
end

-- 主函数，根据文件类型选择命令执行
-- arg 参数可选，传递给脚本
function RunCurrentFile(arg)
	vim.cmd("w") -- 先保存文件

	local filetype = vim.bo.filetype
	local ft_cmd = ft_cmds[filetype]
	local cmd = {}

	if type(ft_cmd) == "table" then
		cmd = ft_cmd
	else
		cmd = {
			cmd = ft_cmd,
		}
	end

	if not cmd or not cmd.cmd then -- 增加一点健壮性检查
		vim.notify("No command defined for filetype: " .. filetype, vim.log.levels.WARN)
	else
		if type(cmd.cmd) == "function" then
			cmd.cmd() -- 如果是函数，调用它
		else
			-- 逻辑修正：尝试 Shebang，如果失败则回退到默认命令
			local ran_via_shebang = false

			if cmd.shebang then
				local shebang_cmd = get_shebang_command()
				if shebang_cmd then
					RunCommand(shebang_cmd, arg)
					ran_via_shebang = true
				end
			end

			-- 如果没有通过 shebang 运行（可能是没开 shebang 选项，也可能是没找到 shebang 行）
			-- 则执行默认定义的命令
			if not ran_via_shebang then
				RunCommand(cmd.cmd, arg)
			end
		end

		if cmd.reload then
			-- 重载所有修改过的缓冲区
			-- 愚蠢的延时技巧，确保在命令执行后的一段时间内检查文件修改
			vim.defer_fn(reload_modified_buffers, 300)
			vim.defer_fn(reload_modified_buffers, 1000)
			vim.defer_fn(reload_modified_buffers, 2000)
		end
	end
end

function RunCurrentFileWithArg()
	vim.cmd("w") -- 先保存文件
	local arg = vim.fn.input("Input arguments: ")
	RunCurrentFile(arg)
end

-- 编译tex文件时，检查是否需要运行 BibTeX并执行
function TryBibTeX()
	local tex_path = vim.fn.expand("%:p") -- 获取当前 tex 文件的完整路径
	local aux_path = tex_path:gsub("%.tex$", ".aux") -- 生成对应的 aux 文件路径

	-- 检查 aux 文件是否存在
	local aux_file = io.open(aux_path, "r")
	if not aux_file then
		return
	end

	-- 检查是否包含 bibdata 条目
	local needs_bibtex = false
	for line in aux_file:lines() do
		if line:find("\\bibdata{") then
			needs_bibtex = true
			break
		end
	end
	aux_file:close()

	-- 执行 BibTeX 编译
	if needs_bibtex then
		-- 静默执行并捕获输出
		local success, output = pcall(
			vim.fn.systemlist,
			"cd " .. vim.fn.expand("%:p:h") .. " &&  bibtex " .. vim.fn.shellescape(vim.fn.expand("%:t:r") .. ".aux")
		)

		-- 显示编译结果
		if success then
			vim.notify("BibTeX build success:\n" .. table.concat(output, "\n"), vim.log.levels.INFO)
		else
			vim.notify("BibTeX build fail:\n" .. table.concat(output, "\n"), vim.log.levels.ERROR)
		end
	end
end

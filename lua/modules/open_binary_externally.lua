--- 将检测为二进制的文件交给系统默认应用。
--- 用于 Neo-tree 的 file_open_requested 事件；
---
--- 输入：{ path = 文件路径, ... }
---   path 为可选字符串；缺省时不处理。建议传绝对路径，相对路径基于
---   Neovim 当前工作目录解析。路径作为独立进程参数传递，无需 shell 转义。
---   其他字段全部忽略，调用方可以直接传入自己的文件打开事件对象。
---
--- 返回值：
---   nil：未接管，调用方应继续执行原来的打开操作。包括文本、空文件、
---   非普通文件、路径不存在，以及检测工具缺失或检测失败等情况。
---   { handled = true }：已接管，调用方应停止原来的打开操作。
---   handled 表示拦截决定，不保证外部应用打开成功；已确认是二进制时，
---   即使 xdg-open 缺失或启动失败，也返回该结果，避免退回编辑二进制内容。
---   错误通过 vim.notify / vim.notify_once 提示。
---@param args { path?: string } 文件打开请求；允许携带额外字段。
---@return { handled: boolean }? result 接管时返回 handled=true，否则返回 nil。
return function(args)
	local path = args.path
	local stat = path and vim.uv.fs_stat(path)
	if not stat or stat.type ~= "file" or stat.size == 0 then
		return
	end

	if vim.fn.executable("file") ~= 1 then
		vim.notify_once("External open: binary detection requires the file command", vim.log.levels.WARN)
		return
	end

	-- Detect content rather than extensions; follow symlinks and preserve Unicode text.
	local result = vim.system({ "file", "--brief", "--mime-encoding", "--dereference", "--", path }, {
		text = true,
	}):wait(1000)
	if result.code ~= 0 then
		vim.notify("External open: could not detect file encoding: " .. path, vim.log.levels.WARN)
		return
	end
	if vim.trim(result.stdout or "") ~= "binary" then
		return
	end

	-- file(1) reports very short text (e.g. a single newline) as binary.
	-- Check the entire small file, so a text prefix cannot hide binary data.
	if stat.size <= 8192 then
		local fd = vim.uv.fs_open(path, "r", 438)
		if fd then
			local content = vim.uv.fs_read(fd, 8193, 0)
			vim.uv.fs_close(fd)
			if content and #content <= 8192 and not content:find("[^\t\r\n\032-\126]") then
				return
			end
		end
	end

	if vim.fn.executable("xdg-open") ~= 1 then
		vim.notify("External open: xdg-open is not installed", vim.log.levels.ERROR)
		return { handled = true }
	end

	-- Pass an argument list so spaces and shell metacharacters stay literal.
	local ok, err = pcall(vim.system, { "xdg-open", path }, { text = true, detach = true }, function(open_result)
		if open_result.code ~= 0 then
			vim.schedule(function()
				local detail = vim.trim(open_result.stderr or "")
				vim.notify("External open: failed: " .. path .. "\n" .. detail, vim.log.levels.ERROR)
			end)
		end
	end)
	if not ok then
		vim.notify("External open: " .. tostring(err), vim.log.levels.ERROR)
	end
	return { handled = true }
end

-- Intercept all Neo-tree open commands, including splits and tabs.
return function(args)
	local path = args.path
	local stat = path and vim.uv.fs_stat(path)
	if not stat or stat.type ~= "file" or stat.size == 0 then
		return
	end

	if vim.fn.executable("file") ~= 1 then
		vim.notify_once("Neo-tree: binary detection requires the file command", vim.log.levels.WARN)
		return
	end

	-- Detect content rather than extensions; follow symlinks and preserve Unicode text.
	local result = vim.system({ "file", "--brief", "--mime-encoding", "--dereference", "--", path }, {
		text = true,
	}):wait(1000)
	if result.code ~= 0 then
		vim.notify("Neo-tree: could not detect file encoding: " .. path, vim.log.levels.WARN)
		return
	end
	if vim.trim(result.stdout or "") ~= "binary" then
		return
	end

	if vim.fn.executable("xdg-open") ~= 1 then
		vim.notify("Neo-tree: xdg-open is not installed", vim.log.levels.ERROR)
		return { handled = true }
	end

	-- Pass an argument list so spaces and shell metacharacters stay literal.
	local ok, err = pcall(vim.system, { "xdg-open", path }, { text = true, detach = true }, function(open_result)
		if open_result.code ~= 0 then
			vim.schedule(function()
				local detail = vim.trim(open_result.stderr or "")
				vim.notify("Neo-tree: external open failed: " .. path .. "\n" .. detail, vim.log.levels.ERROR)
			end)
		end
	end)
	if not ok then
		vim.notify("Neo-tree: " .. tostring(err), vim.log.levels.ERROR)
	end
	return { handled = true }
end

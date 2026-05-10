local configPath = vim.fn.stdpath("config")
local run_matlab_command = 'cd "$dir" && '
	.. configPath
	.. "/bundle/matlab-engine/bin/python "
	.. configPath
	.. '/lua/modules/matlab_server/run_matlab.py "$fullFileName"'

-- 当打开 matlab 文件时，才注册退出时关闭 MATLAB 后台服务器的钩子
vim.api.nvim_create_autocmd("FileType", {
	pattern = "matlab",
	group = vim.api.nvim_create_augroup("MatlabServerManager", { clear = true }),
	callback = function()
		if _G.matlab_server_kill_registered then
			return
		end
		_G.matlab_server_kill_registered = true

		vim.api.nvim_create_autocmd("VimLeavePre", {
			group = vim.api.nvim_create_augroup("KillMatlabServer", { clear = true }),
			callback = function()
				local py_script = [[
import socket, os
try:
    sock_path = '/tmp/matlab_engine_' + os.getlogin() + '.sock'
    if os.path.exists(sock_path):
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(sock_path)
        s.sendall(b'__EXIT__')
        s.close()
except:
    pass
]]
				-- 使用 system 静默执行关闭指令
				vim.fn.system({ "python3", "-c", py_script })
			end,
		})
	end,
})

return run_matlab_command

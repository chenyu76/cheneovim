-- 确保你已经在环境变量中设置了 DEEPSEEK_API_KEY
-- 例如在 ~/.bashrc 或 ~/.zshrc 中: export DEEPSEEK_API_KEY="your_api_key_here"

-- 核心交互函数
function _G.AskDeepSeek(is_visual)
	local api_key = os.getenv("DEEPSEEK_API_KEY") or vim.g.deepseek_api_key
	if not api_key or api_key == "" then
		vim.notify("Can not find DeepSeek api key.", vim.log.levels.ERROR)
		return
	end

	local selected_text = ""
	local insert_pos = vim.api.nvim_win_get_cursor(0) -- 默认插入位置为当前光标

	-- 如果是在可视模式下调用，获取选中的文本
	if is_visual then
		-- 获取可视模式的起始和结束标记
		local s_start = vim.fn.getpos("'<")
		local s_end = vim.fn.getpos("'>")

		-- 提取选区多行文本
		local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
		if #lines > 0 then
			-- 简单处理，将选中的所有行合并
			selected_text = table.concat(lines, "\n")
		end
		-- 将后续内容的插入位置设定为选区的末尾行和列
		insert_pos = { s_end[2], s_end[3] }
	end

	-- 弹出输入框询问用户
	vim.ui.input({ prompt = "Ask DeepSeek: " }, function(user_input)
		if not user_input or user_input == "" then
			vim.notify("Cancel", vim.log.levels.INFO)
			return
		end

		-- 拼接最终发送的 Prompt
		local final_prompt = user_input
		if is_visual and selected_text ~= "" then
			final_prompt = final_prompt .. "\n\n以下是选中的内容:\n```\n" .. selected_text .. "\n```"
		end

		-- 构建 JSON Payload，严格使用你提供的结构
		local payload = {
			model = "deepseek-v4-pro",
			messages = {
				{
					role = "system",
					content = "You are a helpful assistant. Please output your response directly without unnecessary wrapper text and be concise.",
				},
				{ role = "user", content = final_prompt },
			},
			thinking = { type = "enabled" },
			reasoning_effort = "high",
			stream = false,
		}

		-- 将 payload 写入临时文件以供 curl 使用（避免命令行参数转义带来的麻烦）
		local json_payload = vim.fn.json_encode(payload)
		local tmp_file = vim.fn.tempname() .. ".json"
		vim.fn.writefile({ json_payload }, tmp_file)

		vim.notify("DeepSeek thinking...", vim.log.levels.INFO)

		-- 异步调用 curl
		vim.fn.jobstart({
			"curl",
			"-s",
			"https://api.deepseek.com/chat/completions",
			"-H",
			"Content-Type: application/json",
			"-H",
			"Authorization: Bearer " .. api_key,
			"-d",
			"@" .. tmp_file,
		}, {
			stdout_buffered = true,
			on_stdout = function(_, data)
				if not data or #data == 0 or (data[1] == "" and #data == 1) then
					return
				end

				local response_str = table.concat(data, "\n")
				local ok, response_json = pcall(vim.fn.json_decode, response_str)

				-- 确保必须回到 Neovim 的主线程操作 Buffer
				vim.schedule(function()
					if ok and response_json.choices and response_json.choices[1] then
						local content = response_json.choices[1].message.content
						-- 移除 Windows 回车符并将文本分割成多行
						content = content:gsub("\r", "")
						local output_lines = vim.split(content, "\n")

						if is_visual then
							-- 光标移动到选区末尾
							vim.api.nvim_win_set_cursor(0, { insert_pos[1], 0 })
							-- 移动到行尾并向下新建一行插入（防止打乱原本的结尾结构）
							vim.cmd("normal! G")
							vim.api.nvim_win_set_cursor(0, { insert_pos[1], insert_pos[2] })
						end

						-- 将 AI 返回的内容插入光标处
						vim.api.nvim_put(output_lines, "c", true, true)
						vim.notify("DeepSeek answer!", vim.log.levels.INFO)
					else
						vim.notify("Error: \n" .. response_str, vim.log.levels.ERROR)
					end
					-- 清理临时文件
					vim.fn.delete(tmp_file)
				end)
			end,
			on_stderr = function(_, data)
				if data and #data > 0 and data[1] ~= "" then
					vim.schedule(function()
						vim.notify("curl error: " .. table.concat(data, "\n"), vim.log.levels.WARN)
					end)
				end
			end,
		})
	end)
end

-- ==================== 快捷键绑定 ====================

-- 普通模式下：向 AI 提问并插入到光标处（例如绑定到 <leader>da）
-- vim.keymap.set("n", "<leader>da", function()
-- 	_G.AskDeepSeek(false)
-- end, { noremap = true, silent = true, desc = "Ask DeepSeek (Normal)" })

-- 可视模式下：连同选中的文本一起问 AI，并在选区末尾插入结果
-- 注意：这里必须使用 :<C-u> 先退出可视模式，这样 '< 和 '> 标记才会更新为当前最新选区
-- vim.keymap.set(
-- 	"v",
-- 	"<leader>da",
-- 	":<C-u>lua _G.AskDeepSeek(true)<CR>",
-- 	{ noremap = true, silent = true, desc = "Ask DeepSeek (Visual)" }
-- )


-- INFO: format
vim.pack.add({
	"https://github.com/stevearc/conform.nvim",
})

require("conform").setup({
	notify_on_error = true,
	format_on_save = false,
	--    function(bufnr)
	-- 	-- Disable "format_on_save lsp_fallback" for languages that don't
	-- 	-- have a well standardized coding style. You can add additional
	-- 	-- languages here or re-enable it for the disabled ones.
	-- 	local disable_filetypes = { c = true, cpp = true, tex = true }
	-- 	if disable_filetypes[vim.bo[bufnr].filetype] then
	-- 		return nil
	-- 	else
	-- 		return {
	-- 			timeout_ms = 500,
	-- 			lsp_format = "fallback",
	-- 		}
	-- 	end
	-- end,
	formatters = {
		-- 配置 shfmt 的参数 (默认是 -w)
		shfmt = {
			prepend_args = { "-i", "2" }, -- 缩进 2 空格
		},
		["tex-fmt"] = {
			-- 使用 vim.fn.stdpath("config") 获取 nvim 配置目录路径
			-- 最终拼接成：--config /home/user/.config/nvim/tex-fmt.toml
			prepend_args = { "--config", vim.fn.stdpath("config") .. "/tool-configs/tex-fmt.toml" },

			-- 在我的pr合并前先使用我自己编译的版本
			command = vim.fn.stdpath("config") .. "/bundle/tex-fmt/target/release/tex-fmt",
		},
		["cbfmt"] = {
			prepend_args = { "--config", vim.fn.stdpath("config") .. "/tool-configs/cbfmt.toml" },
		},
		["black"] = {
			prepend_args = { "--config", vim.fn.stdpath("config") .. "/tool-configs/black.toml" },
		},
		["fourmolu"] = {
			prepend_args = { "--column-limit", "100" },
		},
	},
	formatters_by_ft = {
		lua = { "stylua" },
		-- Conform can also run multiple formatters sequentially
		python = { "black" },
		--
		-- You can use 'stop_after_first' to run the first available formatter from the list
		-- javascript = { "prettierd", "prettier", stop_after_first = true },
		javascript = { "clang-format" },
		typescript = { "prettier" },
		javascriptreact = { "prettier" },
		typescriptreact = { "prettier" },
		css = { "prettier" },
		html = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },
		graphql = { "prettier" },

		-- C / C++ / C# -> Clang-format
		c = { "clang-format" },
		cpp = { "clang-format" },
		cs = { "clang-format" },
		fortran = { "fprettify" },
		matlab = { "mh_style" }, -- miss_hit

		-- Go -> 先整理 import，再进行严格格式化
		go = { "goimports", "gofumpt" },

		-- Haskell
		haskell = { "fourmolu" },

		-- Shell / Bash
		sh = { "shfmt" },
		bash = { "shfmt" },

		-- LaTeX 相关
		tex = { "tex-fmt" },
		bib = { "bibtex-tidy" },

		-- Typst
		typst = { "prettypst" },

		-- Markdown (组合拳)
		-- 1. 先用 prettier 整理 Markdown 文本结构
		-- 2. 再用 cbfmt 整理 Markdown 内部的代码块
		-- (注意：markdownlint 是 linter，不放在这里)
		markdown = { "prettier", "cbfmt" },

		-- 对所有未指定的文件类型，尝试使用 LSP 格式化
		-- ["*"] = { "codespell" },
	},
})

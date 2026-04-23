-- Completion for Checkbox states & Callouts are provided.
-- You can disable this by running the following before loading markview.
vim.g.markview_blink_loaded = true

vim.pack.add({
	"https://github.com/Saecki/crates.nvim",
	"https://github.com/hat0uma/csvview.nvim",
	"https://github.com/OXY2DEV/markview.nvim",
	"https://github.com/let-def/texpresso.vim",
}, { confirm = false })

require("crates").setup()
require("csvview").setup({
	parser = { comments = { "#", "//" } },
	keymaps = {
		-- Text objects for selecting fields
		textobject_field_inner = { "if", mode = { "o", "x" } },
		textobject_field_outer = { "af", mode = { "o", "x" } },
		-- Excel-like navigation:
		-- Use <Tab> and <S-Tab> to move horizontally between fields.
		-- Use <Enter> and <S-Enter> to move vertically between rows and place the cursor at the end of the field.
		-- Note: In terminals, you may need to enable CSI-u mode to use <S-Tab> and <S-Enter>.
		jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
		jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
		jump_next_row = { "<Enter>", mode = { "n", "v" } },
		jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
	},
})
require("markview").setup({
	preview = {
		enable = true,
	},
	latex = {
		enable = false,
	},
	html = {
		enable = true,
	},
})

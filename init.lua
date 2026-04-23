-- Initialize core settings
require("core.options")
require("core.autocmds")

-- Load my modules
require("modules.auto_input_method")
require("modules.format_and_wrap")
require("modules.lazygit")
require("modules.number_enter_mode")
require("modules.quick_run")
require("modules.view_corresponding_pdf")
require("modules.colorscheme")

-- Initialize plugins via vim.pack
require("plugins.completion")
require("plugins.debug")
require("plugins.editor")
require("plugins.langspec")
require("plugins.ui")

-- keymaps depends on some plugins, thus need to be loaded at the end.
require("core.keymaps")

-- automatic plugin updates
-- vim.pack.update()

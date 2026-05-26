-- different config for different device
-- 1: x1
-- 0: X13
vim.g.current_device = vim.loop.os_gethostname() == "x1gen14" and 1 or 0

-- Initialize core settings
require("core.options")
require("core.autocmds")

-- Load my modules
require("modules.auto_input_method")
require("modules.format_and_wrap")
require("modules.number_enter_mode")
require("modules.quick_run")
require("modules.view_corresponding_pdf")
require("modules.colorscheme")

-- Initialize plugins via vim.pack
require("plugins.completion")
require("plugins.debug")
require("plugins.editor")
require("plugins.langspec")

-- keymaps depends on some plugins, thus it need to be loaded at the end.
require("core.keymaps")

-- automatic plugin updates
-- vim.pack.update()

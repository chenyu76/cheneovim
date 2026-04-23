vim.pack.add({
	"https://github.com/folke/todo-comments.nvim", -- highlight TODO/INFO/WARN comments
	"https://github.com/goolord/alpha-nvim",
}, { confirm = false })

require("todo-comments").setup()

require("alpha").setup(require("alpha.themes.dashboard").config)

local dashboard = require("alpha.themes.dashboard")
-- Set menu
dashboard.section.buttons.val = {
	-- search icon at: https://www.nerdfonts.com/cheat-sheet
	dashboard.button(".", "󰋚 .oldfiles", "<cmd>Telescope oldfiles<CR>"),
	dashboard.button("c", " Create a new file", ":ene <BAR> startinsert <CR>"),
	-- dashboard.button('.', '󰋚 Oldfiles', ':Telescope oldfiles theme=dropdown layout_config={width=0.8}<CR>'),
	-- dashboard.button('e', '󱇧 Edit some file', ':e'),
	dashboard.button("p", "󱉟 Projects", ":Telescope projects<CR>"),
	-- dashboard.button('p', '󱉟 Projects', ':Telescope projects theme=dropdown layout_config={width=0.8}<CR>'),
	dashboard.button("o", "󰩍 Open a file", ":Open<CR>"), -- 定义在vim-setting.lua中的Open函数
	-- dashboard.button('n', '󰙅 Neotree', '<cmd>Neotree filesystem<CR>'),
	-- dashboard.button('s', ' Settings', ':e $MYVIMRC | :cd %:p:h | split . | wincmd k | pwd<CR>'),
	-- dashboard.button('s', ' Settings', ':e $MYVIMRC | :cd %:p:h | pwd<CR>'),
	dashboard.button("t", " Terminal", "<cmd>terminal<CR>"),
	dashboard.button("q", " Quit", "<cmd>qa<CR>"),
}
for _, a in ipairs(dashboard.section.buttons.val) do
	-- a.opts.width = 36
	a.opts.cursor = -2
end
dashboard.section.header.val = {
	[[                     -=-                               ]],
	[[                   4"   "h                             ]],
	[[                  $      {@                            ]],
	[[                          L                            ]],
	[[                  -aF`````vF"``""Vkw-                  ]],
	[[              -sF`                   {h,               ]],
	[[           ~F`  <P``    ~--,           `Q-             ]],
	[[         ~}  ,d`            `Q=          `h            ]],
	[[        :}  /                  {@          $           ]],
	[[       .} c`       ,             {@         $          ]],
	[[       $ /        d        \      L          &         ]],
	[[       }    {    d   L      |    ]      $     {@       ]],
	[[      ]L   |     [  {       |    $     } @{@{@$        ]],
	[[      ]L     ..  [  $       |    }     [  {}$ \        ]],
	[[       [ Lg$}m>.    ``V@- --=---.L     {-} L { }       ]],
	[[         }d'  ]`@        o"`Qk= }      / | |  }        ]],
	[[         { @ ~`         |   [ `L}     /  | |  }        ]],
	[[         { `$,,"        ]@-/  , [    .   | |  L        ]],
	[[         }               "--s" ]     $   | | ]         ]],
	[[         }    |`\              {    :{-  | ` }         ]],
	[[         } \   h ]   .--       $    }`L      \         ]],
	[[         $   `@,``""`       .-<$   /  {      `-        ]],
	[[         $     .}"^mwwpy^""`}  }   }   Q      $        ]],
	[[         { L  4}      }    /   [  ] `- {@      L       ]],
	[[           L  }       L  ~"    L  {  {@ \      $       ]],
	[[          d  d        {,/      L  }   {  Q.    }       ]],
	[[          {  {                 L  }   {   {    `       ]],
}

local ls = require 'luasnip'
local s = ls.snippet
local f = ls.function_node

-- 映射表
local map = {
  -- 下标
  ['_0'] = '₀',
  ['_1'] = '₁',
  ['_2'] = '₂',
  ['_3'] = '₃',
  ['_4'] = '₄',
  ['_5'] = '₅',
  ['_6'] = '₆',
  ['_7'] = '₇',
  ['_8'] = '₈',
  ['_9'] = '₉',
  ['_+'] = '₊',
  ['_-'] = '₋',
  ['_='] = '₌',
  ['_('] = '₍',
  ['_)'] = '₎',
  ['_a'] = 'ₐ',
  ['_e'] = 'ₑ',
  ['_h'] = 'ₕ',
  ['_i'] = 'ᵢ',
  ['_j'] = 'ⱼ',
  ['_k'] = 'ₖ',
  ['_l'] = 'ₗ',
  ['_m'] = 'ₘ',
  ['_n'] = 'ₙ',
  ['_o'] = 'ₒ',
  ['_p'] = 'ₚ',
  ['_r'] = 'ᵣ',
  ['_s'] = 'ₛ',
  ['_t'] = 'ₜ',
  ['_u'] = 'ᵤ',
  ['_v'] = 'ᵥ',
  ['_x'] = 'ₓ',
  -- 上标
  ['^0'] = '⁰',
  ['^1'] = '¹',
  ['^2'] = '²',
  ['^3'] = '³',
  ['^4'] = '⁴',
  ['^5'] = '⁵',
  ['^6'] = '⁶',
  ['^7'] = '⁷',
  ['^8'] = '⁸',
  ['^9'] = '⁹',
  ['^+'] = '⁺',
  ['^-'] = '⁻',
  ['^='] = '⁼',
  ['^('] = '⁽',
  ['^)'] = '⁾',
  ['^a'] = 'ᵃ',
  ['^b'] = 'ᵇ',
  ['^c'] = 'ᶜ',
  ['^d'] = 'ᵈ',
  ['^e'] = 'ᵉ',
  ['^f'] = 'ᶠ',
  ['^g'] = 'ᵍ',
  ['^h'] = 'ʰ',
  ['^i'] = 'ⁱ',
  ['^j'] = 'ʲ',
  ['^k'] = 'ᵏ',
  ['^l'] = 'ˡ',
  ['^m'] = 'ᵐ',
  ['^n'] = 'ⁿ',
  ['^o'] = 'ᵒ',
  ['^p'] = 'ᵖ',
  ['^r'] = 'ʳ',
  ['^s'] = 'ˢ',
  ['^t'] = 'ᵗ',
  ['^u'] = 'ᵘ',
  ['^v'] = 'ᵛ',
  ['^w'] = 'ʷ',
  ['^x'] = 'ˣ',
  ['^y'] = 'ʸ',
  ['^z'] = 'ᶻ',
}

-- 核心逻辑函数
local function script_replace(_, snip)
  local prefix = snip.captures[1] -- 拿到前面的字符，比如 'a'
  local type = snip.captures[2] -- 拿到符号，比如 '_' 或 '^'
  local content = snip.captures[3] -- 拿到内容，比如 '12'

  local result = ''
  for i = 1, #content do
    local char = content:sub(i, i)
    local key = type .. char
    result = result .. (map[key] or char)
  end
  return prefix .. result
end

vim.g.math_scripts_enabled = false

local function toggle_math_scripts()
  vim.g.math_scripts_enabled = not vim.g.math_scripts_enabled
  print('Math Scripts: ' .. (vim.g.math_scripts_enabled and 'ON' or 'OFF'))
end

vim.api.nvim_create_user_command('MathScriptsToggle', toggle_math_scripts, {})

local function math_condition()
  return vim.g.math_scripts_enabled
end

ls.add_snippets('all', {
  -- 单字符：加入更严格的转义 [%+%-...]，避免解析错误
  s({
    trig = '([%a%d])([%^_])([%a%d%+%-=%(%)])',
    regTrig = true,
    wordTriggers = false,
    name = 'Math Scripts Single',
    dscr = 'Auto script for a single character',
    condition = math_condition,
  }, {
    f(script_replace),
  }),

  -- 多字符：使用 [^}]+ 强制要求括号内必须有内容，防止被 autopairs 插件触发空括号
  s({
    trig = '([%a%d])([%^_]){([^}]+)}',
    regTrig = true,
    wordTriggers = false,
    name = 'Math Scripts Multi',
    dscr = 'Math Scripts with {} for multiple characters',
    condition = math_condition,
  }, {
    f(script_replace),
  }),
}, {
  type = 'autosnippets',
})

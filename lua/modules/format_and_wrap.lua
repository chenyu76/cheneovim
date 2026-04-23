
_G.FormatSelectionAndWrap = function()
  -- 1. 获取正确的视觉选择区域
  local mode = vim.fn.visualmode()
  local _, sr, sc, _ = table.unpack(vim.fn.getpos "'<")
  local _, er, ec, _ = table.unpack(vim.fn.getpos "'>")
  sr = sr - 1
  er = er - 1

  local line_length = string.len(vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1] or '')
  if mode == 'V' or (mode == 'v' and ec == 2147483647) then
    sc = 0
    ec = line_length
  else
    sc = sc - 1
    ec = math.min(ec, line_length)
  end

  -- 2. 提取文本
  local lines = vim.api.nvim_buf_get_text(0, sr, sc, er, ec, {})
  local text = table.concat(lines, '\n')

  -- 3. 按连续两个及以上的换行符分割段落 (语义段落)
  local paragraphs = {}
  local start_idx = 1
  while true do
    local s, e = text:find('\n\n+', start_idx)
    if not s then
      table.insert(paragraphs, text:sub(start_idx))
      break
    end
    table.insert(paragraphs, text:sub(start_idx, s - 1))
    start_idx = e + 1
  end

  -- 4. 预处理每一个段落
  local filetype = vim.bo.filetype
  local is_tex = (filetype == 'tex' or filetype == 'markdown' or filetype == 'latex')

  for i, para in ipairs(paragraphs) do
    -- 将段落内所有的单个换行符替换为空格
    para = para:gsub('\n', ' ')
    -- 将多个连续空格压缩为单个空格
    para = para:gsub('%s+', ' ')

    -- 处理 CJK 字符：如果两个非 ASCII 字符之间有空格，则移除空格
    para = vim.fn.substitute(para, '\\v([^\\x00-\\xff])\\s+([^\\x00-\\xff])', '\\1\\2', 'g')

    -- 5. LaTeX 特殊规则处理
    if is_tex then
      -- === 核心修改：使用表驱动方式管理 LaTeX 命令 ===
      -- 列表中只需要写 `\` 后面的部分。支持 Lua 模式匹配语法。
      local latex_spacing_cmds = {
        '%(', -- 匹配公式环境 \( （% 是 Lua 中的转义符）
        '%a*cite%a*', -- 匹配各类引用变体 (\cite, \parencite, \citet 等)
        '%a*ref%a*', -- 匹配各类交叉引用 (\ref, \cref, \eqref 等)
        -- 如果是精确匹配的命令（不含特殊符号）： 直接写入去掉 \ 后的字符串即可。
        -- 比如想加 \footnote，就在表里加 "footnote",。
        -- 如果是精确匹配带有特殊符号的命令： 在 Lua 中，^$()%.[]*+-? 是魔法字符。
        -- 如果要匹配它们本身，要在前面加 %。比如匹配 \(，就在表里写 "%(,"。
        -- 如果是想匹配一类命令： 使用 %a*（代表 0 个或多个字母）。比如匹配
        -- \foo, \myfoo, \fooabc，就在表里写 "%a*foo%a*",。
      }

      -- 遍历表格，统一进行正则替换
      for _, cmd_pattern in ipairs(latex_spacing_cmds) do
        -- 构造模式: 匹配前面的空格 (%s+) + 反斜杠 (\\) + 命令模式
        -- 用 () 整体捕获命令部分，然后在替换时用 %1 原样放回
        local search_pattern = '%s+(\\' .. cmd_pattern .. ')'
        para = para:gsub(search_pattern, '~%1')
      end
      -- ===============================================

      -- 处理奇数个未转义的 $
      local chars = {}
      local math_open = false
      local j = 1
      while j <= #para do
        local c = para:sub(j, j)
        if c == '\\' then
          table.insert(chars, c)
          if j < #para then
            table.insert(chars, para:sub(j + 1, j + 1))
          end
          j = j + 2
        elseif c == '$' then
          if not math_open then
            local space_found = false
            while #chars > 0 and chars[#chars]:match '%s' do
              table.remove(chars)
              space_found = true
            end
            if space_found then
              table.insert(chars, '~')
            end
            math_open = true
          else
            math_open = false
          end
          table.insert(chars, c)
          j = j + 1
        else
          table.insert(chars, c)
          j = j + 1
        end
      end
      para = table.concat(chars)
    end

    paragraphs[i] = para
  end

  -- 6. 将处理好的段落重新拼接，并写回 Buffer
  local new_text = table.concat(paragraphs, '\n\n')
  local new_lines = vim.split(new_text, '\n')
  vim.api.nvim_buf_set_text(0, sr, sc, er, ec, new_lines)

  -- 7. 计算折行位置
  local cc = vim.api.nvim_get_option_value('colorcolumn', { scope = 'local' })
  local tw = vim.api.nvim_get_option_value('textwidth', { scope = 'local' })
  local wrap_col = tw > 0 and tw or 80

  if cc and cc ~= '' then
    local first_cc = vim.split(cc, ',')[1]
    if first_cc:match '^%+' or first_cc:match '^%-' then
      wrap_col = wrap_col + tonumber(first_cc)
    else
      wrap_col = tonumber(first_cc) or wrap_col
    end

    -- 在获取到第一条可视化线的位置后，减去 10
    -- 保证和我的tex格式化工具的兼容性
    wrap_col = math.max(1, wrap_col - 10)
  end

  -- 8. 配置 Vim 内置的格式化参数，并触发 `gw`
  local save_tw = vim.api.nvim_get_option_value('textwidth', { scope = 'local' })
  local save_fo = vim.api.nvim_get_option_value('formatoptions', { scope = 'local' })

  vim.api.nvim_set_option_value('textwidth', wrap_col, { scope = 'local' })
  vim.api.nvim_set_option_value('formatoptions', 'mM1', { scope = 'local' })

  local new_er = sr + #new_lines - 1
  vim.cmd(string.format('silent! normal! %dG0V%dGgw', sr + 1, new_er + 1))

  -- 9. 还原设置
  vim.api.nvim_set_option_value('textwidth', save_tw, { scope = 'local' })
  vim.api.nvim_set_option_value('formatoptions', save_fo, { scope = 'local' })
end

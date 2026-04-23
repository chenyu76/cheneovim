
function ViewCorrespondingPDF(target_file)
  -- 确定当前要处理的文件路径（绝对路径）
  local current_file = target_file or vim.fn.expand '%:p'
  -- 统一路径分隔符
  current_file = current_file:gsub('\\', '/')

  -- .cls / .bib 文件的启发式查找逻辑
  if current_file:match '%.cls$' or current_file:match '%.bib$' then
    local target_pdf = nil

    -- 策略 A: 查找最近打开的 buffer 中的 tex 文件
    local bufs = vim.api.nvim_list_bufs()
    local tex_bufs = {}
    for _, buf in ipairs(bufs) do
      if vim.api.nvim_buf_is_loaded(buf) then
        local buf_name = vim.api.nvim_buf_get_name(buf):gsub('\\', '/')
        if buf_name:match '%.tex$' then
          -- 获取 buffer 的最后使用时间
          local info = vim.fn.getbufinfo(buf)[1]
          if info then
            table.insert(tex_bufs, { name = buf_name, lastused = info.lastused })
          end
        end
      end
    end

    -- 按最后使用时间降序排序 (最近使用的排前面)
    table.sort(tex_bufs, function(a, b)
      return a.lastused > b.lastused
    end)

    for _, b in ipairs(tex_bufs) do
      local possible_pdf = b.name:gsub('%.tex$', '.pdf')
      if vim.fn.filereadable(possible_pdf) == 1 then
        target_pdf = possible_pdf
        break
      end
    end

    -- 策略 B: 如果 buffer 中没找到对应的 PDF，查找当前目录
    if not target_pdf then
      local current_dir = vim.fn.fnamemodify(current_file, ':h')
      local main_pdf = current_dir .. '/main.pdf'

      -- 启发式 1: 优先寻找 main.pdf
      if vim.fn.filereadable(main_pdf) == 1 then
        target_pdf = main_pdf
      else
        -- 启发式 2: 查找目录下所有 .tex 对应的 .pdf，选名称最短的
        local tex_files = vim.fn.glob(current_dir .. '/*.tex', false, true)
        local valid_pdfs = {}
        for _, tex in ipairs(tex_files) do
          local pdf = tex:gsub('\\', '/'):gsub('%.tex$', '.pdf')
          if vim.fn.filereadable(pdf) == 1 then
            table.insert(valid_pdfs, pdf)
          end
        end

        if #valid_pdfs > 0 then
          table.sort(valid_pdfs, function(a, b)
            local name_a = vim.fn.fnamemodify(a, ':t')
            local name_b = vim.fn.fnamemodify(b, ':t')
            return #name_a < #name_b
          end)
          target_pdf = valid_pdfs[1]
        end
      end
    end

    -- 如果通过启发式找到了对应的 PDF，递归调用本函数打开它
    if target_pdf then
      local target_tex = target_pdf:gsub('%.pdf$', '.tex')
      -- vim.notify('匹配到 .cls 对应的文件: ' .. vim.fn.fnamemodify(target_tex, ':t'), vim.log.levels.INFO, { title = 'PDF View' })
      return ViewCorrespondingPDF(target_tex)
    else
      vim.notify('Cannot open PDF for current .cls / .bib file.', vim.log.levels.WARN, { title = 'PDF View' })
      return
    end
  end

  -- 构造对应的 PDF 路径
  local pdf_file = vim.fn.fnamemodify(current_file, ':r') .. '.pdf'

  -- 2. 检查 PDF 是否存在，如果存在则直接打开
  if vim.fn.filereadable(pdf_file) == 1 then
    local cmd = {}
    if vim.g.current_device == 1 then
      cmd = { 'evince', pdf_file }
    else
      -- okular --unique 防止重复打开
      -- cmd = { 'okular', '--unique', pdf_file }
      -- https://github.com/latex-lsp/texlab/wiki/Previewing#inverse-search-1
      -- cmd = { vim.fn.stdpath 'config' .. '/bundle/evince-synctex/evince_synctex.py', pdf_file, '"texlab -i %f -l %l"' }
      cmd = { 'papers', pdf_file }
    end

    vim.system(cmd, { detach = true }, function(obj)
      if obj.code ~= 0 then
        vim.schedule(function()
          vim.notify('Cannot open PDF: ' .. obj.code, vim.log.levels.ERROR)
        end)
      end
    end)
    return
  end

  -- 如果 PDF 不存在，且是 .tex 文件，检查是否是 subfile
  if current_file:match '%.tex$' then
    local lines = {}
    -- 确保用来对比的当前活动文件路径也统一了斜杠，防止 Windows 下等式判定失效
    local active_file = vim.fn.expand('%:p'):gsub('\\', '/')
    -- 如果是当前编辑的文件，直接从 buffer 读（支持未保存的改动）；否则读磁盘
    if current_file == active_file then
      lines = vim.api.nvim_buf_get_lines(0, 0, 10, false)
    else
      if vim.fn.filereadable(current_file) == 1 then
        lines = vim.fn.readfile(current_file, '', 10)
      end
    end

    for _, line in ipairs(lines) do
      -- 提取 subfile 的主文件路径
      local main_rel_path = line:match '\\documentclass%s*%[(.-)%]%s*{subfiles?}'
      if main_rel_path then
        -- 去掉可能存在的引号
        main_rel_path = main_rel_path:gsub('"', ''):gsub("'", '')
        -- 去除首尾多余空格，防止用户写成 [ ./main.tex ] 导致路径解析失败
        main_rel_path = vim.trim(main_rel_path)
        -- 如果用户省略了 .tex 后缀 (LaTeX允许这么做)，自动为其补全
        if not main_rel_path:match '%.tex$' then
          main_rel_path = main_rel_path .. '.tex'
        end
        -- 处理相对路径转换为绝对路径
        local current_dir = vim.fn.fnamemodify(current_file, ':h')
        local main_abs_path = vim.fn.fnamemodify(current_dir .. '/' .. main_rel_path, ':p')
        -- 把解析出的绝对路径也统一化，防止出现 \ 和 / 混用导致后续 filereadable 失败
        main_abs_path = main_abs_path:gsub('\\', '/')
        -- 防止死循环并递归跳转
        if main_abs_path ~= current_file and vim.fn.filereadable(main_abs_path) == 1 then
          return ViewCorrespondingPDF(main_abs_path)
        else
          vim.notify('Cannot find main file of current subfile: ' .. main_abs_path, vim.log.levels.WARN)
          return
        end
      end
    end
  end

  -- 最终失败提示
  vim.notify('Cannot find corresponding PDF: ' .. pdf_file, vim.log.levels.WARN, { title = 'PDF View' })
end


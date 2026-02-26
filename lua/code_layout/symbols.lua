local api = vim.api

local M = {}

local function parse_symbols(symbols, level, parent_path)
  local lines = {}
  local locations = {}
  local fzf_lines = {}
  level = level or 0
  parent_path = parent_path or ""

  table.sort(symbols, function(a, b)
    local a_start = a.range and a.range.start.line or (a.location and a.location.range.start.line) or 0
    local b_start = b.range and b.range.start.line or (b.location and b.location.range.start.line) or 0
    return a_start < b_start
  end)

  for _, symbol in ipairs(symbols) do
    local kind = vim.lsp.protocol.SymbolKind[symbol.kind] or 'Other'
    local name = symbol.name
    local indent = string.rep('  ', level)
    
    local icon = '󰽽'
    if kind == 'Function' or kind == 'Method' then icon = '󰊕'
    elseif kind == 'Class' or kind == 'Struct' then icon = '󰌗'
    elseif kind == 'Interface' then icon = '󰭦'
    elseif kind == 'Variable' or kind == 'Field' then icon = '󰫧'
    elseif kind == 'Constant' then icon = '󰏿'
    end

    -- 1. Tree line (for sidebar layouts)
    local tree_line = string.format('%s%s %s', indent, icon, name)
    table.insert(lines, tree_line)
    
    -- 2. FZF line (Indented Name + Grayed Context)
    -- We include the parent path in parentheses to provide absolute context
    local fzf_display = tree_line
    if parent_path ~= "" then
        fzf_display = string.format('%s  (%s)', tree_line, parent_path)
    end
    table.insert(fzf_lines, fzf_display)
    
    local range = symbol.range or symbol.location.range
    table.insert(locations, {
      name = name,
      line = range.start.line,
      col = range.start.character,
    })

    local current_path = parent_path == "" and name or (parent_path .. " › " .. name)
    if symbol.children and #symbol.children > 0 then
      local child_lines, child_locations, child_fzf = parse_symbols(symbol.children, level + 1, current_path)
      for _, l in ipairs(child_lines) do table.insert(lines, l) end
      for _, loc in ipairs(child_locations) do table.insert(locations, loc) end
      for _, f in ipairs(child_fzf) do table.insert(fzf_lines, f) end
    end
  end

  return lines, locations, fzf_lines
end

function M.fzf_open()
  local bufnr = api.nvim_get_current_buf()
  local params = { textDocument = vim.lsp.util.make_text_document_params() }

  vim.lsp.buf_request(bufnr, 'textDocument/documentSymbol', params, function(err, result, _, _)
    if err or not result or #result == 0 then
      print('[code-layout] No symbols found')
      return
    end

    local _, locations, fzf_lines = parse_symbols(result)
    local filename = api.nvim_buf_get_name(bufnr)
    local fzf_entries = {}
    
    for i, display_text in ipairs(fzf_lines) do
      local loc = locations[i]
      -- Metadata for fzf-lua: filename:line:col:text
      table.insert(fzf_entries, string.format('%s:%d:%d:%s', filename, loc.line + 1, loc.col + 1, display_text))
    end

    require('fzf-lua').fzf_exec(fzf_entries, {
      prompt = 'Symbols> ',
      previewer = "builtin",
      winopts = {
        title = " Symbols (Tree View) ",
        height = 0.85,
        width = 0.80,
        preview = {
          layout = 'vertical',
          vertical = 'down:45%',
        }
      },
      fzf_opts = {
        ['--delimiter'] = ':',
        ['--with-nth'] = '4..',
        ['--tiebreak'] = 'begin', -- Prefer matches closer to the start of the line
      },
      actions = {
        ['default'] = require('fzf-lua').actions.file_edit,
      },
    })
  end)
end

function M.open(mode)
  if mode == 'float' then
    return M.fzf_open()
  end

  local bufnr = api.nvim_get_current_buf()
  local params = { textDocument = vim.lsp.util.make_text_document_params() }

  vim.lsp.buf_request(bufnr, 'textDocument/documentSymbol', params, function(err, result, _, _)
    if err or not result or #result == 0 then return end

    local lines, locations = parse_symbols(result)
    local cur_win = api.nvim_get_current_win()
    
    if mode == 'left' then
      vim.cmd('topleft vertical 35split')
    else
      vim.cmd('botright vertical 35split')
    end

    local swin = api.nvim_get_current_win()
    local sbuf = api.nvim_create_buf(false, true)
    api.nvim_win_set_buf(swin, sbuf)
    api.nvim_buf_set_lines(sbuf, 0, -1, false, lines)
    
    api.nvim_set_option_value('filetype', 'code-layout-symbols', { buf = sbuf })
    api.nvim_set_option_value('buftype', 'nofile', { buf = sbuf })
    api.nvim_set_option_value('bufhidden', 'wipe', { buf = sbuf })
    api.nvim_set_option_value('number', false, { win = swin })
    api.nvim_set_option_value('relativenumber', false, { win = swin })
    api.nvim_set_option_value('winfixwidth', true, { win = swin })
    api.nvim_set_option_value('cursorline', true, { win = swin })

    vim.keymap.set('n', '<CR>', function()
      local cursor = api.nvim_win_get_cursor(swin)
      local loc = locations[cursor[1]]
      if loc then
        api.nvim_win_set_cursor(cur_win, {loc.line + 1, loc.col})
        api.nvim_win_call(cur_win, function() vim.cmd('normal! zz') end)
      end
    end, { buffer = sbuf, silent = true })

    api.nvim_create_autocmd('CursorMoved', {
      buffer = sbuf,
      callback = function()
        if not api.nvim_win_is_valid(cur_win) then return end
        local loc = locations[api.nvim_win_get_cursor(swin)[1]]
        if loc then
          api.nvim_win_set_cursor(cur_win, {loc.line + 1, loc.col})
          api.nvim_win_call(cur_win, function() vim.cmd('normal! zz') end)
        end
      end
    })
    
    vim.keymap.set('n', 'q', function()
      if api.nvim_win_is_valid(swin) then api.nvim_win_close(swin, true) end
    end, { buffer = sbuf, silent = true })
  end)
end

return M

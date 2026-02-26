local api = vim.api

local M = {}

local function parse_symbols(symbols, level)
  local lines = {}
  local locations = {}
  level = level or 0

  -- Sort symbols by their range start line
  table.sort(symbols, function(a, b)
    local a_start = a.range and a.range.start.line or (a.location and a.location.range.start.line) or 0
    local b_start = b.range and b.range.start.line or (b.location and b.location.range.start.line) or 0
    return a_start < b_start
  end)

  for _, symbol in ipairs(symbols) do
    local kind = vim.lsp.protocol.SymbolKind[symbol.kind] or 'Other'
    local name = symbol.name
    local indent = string.rep('  ', level)
    
    -- Icon mapping (basic)
    local icon = '󰽽'
    if kind == 'Function' or kind == 'Method' then icon = '󰊕'
    elseif kind == 'Class' or kind == 'Struct' then icon = '󰌗'
    elseif kind == 'Interface' then icon = '󰭦'
    elseif kind == 'Variable' or kind == 'Field' then icon = '󰫧'
    elseif kind == 'Constant' then icon = '󰏿'
    end

    local line_text = string.format('%s%s %s', indent, icon, name)
    table.insert(lines, line_text)
    
    local range = symbol.range or symbol.location.range
    table.insert(locations, {
      name = name,
      line = range.start.line,
      col = range.start.character,
    })

    if symbol.children and #symbol.children > 0 then
      local child_lines, child_locations = parse_symbols(symbol.children, level + 1)
      for _, l in ipairs(child_lines) do table.insert(lines, l) end
      for _, loc in ipairs(child_locations) do table.insert(locations, loc) end
    end
  end

  return lines, locations
end

function M.open(mode)
  local bufnr = api.nvim_get_current_buf()
  local params = { textDocument = vim.lsp.util.make_text_document_params() }

  vim.lsp.buf_request(bufnr, 'textDocument/documentSymbol', params, function(err, result, _, _)
    if err or not result or #result == 0 then
      print('[code-layout] No symbols found or LSP not attached')
      return
    end

    local lines, locations = parse_symbols(result)
    local cur_win = api.nvim_get_current_win()
    local sbuf, swin

    if mode == 'float' then
      local cl = require('code_layout')
      sbuf, swin = cl.layout('float')
        :left(math.floor(vim.o.lines * 0.8), 60, nil, ' Symbols ')
        :done()
    elseif mode == 'left' then
      vim.cmd('topleft vertical 35split')
      swin = api.nvim_get_current_win()
      sbuf = api.nvim_create_buf(false, true)
      api.nvim_win_set_buf(swin, sbuf)
    else -- right (default)
      vim.cmd('botright vertical 35split')
      swin = api.nvim_get_current_win()
      sbuf = api.nvim_create_buf(false, true)
      api.nvim_win_set_buf(swin, sbuf)
    end

    api.nvim_buf_set_lines(sbuf, 0, -1, false, lines)
    
    -- Set buffer options
    api.nvim_set_option_value('filetype', 'code-layout-symbols', { buf = sbuf })
    api.nvim_set_option_value('buftype', 'nofile', { buf = sbuf })
    api.nvim_set_option_value('bufhidden', 'wipe', { buf = sbuf })
    
    -- Set window options
    api.nvim_set_option_value('number', false, { win = swin })
    api.nvim_set_option_value('relativenumber', false, { win = swin })
    api.nvim_set_option_value('winfixwidth', true, { win = swin })
    api.nvim_set_option_value('cursorline', true, { win = swin })

    -- Add mapping to jump to symbol on Enter
    vim.keymap.set('n', '<CR>', function()
      local cursor = api.nvim_win_get_cursor(swin)
      local idx = cursor[1]
      local loc = locations[idx]
      if loc then
        api.nvim_win_set_cursor(cur_win, {loc.line + 1, loc.col})
        api.nvim_win_call(cur_win, function() vim.cmd('normal! zz') end)
      end
    end, { buffer = sbuf, silent = true })

    -- Sync scroll: jump main window when cursor moves in sidebar
    api.nvim_create_autocmd('CursorMoved', {
      buffer = sbuf,
      callback = function()
        if not api.nvim_win_is_valid(cur_win) then return end
        local cursor = api.nvim_win_get_cursor(swin)
        local idx = cursor[1]
        local loc = locations[idx]
        if loc then
          api.nvim_win_set_cursor(cur_win, {loc.line + 1, loc.col})
          api.nvim_win_call(cur_win, function() vim.cmd('normal! zz') end)
        end
      end
    })
    
    -- Mapping to close with 'q'
    vim.keymap.set('n', 'q', function()
      if api.nvim_win_is_valid(swin) then api.nvim_win_close(swin, true) end
    end, { buffer = sbuf, silent = true })
  end)
end

return M

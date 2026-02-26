local cl = require('code_layout')

-- Command to open a floating window with symbols
vim.api.nvim_create_user_command('CodeLayoutFloat', function()
  require('code_layout.symbols').open('float')
end, { desc = 'Open the LSP symbol tree in a floating window' })

-- Command to open a sidebar on the left with symbols
vim.api.nvim_create_user_command('CodeLayoutLeft', function()
  require('code_layout.symbols').open('left')
end, { desc = 'Open the LSP symbol tree in a left sidebar' })

-- Command to open the LSP symbol tree on the right
vim.api.nvim_create_user_command('CodeLayoutRight', function()
  require('code_layout.symbols').open('right')
end, { desc = 'Open the LSP symbol tree in a right sidebar' })

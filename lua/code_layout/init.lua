local code_layout = {}

function code_layout.layout(args)
  local layout = require('code_layout.layout')
  return layout:new(args)
end

return code_layout

local M = {}

M.defaults = {
	floating = {
		annotate = true,
	},
}

M.options = vim.tbl_deep_extend("force", {}, M.defaults)

function M.setup(user_opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, user_opts or {})
end

return M

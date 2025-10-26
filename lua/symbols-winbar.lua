local config = {
  seperator = "  ",
}

---@return string
local function winbar()
  local path = vim.fn.expand("%")
  path = table.concat(vim.split(path, "/"), config.seperator)

  return path
end

local M = {}

function M.setup()
  vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
    group = vim.api.nvim_create_augroup("symbols-winbar.nvim", { clear = true }),
    callback = function()
      vim.wo.winbar = winbar()
    end,
  })
end

return M

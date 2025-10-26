local config = {
  seperator = "  ",
}

---@param cursor integer[]
---@param range lsp.Range
---@return boolean
local function in_range(cursor, range)
  -- Checks for the following:
  -- 1. cursor is on same line as start range and greator than or equal start character
  -- 2. cursor is in between start and end lines
  -- 3. cursor is not on same line as start range and on same line as end range and less than or equal end character
  return (cursor[1] == range.start.line and cursor[2] >= range.start.character)
    or (cursor[1] > range.start.line and cursor[1] < range["end"].line)
    or (
      range.start.line ~= range["end"].line
      and cursor[1] == range["end"].line
      and cursor[2] <= range["end"].character
    )
end

---@param root lsp.DocumentSymbol[]
---@param cursor integer[]
---@return lsp.DocumentSymbol?
local function search_symbol(root, cursor)
  ---Sort symbols in reverse order
  ---@param a lsp.DocumentSymbol
  ---@param b lsp.DocumentSymbol
  table.sort(root, function(a, b)
    return a.range.start.line > b.range.start.line
      or (
        a.range.start.line == b.range.start.line
        and a.range["end"].character > b.range["end"].character
      )
  end)

  for _, node in ipairs(root) do
    if in_range(cursor, node.range) then
      if node.children then
        local result = search_symbol(node.children, cursor)
        if result then
          return result
        else
          return node
        end
      else
        return node
      end
    end
  end

  return nil
end

local function update()
  local path = vim.fn.expand("%")
  path = table.concat(vim.split(path, "/"), config.seperator)

  local text_document = vim.lsp.util.make_text_document_params(0)
  local method = "textDocument/documentSymbol"
  local client = vim.lsp.get_clients({ bufnr = 0, method = method })[1]

  if client then
    client:request(method, { textDocument = text_document }, function(err, symbols)
      if err then
        vim.wo.winbar = path
        return
      end

      --`nvim_win_get_cursor` cursor is (1, 0)-indexed, lsp cursor is (0, 0)-indexed
      local cursor = vim.api.nvim_win_get_cursor(0)
      cursor[1] = cursor[1] - 1

      local symbol = search_symbol(symbols, cursor)
      if symbol then
        vim.wo.winbar = path .. config.seperator .. symbol.name
      else
        vim.wo.winbar = path
      end
    end)
  else
    vim.wo.winbar = path
  end
end

local M = {}

function M.setup()
  vim.api.nvim_create_autocmd({ "BufWinEnter", "CursorHold" }, {
    group = vim.api.nvim_create_augroup("symbols-winbar.nvim", { clear = true }),
    callback = function()
      update()
    end,
  })
end

return M

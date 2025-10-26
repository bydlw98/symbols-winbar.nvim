local config = {
  kind_icons = {
    File = " ",
    Module = " ",
    Namespace = " ",
    Package = " ",
    Class = " ",
    Method = " ",
    Property = " ",
    Field = " ",
    Constructor = " ",
    Enum = " ",
    Interface = " ",
    Function = " ",
    Variable = " ",
    Constant = " ",
    String = " ",
    Number = " ",
    Boolean = " ",
    Array = " ",
    Object = " ",
    Key = " ",
    Null = " ",
    EnumMember = " ",
    Struct = " ",
    Event = " ",
    Operator = " ",
    TypeParameter = " ",
  },
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
---@param symbols_list string[]
---@return boolean
local function search_symbol(root, cursor, symbols_list)
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
      local kind = vim.lsp.protocol.SymbolKind[node.kind]
      local symbol = config.kind_icons[kind] .. node.name
      table.insert(symbols_list, symbol)

      if node.children then
        return search_symbol(node.children, cursor, symbols_list)
      else
        return true
      end
    end
  end

  return false
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

      ---@type string[]
      local symbols_list = {}
      search_symbol(symbols, cursor, symbols_list)

      if #symbols_list > 0 then
        vim.wo.winbar = path .. config.seperator .. table.concat(symbols_list, config.seperator)
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

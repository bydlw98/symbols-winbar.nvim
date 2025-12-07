---@class symbols-winbar.Config
local config = {
  ---Checks if we should update the winbar of current window.
  ---@type fun():boolean
  activate = function()
    return vim.bo.buftype == ""
  end,

  ---Icons for different `vim.lsp.protocol.SymbolKind`.
  ---@type table<string, string>
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

  ---Winbar content seperator.
  ---@type string
  seperator = "  ",
}

---Returns a winbar formatted `text` highlighted with `hlgroup`.
---@param hlgroup string
---@param text string
---@return string
local function winbar_hl(hlgroup, text)
  return "%#" .. hlgroup .. "#" .. text .. "%*"
end

---Returns a winbar formatted string containing the current path.
---@return string
local function path_section()
  local path = vim.fn.expand("%")
  if path == "" then
    return "[No Name]"
  end

  local components = vim.split(path, "/")
  local filename = components[#components]
  local extension = filename:match("[^%.]*$") or ""

  local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
  if devicons_ok then
    local icon, icon_hl = devicons.get_icon(filename, extension, { default = true })
    components[#components] = winbar_hl(icon_hl, icon) .. " " .. filename
  end

  --If `path` starts with `/` e.g. "/etc/passwd", `components[1]` will be an empty string.
  --Thus the concatenated winbar path section will be ` > etc > passwd`.
  --Instead what we want is `/etc > passwd`.
  if components[1] == "" then
    table.remove(components, 1)
    components[1] = "/" .. components[1]
  end

  return table.concat(components, config.seperator)
end

---Checks whether (0, 0)-indexed `cursor` is within `range`.
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

---Recursively search for symbol under `cursor` and update `symbols_list` with the symbols's hierarchy.
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
      local symbol = winbar_hl("SymbolsWinbar" .. kind, config.kind_icons[kind]) .. node.name
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

---Updates the winbar of current window.
local function update()
  if not config.activate() then
    return
  end

  local text_document = vim.lsp.util.make_text_document_params(0)
  local method = "textDocument/documentSymbol"
  local client = vim.lsp.get_clients({ bufnr = 0, method = method })[1]

  if client then
    client:request(method, { textDocument = text_document }, function(err, symbols)
      if err then
        vim.wo.winbar = path_section()
        return
      end

      --`nvim_win_get_cursor` cursor is (1, 0)-indexed, lsp cursor is (0, 0)-indexed
      local cursor = vim.api.nvim_win_get_cursor(0)
      cursor[1] = cursor[1] - 1

      ---@type string[]
      local symbols_list = {}
      search_symbol(symbols, cursor, symbols_list)

      if #symbols_list > 0 then
        vim.wo.winbar = path_section()
          .. config.seperator
          .. table.concat(symbols_list, config.seperator)
      else
        vim.wo.winbar = path_section()
      end
    end)
  else
    vim.wo.winbar = path_section()
  end
end

---@class symbols-winbar
local M = {}

---@param opts? symbols-winbar.Config
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  ---@type table<string, vim.api.keyset.highlight>
  local hlgroups = {
    SymbolsWinbarFile = { link = "Structure" },
    SymbolsWinbarModule = { link = "@module" },
    SymbolsWinbarNamespace = { link = "@lsp.type.namespace" },
    SymbolsWinbarPackage = { link = "Structure" },
    SymbolsWinbarClass = { link = "@lsp.type.class" },
    SymbolsWinbarMethod = { link = "@lsp.type.method" },
    SymbolsWinbarProperty = { link = "@lsp.type.property" },
    SymbolsWinbarField = { link = "@lsp.type.field" },
    SymbolsWinbarConstructor = { link = "@lsp.type.constructor" },
    SymbolsWinbarEnum = { link = "@lsp.type.enum" },
    SymbolsWinbarInterface = { link = "@lsp.type.interface" },
    SymbolsWinbarFunction = { link = "@lsp.type.function" },
    SymbolsWinbarVariable = { link = "@lsp.type.variable" },
    SymbolsWinbarConstant = { link = "@constant" },
    SymbolsWinbarString = { link = "@lsp.type.string" },
    SymbolsWinbarNumber = { link = "@lsp.type.number" },
    SymbolsWinbarBoolean = { link = "Boolean" },
    SymbolsWinbarArray = { link = "@lsp.type.operator" },
    SymbolsWinbarObject = { link = "Structure" },
    SymbolsWinbarKey = { link = "Identifier" },
    SymbolsWinbarNull = { link = "Special" },
    SymbolsWinbarEnumMember = { link = "@lsp.type.enumMember" },
    SymbolsWinbarStruct = { link = "@lsp.type.struct" },
    SymbolsWinbarEvent = { link = "@lsp.type.event" },
    SymbolsWinbarOperator = { link = "@lsp.type.operator" },
    SymbolsWinbarTypeParameter = { link = "@lsp.type.typeParameter" },
  }

  for name, val in pairs(hlgroups) do
    val.default = true
    vim.api.nvim_set_hl(0, name, val)
  end

  vim.api.nvim_create_autocmd({ "BufWinEnter", "CursorHold" }, {
    group = vim.api.nvim_create_augroup("symbols-winbar.nvim", { clear = true }),
    callback = function()
      update()
    end,
  })
end

return M

-- vim:ts=2:sts=2:sw=2:et:

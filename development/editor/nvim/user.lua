local M = {}
local files = vim.fn.glob(vim.fn.stdpath("config") .. "/lua/custom/*.lua", false, true)
for _, file in ipairs(files) do
  local mod = file:match("lua/(.-)%.lua$")
  if mod then
    local spec = require(mod:gsub("/", "."))
    if type(spec) == "table" then
      if vim.tbl_islist(spec) then
        vim.list_extend(M, spec)
      else
        table.insert(M, spec)
      end
    end
  end
end
return M
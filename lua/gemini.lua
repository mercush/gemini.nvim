local config = require('gemini.config')
print("in gemini github")
local M = {}

local function is_nvim_version_ge(major, minor, patch)
  local v = vim.version()
  if v.major > major then
    return true
  elseif v.major == major then
    if v.minor > 9 then
      return true
    elseif v.minor == minor and v.patch >= patch then
      return true
    end
  end
  return false
end

M.setup = function(opts)
  print("gemini.setup()")
  if not vim.fn.executable('curl') then
    vim.notify('curl is not found', vim.log.levels.WARN)
    return
  end

  if not is_nvim_version_ge(0, 9, 1) then
    vim.notify('neovim version too old', vim.log.levels.WARN)
    return
  end

  print("setting config")
  config.set_config(opts)

  print("requiring gemini.completion")
  require('gemini.completion').setup()
  print("gemini.setup() finished")
end

return M

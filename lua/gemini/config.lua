local api = require('gemini.api')
local util = require('gemini.util')

local M = {}

local default_model_config = {
  model_id = api.MODELS.GEMINI_2_0_FLASH,
  temperature = 0.1,
  top_k = 128,
  response_mime_type = 'text/plain',
}

local default_completion_config = {
  enabled = true,
  blacklist_filetypes = { 'help', 'qf', 'json', 'yaml', 'toml', 'xml' },
  blacklist_filenames = { '.env' },
  completion_delay = 1000,
  insert_result_key = '<S-Tab>',
  regenerate_key = '<S-Enter>',
  move_cursor_end = true,
  can_complete = function()
    return vim.fn.pumvisible() ~= 1
  end,
  get_system_text = function()
    return "You are a coding AI assistant that autocomplete user's code."
      .. "\n* Your task is to provide code suggestion at the cursor location marked by <cursor></cursor>."
      .. '\n* Your response does not need to contain explanation.'
      .. '\n* Index highly on comments, some of which give instructions on tasks that you should complete.'
      .. '\n* Always output your code in a Markdown code environment, making sure to begin and end code suggestions with backticks (```).'
      .. '\n* Do not add any other contents different from code'
  end,
  get_prompt = function(bufnr, pos)
    local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
    local prompt = 'Below is the content of a %s file `%s`:\n'
        .. '```%s\n%s\n```\n\n'
        .. 'Suggest the most likely code at <cursor></cursor>.\n'
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local line = pos[1]
    local col = pos[2]
    local target_line = lines[line]
    if target_line then
      lines[line] = target_line:sub(1, col) .. '<cursor></cursor>' .. target_line:sub(col + 1)
    else
      return nil
    end
    local code = vim.fn.join(lines, '\n')
    local abs_path = vim.api.nvim_buf_get_name(bufnr)
    local filename = vim.fn.fnamemodify(abs_path, ':.')
    prompt = string.format(prompt, filetype, filename, filetype, code)
    return prompt
  end
}

M.set_config = function(opts)
  opts = opts or {}

  M.config = {
    model = vim.tbl_deep_extend('force', {}, default_model_config, opts.model_config or {}),
    completion = vim.tbl_deep_extend('force', {}, default_completion_config, opts.completion or {}),
  }

end

M.get_config = function(keys)
  return util.table_get(M.config, keys)
end

M.get_gemini_generation_config = function()
  return {
    temperature = M.get_config({ 'model', 'temperature' }) or default_model_config.temperature,
    topK = M.get_config({ 'model', 'top_k' }) or default_model_config.top_k,
    response_mime_type = M.get_config({ 'model', 'response_mime_type' }) or 'text/plain',
  }
end

return M

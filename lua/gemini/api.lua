local uv = vim.loop or vim.uv

local M = {}

local API = "https://openrouter.ai/api/v1";

M.MODELS = {
  GEMINI_2_5_FLASH = 'google/gemini-2.5-flash',
  GEMINI_2_5_FLASH_PREVIEW = 'google/gemini-2.5-flash-preview-04-17',
  GEMINI_2_5_PRO_PREVIEW = 'google/gemini-2.5-pro-preview-03-25',
  GEMINI_2_0_FLASH_LITE = 'google/gemini-2.0-flash-lite',
  GEMINI_2_0_FLASH_EXP = 'google/gemini-2.0-flash-exp',
  GEMINI_2_0_FLASH_THINKING_EXP = 'google/gemini-2.0-flash-thinking-exp-1219',
  GEMINI_1_5_PRO = 'google/gemini-1.5-pro',
  GEMINI_1_5_FLASH = 'google/gemini-1.5-flash',
  GEMINI_1_5_FLASH_8B = 'google/gemini-1.5-flash-8b',
}

M.gemini_generate_content = function(user_text, system_text, model_name, generation_config, callback)
  local api_key = os.getenv("OPENROUTER_API_KEY")
  if not api_key then
    print("ERROR: OPENROUTER_API_KEY not found")
    return ''
  end

  local api = API .. "/chat/completions"

  -- OpenRouter uses OpenAI-style messages format
  local messages = {}
  if system_text then
    table.insert(messages, {
      role = 'system',
      content = system_text
    })
  end
  table.insert(messages, {
    role = 'user',
    content = user_text
  })

  local data = {
    model = model_name,
    messages = messages,
  }

  -- Map generation_config to OpenRouter parameters
  if generation_config then
    if generation_config.temperature then
      data.temperature = generation_config.temperature
    end
    if generation_config.maxOutputTokens then
      data.max_tokens = generation_config.maxOutputTokens
    end
    if generation_config.topP then
      data.top_p = generation_config.topP
    end
  end

  local json_text = vim.json.encode(data)

  local cmd = {
    'curl', '-X', 'POST', api,
    '-H', 'Content-Type: application/json',
    '-H', 'Authorization: Bearer ' .. api_key,
    '--data-binary', '@-'
  }
  local opts = { stdin = json_text }

  if callback then
    return vim.system(cmd, opts, callback)
  else
    return vim.system(cmd, opts)
  end
end

M.gemini_regenerate_content = function(user_text, assistant_text, system_text, model_name, generation_config, callback)
  local api_key = os.getenv("OPENROUTER_API_KEY")
  if not api_key then
    print("ERROR: OPENROUTER_API_KEY not found")
    return ''
  end

  local api = API .. "/chat/completions"

  -- OpenRouter uses OpenAI-style messages format
  local messages = {}
  if system_text then
    table.insert(messages, {
      role = 'system',
      content = system_text
    })
  end
  table.insert(messages, {
    role = 'user',
    content = user_text
  })
  table.insert(messages, {
    role = 'assistant',
    content = assistant_text
  })
  table.insert(messages, {
    role = 'user',
    content = 'That wasn\'t quite right. Try again.'
  })

  local data = {
    model = model_name,
    messages = messages,
  }

  -- Map generation_config to OpenRouter parameters
  if generation_config then
    if generation_config.temperature then
      data.temperature = generation_config.temperature
    end
    if generation_config.maxOutputTokens then
      data.max_tokens = generation_config.maxOutputTokens
    end
    if generation_config.topP then
      data.top_p = generation_config.topP
    end
  end

  local json_text = vim.json.encode(data)

  local cmd = {
    'curl', '-X', 'POST', api,
    '-H', 'Content-Type: application/json',
    '-H', 'Authorization: Bearer ' .. api_key,
    '--data-binary', '@-'
  }
  local opts = { stdin = json_text }

  if callback then
    return vim.system(cmd, opts, callback)
  else
    return vim.system(cmd, opts)
  end
end
M.gemini_generate_content_stream = function(user_text, model_name, generation_config, callback)
  local api_key = os.getenv("OPENROUTER_API_KEY")
  if not api_key then
    print("ERROR: OPENROUTER_API_KEY not found")
    return
  end

  if not callback then
    print("ERROR: No callback provided for streaming")
    return
  end

  local api = API .. "/chat/completions"

  local messages = {
    {
      role = 'user',
      content = user_text
    }
  }

  local data = {
    model = model_name,
    messages = messages,
    stream = true,
  }

  -- Map generation_config to OpenRouter parameters
  if generation_config then
    if generation_config.temperature then
      data.temperature = generation_config.temperature
    end
    if generation_config.maxOutputTokens then
      data.max_tokens = generation_config.maxOutputTokens
    end
    if generation_config.topP then
      data.top_p = generation_config.topP
    end
  end

  local json_text = vim.json.encode(data)

  local stdin = uv.new_pipe()
  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()
  local options = {
    stdio = { stdin, stdout, stderr },
    args = {
      api, '-X', 'POST', '-s',
      '-H', 'Content-Type: application/json',
      '-H', 'Authorization: Bearer ' .. api_key,
      '-d', json_text
    }
  }

  uv.spawn('curl', options, function(code, _)
  end)

  local streamed_data = ''
  uv.read_start(stdout, function(err, data)
    if err then
      print("ERROR: Stream read error: " .. tostring(err))
      return
    end

    if not err and data then
      streamed_data = streamed_data .. data

      local start_index = string.find(streamed_data, 'data:')
      local end_index = string.find(streamed_data, '\r')
      local json_text = ''
      while start_index and end_index do
        if end_index >= start_index then
          json_text = string.sub(streamed_data, start_index + 5, end_index - 1)
          callback(json_text)
        end
        streamed_data = string.sub(streamed_data, end_index + 1)
        start_index = string.find(streamed_data, 'data:')
        end_index = string.find(streamed_data, '\r')
      end
    end
  end)
end

return M

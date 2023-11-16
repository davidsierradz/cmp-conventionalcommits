local source = {}

function source.new()
  local commitlintConfigRaw = io.popen(
        [[node --eval 'eval("var obj ="+process.argv[1]);console.log(JSON.stringify(obj));' "$(npx commitlint --print-config --no-color | tr '\n' ' ')" 2>/dev/null]])
      :read(
        "*a")

  -- TODO: using commitling config file
  local commitlintConfig = vim.fn.json_decode(commitlintConfigRaw)
  local commitlintTypes = ((commitlintConfig or {})['rules'] or {})['type-enum']
  source.types = {}
  for _, type in ipairs(commitlintTypes[3]) do
    source.types[type] = { label = type, kind = require('cmp').lsp.CompletionItemKind.Keyword }
  end

  source.scopes = {}
  local commitlintScopes = ((commitlintConfig or {})['rules'] or {})['scope-enum']
  for _, scope in ipairs(commitlintScopes[3]) do
    source.scopes[scope] = { label = scope, kind = require('cmp').lsp.CompletionItemKind.Keyword }
  end

  local commitlintQuestionsEnum = ((((commitlintConfig or {})['prompt'] or {})['questions'] or {})['type'] or {})
      ['enum'] or {}

  for type, props in pairs(commitlintQuestionsEnum) do
    local typeTitle = props.title or ''
    local typeDesc = props.description or ''
    local sep = ''
    if typeTitle ~= '' and typeDesc ~= '' then
      sep = ': '
    end
    if source.types[type] ~= nil then
      source.types[type]['documentation'] = typeTitle .. sep .. typeDesc
    end
  end


  return setmetatable({}, { __index = source })
end

function source:is_available() return vim.bo.filetype == "gitcommit" end

function source:get_keyword_pattern() return [[\w\+]] end

local function candidates(entries)
  local items = {}
  for _, v in pairs(entries) do
    table.insert(items, v)
  end
  return items
end

function source:complete(request, callback)
  vim.print(request)
  if request.context.option.reason == "manual" and request.context.cursor.row ==
      1 and request.context.cursor.col == 1 then
    callback({ items = candidates(self.types), isIncomplete = true })
  elseif request.context.option.reason == "auto" and request.context.cursor.row ==
      1 and request.context.cursor.col == 2 then
    callback({ items = candidates(self.types), isIncomplete = true })
  elseif string.match(request.context.cursor_before_line, '%a+%(') and request.context.cursor.row ==
      1 then
    callback({ items = candidates(self.scopes), isIncomplete = true })
  else
    callback()
  end
end

return source

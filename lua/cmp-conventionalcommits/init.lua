local source = {}

local typesDict = {}
typesDict['build'] = {
  label = 'build',
  documentation = 'Changes that affect the build system or external dependencies',
}
typesDict['chore'] = {
  label = 'chore',
  documentation = 'Other changes that dont modify src or test files',
}
typesDict['ci'] = {
  label = 'ci',
  documentation = 'Changes to our CI configuration files and scripts',
}
typesDict['docs'] = {
  label = 'docs',
  documentation = 'Documentation only changes',
}
typesDict['feat'] = {label = 'feat', documentation = 'A new feature'}
typesDict['fix'] = {label = 'fix', documentation = 'A bug fix'}
typesDict['perf'] = {
  label = 'perf',
  documentation = 'A code change that improves performance',
}
typesDict['refactor'] = {
  label = 'refactor',
  documentation = 'A code change that neither fixes a bug nor adds a feature',
}
typesDict['revert'] = {
  label = 'revert',
  documentation = 'Reverts a previous commit',
}
typesDict['style'] = {
  label = 'style',
  documentation = 'Changes that do not affect the meaning of the code',
}
typesDict['test'] = {
  label = 'test',
  documentation = 'Adding missing tests or correcting existing tests',
}

function source.new()
  local result = io.popen(
                     [[node --eval 'console.log(process.argv[1])' $(npm list --long --parseable --depth=0 @commitlint/cli | awk -F@ '{print $NF}') 2>/dev/null]]):read(
                     "*a")
  -- dump(result)
  if result == "undefined\n" then
    -- Error handling.
    source.types = {
      typesDict['build'], typesDict['chore'], typesDict['ci'],
      typesDict['docs'], typesDict['feat'], typesDict['fix'], typesDict['perf'],
      typesDict['refactor'], typesDict['revert'], typesDict['style'],
      typesDict['test'],
    }
  else
    if string.match(result, "^1[2|3]") then
      local newcommitlint = io.popen(
                                [[node --eval 'eval("var obj ="+process.argv[1]);console.log(JSON.stringify(obj?.rules?.["type-enum"]?.[2]));' "$(npx commitlint --print-config --no-color | tr '\n' ' ')" 2>/dev/null]]):read(
                                "*a")
      -- dump(newcommitlint)
      if newcommitlint ~= "" then
        -- Success handling.
        local result_decoded = vim.fn.json_decode(newcommitlint)
        local types = {}
        for _, v in ipairs(result_decoded) do
          if typesDict[v] then
            table.insert(types, typesDict[v])
          else
            table.insert(types, {label = v})
          end
        end
        source.types = types
      else
        -- Error handling.
        source.types = {
          typesDict['build'], typesDict['chore'], typesDict['ci'],
          typesDict['docs'], typesDict['feat'], typesDict['fix'],
          typesDict['perf'], typesDict['refactor'], typesDict['revert'],
          typesDict['style'], typesDict['test'],
        }
      end
    else
      local oldcommitlint = io.popen(
                                [[node --eval 'console.log(JSON.stringify(require("@commitlint/config-conventional")?.rules?.["type-enum"]?.[2]));' 2>/dev/null]]):read(
                                "*a")
      -- dump(oldcommitlint)
      if oldcommitlint ~= "" then
        -- Success handling.
        local result_decoded = vim.fn.json_decode(oldcommitlint)
        local types = {}
        for _, v in ipairs(result_decoded) do
          if typesDict[v] then
            table.insert(types, typesDict[v])
          else
            table.insert(types, {label = v})
          end
        end
        source.types = types
      else
        -- Error handling.
        source.types = {
          typesDict['build'], typesDict['chore'], typesDict['ci'],
          typesDict['docs'], typesDict['feat'], typesDict['fix'],
          typesDict['perf'], typesDict['refactor'], typesDict['revert'],
          typesDict['style'], typesDict['test'],
        }
      end
    end
  end

  local lernaresult = io.popen(
                          [[./node_modules/.bin/lerna --loglevel silent list --all --long --parseable 2>/dev/null | cut --delimiter=':' --fields=2 | cut --delimiter='/' --fields=2]]):read(
                          "*a")
  if lernaresult ~= "" then
    -- Success handling.
    local lines = {}
    for s in lernaresult:gmatch("[^\r\n]+") do table.insert(lines, s) end
    source.scopes = lines
  else
    -- Error handling.
    source.scopes = {}
  end

  return setmetatable({}, {__index = source})
end

function source:is_available() return vim.bo.filetype == "gitcommit" end

function source:get_keyword_pattern() return [[\w\+]] end

local function candidates(entries)
  local items = {}
  for k, v in ipairs(entries) do
    items[k] = {
      label = v.label,
      kind = require('cmp').lsp.CompletionItemKind.Keyword,
      documentation = v.documentation,
    }
  end
  return items
end

local function candidatesLernaScope(entries)
  local items = {}
  for k, v in ipairs(entries) do
    items[k] = {label = v, kind = require('cmp').lsp.CompletionItemKind.Folder}
  end
  return items
end

function source:complete(request, callback)
  if request.context.option.reason == "manual" and request.context.cursor.row ==
      1 and request.context.cursor.col == 1 then
    callback({items = candidates(self.types), isIncomplete = true})
  elseif request.context.option.reason == "auto" and request.context.cursor.row ==
      1 and request.context.cursor.col == 2 then
    callback({items = candidates(self.types), isIncomplete = true})
  elseif request.context.cursor_after_line == ")" and request.context.cursor.row ==
      1 then
    callback({items = candidatesLernaScope(self.scopes), isIncomplete = true})
  else
    callback()
  end
end

return source

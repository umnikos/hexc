
local function isImported()
  -- https://stackoverflow.com/questions/49375638/how-to-determine-whether-my-code-is-running-in-a-lua-module
  return pcall(debug.getlocal, 4, 1)
end

local function is_numeric(s)
  return string.find(s,"^[%d%.]+$")
end

table.append = function(a,b)
  for _,i in pairs(b) do
    table.insert(a,i)
  end
end

local function len(x)
  local res = 0
  for _,_ in pairs(x) do
    res = res + 1
  end
  return res
end

local symbol_registry = textutils.unserializeJSON(fs.open("symbols.json","r").readAll())
local symbol_overrides_file = fs.open("symbol-overrides.json","r")
local symbol_overrides = {}
if symbol_overrides_file then
  symbol_overrides = textutils.unserializeJSON(symbol_overrides_file.readAll())
end

local symbols = {}
for _,s in pairs(symbol_registry) do
  if not s.perworld then
    -- direction: start dir
    -- pattern: angles to turn
    symbols[s.name] = s
  end
end
for _,s in pairs(symbol_overrides) do
  if not s.perworld then
    symbols[s.name] = s
  end
end

local function tokenizer(program)
  return function()
    local definition, rest = string.match(program,"^%s*(:%s.-%s;)%s(.*)")
    if definition then
      program = rest
      return definition, "definition"
    end
    local word, rest = string.match(program, "^%s*(%S+)(.*)")
    if word then
      program = rest
      return word, "word"
    end
  end
end

-- takes string
-- returns internal representation of the program
-- that needs to be translated to either ducky or hextweaks format
local function compile(program)
  local res = {}

  local dictionary = {}
  local tokens = tokenizer(program)
  for token, type in tokens do
    if type == "definition" then
      local name, body = string.match(token, "^:%s(%S+)%s*(.-)%s;$")
      local compiled = compile(body)
      dictionary[name] = compiled
    elseif type == "word" then
      if token == "{" then
        table.insert(res, {
          literal = false,
          type = "{",
        })
      elseif token == "}" then
        local quotation = {}
        while res[#res].type ~= "{" do
          table.insert(quotation, 1, res[#res])
          res[#res] = nil
        end
        res[#res] = nil
        table.insert(res, {
          literal = true,
          type = "code",
          value = quotation
        })
      elseif dictionary[token] then
        table.append(res,dictionary[token])
      elseif symbols[token] then
        table.insert(res, {
          literal = false,
          type = "symbol",
          name = token,
          pattern = symbols[token].pattern,
          direction = symbols[token].direction
        })
      elseif is_numeric(token) then
        table.insert(res, {
          literal = true,
          type = "number",
          value = tonumber(token)
        })
      else
        error("unknown word: "..token)
      end
    else
      error("unknown token type: "..type)
    end
  end

  return res
end

if isImported() then
  return compile
else
  local args = {...}
  error("TODO")
end



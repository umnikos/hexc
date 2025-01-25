
local function isImported()
  -- https://stackoverflow.com/questions/49375638/how-to-determine-whether-my-code-is-running-in-a-lua-module
  return pcall(debug.getlocal, 4, 1)
end

local function is_numeric(s)
  return string.find(s,"^[%d%.]+$")
end

table.append = function(a,b)
  for _,i in ipairs(b) do
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
  -- direction: start dir
  -- pattern: angles to turn
  symbols[s.name] = s
  if s.perworld then
    -- TODO: cause an error when translating not when compiling
    s.direction = nil
    s.pattern = nil
  end
end
for _,s in pairs(symbol_overrides) do
  symbols[s.name] = s
end

local function tokenizer(program)
  local next = function()
    local definition, rest = string.match(program,"^%s*(:%s.-%s;)%s(.*)")
    if definition then
      program = rest
      return definition, "definition"
    end
    local literal, rest = string.match(program, '^%s*"([^"]*)"(.*)')
    if literal then
      program = rest
      return literal, "string_literal"
    end
    local word, rest = string.match(program, "^%s*(%S+)(.*)")
    if word then
      program = rest
      return word, "word"
    end
  end

  local prepend = function(other_program)
    program = other_program .. " " .. program
  end

  local exports = {
    next = next,
    prepend = prepend
  }
  setmetatable(exports, {
    _G=_G,
    __call=function(self,args) return self.next(args) end
  })
  return exports
end

-- takes string
-- returns internal representation of the program
-- that needs to be translated to either ducky or hextweaks format
local function compile(program, global_dictionary)
  local res = {}

  local dictionary = {}
  for k,v in pairs(global_dictionary or {}) do
    dictionary[k]=v
  end

  local tokens = tokenizer(program)
  for token, type in tokens do
    print(token)
    if type == "definition" then
      local name, body = string.match(token, "^:%s(%S+)%s*(.-)%s;$")
      local compiled = compile(body,dictionary)
      dictionary[name] = compiled
    elseif type == "string_literal" then
      table.insert(res, {
        literal = true,
        type = "string",
        value = token
      })
    elseif type == "word" then
      if token == "loadfile!" then
        -- TODO: turn this into a macro
        local filename = res[#res].value
        res[#res] = nil
        local contents = fs.open(filename,"r").readAll()
        tokens.prepend(contents)
      elseif token == "{" then
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
        error("unknown word: '"..token.."'")
      end
    else
      error("unknown token type: "..type)
    end
  end

  return res, dictionary
end

local function translateHexTweaks(compiled)
  local res = {
    ["iota$serde"]="hextweaks:list"
  }
  local function convert_symbol(symbol)
    if not symbol.pattern then
      error("symbol '"..symbol.name.."' has an unknown pattern")
    end
    return {
      ["iota$serde"]="hextweaks:pattern",
      angles=symbol.pattern,
      startDir=symbol.direction
    }
  end
  for _,v in pairs(compiled) do
    if v.type == "symbol" then
      table.insert(res,convert_symbol(v))
    elseif v.type == "number" then
      table.insert(res,convert_symbol(symbols["open_paren"]))
      table.insert(res,v.value)
      table.insert(res,convert_symbol(symbols["close_paren"]))
      table.insert(res,convert_symbol(symbols["splat"]))
    elseif v.type == "code" then
      table.insert(res,convert_symbol(symbols["open_paren"]))
      table.append(res,translateHexTweaks(v.value))
      table.insert(res,convert_symbol(symbols["close_paren"]))
    else
      error("unhandled type: "..v.type)
    end
  end
  return res
end

local global_dictionary = {}
local function run(program)
  local compiled, new_dictionary = compile(program,global_dictionary)
  local translated = translateHexTweaks(compiled)
  local wand = peripheral.find("wand")
  wand.pushStack(translated)
  wand.runPattern("","deaqq") -- hermes
  global_dictionary = new_dictionary
end

if isImported() then
  return {
    compile=compile,
    run=run
  }
else
  local args = {...}
  --error("TODO")
  compile('"stdlib.hexc" loadfile!')
end



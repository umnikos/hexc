
local function isImported()
  -- https://stackoverflow.com/questions/49375638/how-to-determine-whether-my-code-is-running-in-a-lua-module
  return pcall(debug.getlocal, 4, 1)
end

local function is_numeric(s)
  return string.find(s,"^[%d%.%-]+$")
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

local function deepcopy(t)
  if type(t) == "table" then
    local copy = {}
    for k,v in pairs(t) do
      copy[k]=deepcopy(v)
    end
    return copy
  else
    return t
  end
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
    s.direction = nil
    s.pattern = nil
  end
end
for _,s in pairs(symbol_overrides) do
  symbols[s.name] = s
end

local function tokenizer(program)
  program = program .. "\n"
  local next = function()
    local comment, rest = string.match(program,"^%s*(#[^\n]*)\n(.*)")
    if comment then
      program = rest
      return comment, "comment"
    end
    local definition, rest = string.match(program,"^%s*(:%s.-%s;)%s(.*)")
    if definition then
      program = rest
      return definition, "definition"
    end
    local expansion, rest = string.match(program,"^%s*(EXPAND:%s.-%s;)%s(.*)")
    if expansion then
      program = rest
      return expansion, "expansion"
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

-- make a deep copy of this to define a new dictionary
local empty_dictionary = {
  words={},
  expansions={}
}

-- this is the variable currently being used to pass data in and out of expansions
-- it needs to be outside of compile()
-- in order for the reference to persist across calls to compile()
-- FIXME: just pass data as function arguments...
local expansion_stack = {} 

-- takes string
-- returns internal representation of the program
-- that needs to be translated to either ducky or hextweaks format
local function compile(program, global_dictionary)
  local res = {}

  local dictionary = deepcopy(global_dictionary or empty_dictionary)

  local function expansion_pop()
    return table.remove(expansion_stack)
  end
  local function expansion_push(x)
    return table.insert(expansion_stack, x)
  end
  local function expansion_append(l)
    for _,x in ipairs(l) do
      expansion_push(x)
    end
  end
  local function expansion_fail()
    expansion_stack = nil
  end

  local function trigger_expansions(i)
    while true do -- for multiple rounds of expansion
      while res[i] and res[i].literal do
        i = i + 1
      end
      if not res[i] then return end
      if not res[i].type == "symbol" then return end
      local expansion = dictionary.expansions[res[i].name]
      if not expansion then return end
      local j = 0 -- literals count
      while res[i-(j+1)] and res[i-(j+1)].literal do
        j = j + 1
      end
      if j < expansion.arity then return end
      local symbol = table.remove(res,i)
      expansion_stack = {}
      for _=1,j do
        expansion_push(table.remove(res,i-j))
      end
      local expansion_stack_backup = deepcopy(expansion_stack)
      expansion.call()
      if expansion_stack then
        -- success
        while #expansion_stack > 0 do
          table.insert(res,i-j,expansion_pop())
        end

        -- prepare for another round of expansion
        i = i - j
      else
        -- failure
        expansion_stack = expansion_stack_backup
        table.insert(res,i-j,symbol)
        while #expansion_stack > 0 do
          table.insert(res,i-j,expansion_pop())
        end
        return
      end
    end
  end

  local tokens = tokenizer(program)
  for token, type in tokens do
    print(token)
    if type == "comment" then
      -- ignore it
    elseif type == "definition" then
      local name, body = string.match(token, "^:%s(%S+)%s+(.-)%s;$")
      local compiled = compile(body,dictionary)
      dictionary.words[name] = compiled
    elseif type == "expansion" then
      local arity, name, body = string.match(token, "^EXPAND:%s(%d+)%s+(%S+)%s+(.-)%s;$")
      arity = tonumber(arity)
      if not symbols[name] then
        error("cannot make an expansion for '"..name.." as there's no such symbol")
      end
      local f = load(body)
      f = setfenv(f, {
        push=expansion_push,
        append=expansion_append,
        pop=expansion_pop,
        fail=expansion_fail,
        print=print,
        error=error,
        pairs=pairs,
        ipairs=ipairs
      })
      dictionary.expansions[name] = {
        arity = arity,
        call = f
      }
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
      elseif token == "sleep!" then
        -- TODO: turn this into a macro
        local seconds = res[#res].value
        res[#res] = nil
        sleep(seconds)
      elseif token == "swizzle!" then
        -- TODO: a macro
        error("swizzle! isn't implemented yet")
      elseif token == "symbol!" then
        -- TODO: a macro
        local pattern = res[#res].value
        res[#res] = nil
        local direction = res[#res].value
        res[#res] = {
          literal = "false",
          type = "symbol",
          name = nil,
          pattern = pattern,
          direction = direction
        }
      elseif token == "[" then
        table.insert(res, {
          literal = false,
          type = "[",
        })
      elseif token == "]" then
        local quotation = {}
        while res[#res].type ~= "[" do
          table.insert(quotation, 1, res[#res])
          res[#res] = nil
        end
        res[#res] = nil
        table.insert(res, {
          literal = true,
          type = "code",
          value = quotation
        })
      -- words before symbols so that they can overwrite the symbol
      elseif dictionary.words[token] then
        local previous_end = #res
        table.append(res,dictionary.words[token])
        trigger_expansions(previous_end + 1)
      elseif symbols[token] then
        table.insert(res, {
          literal = false,
          type = "symbol",
          name = token,
          pattern = symbols[token].pattern,
          direction = symbols[token].direction
        })
        trigger_expansions(#res)
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
      if symbols[v.value] then
        table.insert(res,convert_symbol(symbols[v.value]))
      else
        table.insert(res,convert_symbol(symbols["open_paren"]))
        table.insert(res,v.value)
        table.insert(res,convert_symbol(symbols["close_paren"]))
        table.insert(res,convert_symbol(symbols["splat"]))
      end
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

local global_dictionary = deepcopy(empty_dictionary)
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



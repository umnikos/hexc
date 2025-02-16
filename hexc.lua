-- valid values: "consideration", "introretro"
local quotation_style = "introretro"



-- for debugging only
local pretty = require("cc.pretty")
local pprint = pretty.pretty_print

local function is_imported(args)
  if #args == 2 and type(package.loaded[args[1]]) == "table" and not next(package.loaded[args[1]]) then
    return true
  else
    return false
  end
end

local function is_numeric(s)
  return string.find(s,"^[%d%.%-]+$")
end

local function curry(f,x) return function (...) return f(x,...) end end

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
    -- TODO: make tokenizer faster by optimizing these regexes
    -- (get rid of '(.*)' and remember an index for where to start reading from on the next iteration)
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
  expansions={},
  debug=false
}

-- takes string
-- returns internal representation of the program
-- that needs to be translated to either ducky or hextweaks format
local function compile(program, global_dictionary, no_copy)
  local res = {}

  local dictionary = nil 
  if global_dictionary then
    if no_copy then
      dictionary = global_dictionary
    else
      dictionary = deepcopy(global_dictionary)
    end
  else
    dictionary = deepcopy(empty_dictionary)
  end

  local debug_print
  local function update_debug()
    if dictionary.debug then
      debug_print = print
    else
      debug_print = function() end
    end
  end
  update_debug()

  local function trigger_expansions(i)
    while true do -- for multiple rounds of expansion
      while res[i] and res[i].literal do
        i = i + 1
      end
      if not res[i] then return end
      if not res[i].type == "symbol" then return end
      -- search by name first
      local expansion = dictionary.expansions[res[i].name]
      -- then try searching by angle signature surrounded by quotation marks
      if res[i].pattern then
        expansion = expansion or dictionary.expansions['"'..(res[i].pattern)..'"']
      end
      if not expansion then return end
      local j = 0 -- literals count
      while res[i-(j+1)] and res[i-(j+1)].literal do
        j = j + 1
      end
      if j < expansion.arity then return end
      local symbol = table.remove(res,i)
      expansion.clear()
      for _=1,j do
        expansion.push(table.remove(res,i-j))
      end
      local expansion_stack_backup = expansion.duplicate()
      expansion.call()
      if not expansion.get_stack().fail then
        -- success
        while #expansion.get_stack() > 0 do
          table.insert(res,i-j,expansion.pop())
        end

        -- prepare for another round of expansion
        i = i - j
      else
        -- failure
        table.insert(res,i-j,symbol)
        while #expansion_stack_backup > 0 do
          table.insert(res,i-j,table.remove(expansion_stack_backup))
        end
        return
      end
    end
  end

  local tokens = tokenizer(program)
  for token, type in tokens do
    debug_print(token)
    if type == "comment" then
      -- ignore it
    elseif type == "definition" then
      local name, body = string.match(token, "^:%s(%S+)%s+(.-)%s;$")
      -- FIXME: no_copy is only fine here because you can't define inside a definition.
      -- The correct solution would be to give it
      -- a wrapped version of the dictionary that is layered.
      local compiled = compile(body,dictionary,true)
      dictionary.words[name] = compiled
    elseif type == "expansion" then
      local arity, name, body = string.match(token, "^EXPAND:%s(%d+)%s+(%S+)%s+(.-)%s;$")
      arity = tonumber(arity)
      local is_anglesig = string.match(name,'^"[^"]*"$')
      if not symbols[name] and not is_anglesig then
        error("cannot make an expansion for '"..name.."' as there's no such symbol")
      end
      local f = load(body)
      local expansion_stack = {}
      local function duplicate()
        local copy = deepcopy(expansion_stack)
        local original = expansion_stack
        expansion_stack = copy
        return original
      end
      local function get_stack()
        return expansion_stack
      end
      local function pop()
        return table.remove(expansion_stack)
      end
      local function push(x)
        return table.insert(expansion_stack, x)
      end
      local function append(l)
        for _,x in ipairs(l) do
          table.insert(expansion_stack, x)
        end
      end
      local function clear()
        for k,_ in pairs(expansion_stack) do
          expansion_stack[k] = nil
        end
      end
      local function fail()
        expansion_stack.fail = true
      end
      local expansion = {
        arity = arity,
        call = f,
        duplicate = duplicate,
        get_stack = get_stack,
        pop = pop,
        push = push,
        append = append,
        fail = fail,
        clear = clear,
      }
      setfenv(expansion.call, {
        pop = expansion.pop,
        push = expansion.push,
        append = expansion.append,
        fail = expansion.fail,
        print = debug_print,
        error = error,
        pairs = pairs,
        ipairs = ipairs,
      })
      dictionary.expansions[name] = expansion
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
      elseif token == "debug!" then
        -- TODO: a macro
        dictionary.debug = res[#res].value
        res[#res] = nil
        update_debug()
      elseif token == "swizzle!" then
        -- TODO: a macro
        error("swizzle! isn't implemented yet")
      elseif token == "symbol!" then
        -- TODO: a macro
        local pattern = res[#res].value
        res[#res] = nil
        local direction = res[#res].value
        res[#res] = {
          literal = false,
          type = "symbol",
          name = nil,
          pattern = pattern,
          direction = direction
        }
      elseif token == "readfile!" then
        -- TODO: macro
        -- reads a iota from a json file and pushes it to the stack
        -- presumed to be in a hextweaks format
        local filename = res[#res].value
        local f = fs.open(filename,"r")
        local s = f.readAll()
        f.close()
        local iota = textutils.unserializeJSON(s)
        res[#res] = {
          literal=true,
          type="hextweaks",
          value=iota
        }
      elseif token == "[" then
        table.insert(res, {
          literal = false,
          type = "paren",
          value = "[",
        })
      elseif token == "{" then
        table.insert(res, {
          literal = false,
          type = "paren",
          value = "{",
        })
      elseif token == "]" then
        local quotation = {}
        while res[#res].type ~= "paren" do
          table.insert(quotation, 1, res[#res])
          res[#res] = nil
        end
        if res[#res].value ~= "[" then
          error("mismatched parentheses: "..res[#res].value.."...]")
        end
        res[#res] = nil
        table.insert(res, {
          literal = true,
          type = "code",
          value = quotation
        })
      elseif token == "}" then
        local quotation = {}
        while res[#res].type ~= "paren" do
          if not res[#res].literal then
            error("cannot insert non-literals into list")
          end
          table.insert(quotation, 1, res[#res])
          res[#res] = nil
        end
        if res[#res].value ~= "{" then
          error("mismatched parentheses: "..res[#res].value.."...}")
        end
        res[#res] = nil
        table.insert(res, {
          literal = true,
          type = "list",
          value = quotation
        })
      elseif token == "t" or token == "f" then
        local value = false
        if token == "t" then value = true end
        table.insert(res, {
          literal = true,
          type = "bool",
          value = value
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
local function quoteValue(x)
  local out = {}
  if quotation_style == "consideration" then
    table.insert(out,convert_symbol(symbols["escape"]))
    table.insert(out,x)
  elseif quotation_style == "introretro" then
    table.insert(out,convert_symbol(symbols["open_paren"]))
    table.insert(out,x)
    table.insert(out,convert_symbol(symbols["close_paren"]))
    table.insert(out,convert_symbol(symbols["splat"]))
  else
    error("unknown quotation style: "..quotation_style)
  end
  return out
end
local function quoteList(l)
  local out = {}
  if quotation_style == "consideration" then
    table.insert(out,convert_symbol(symbols["escape"]))
    table.insert(out,l)
  elseif quotation_style == "introretro" then
    table.insert(out,convert_symbol(symbols["open_paren"]))
    table.append(out,l)
    table.insert(out,convert_symbol(symbols["close_paren"]))
  else
    error("unknown quotation style: "..quotation_style)
  end
  return out
end

local function translateHexTweaks(compiled)
  local res = {
    ["iota$serde"]="hextweaks:list"
  }
  -- for recursing through list literals
  local function translateLiteral(v)
    if v.type == "string" or v.type == "bool" or v.type == "number" then
      return v.value
    end
    if v.type == "code" then
      return translateHexTweaks(v.value)
    end
    if v.type == "list" then
      local l = {
        ["iota$serde"]="hextweaks:list"
      }
      for _,vv in ipairs(v.value) do
        table.insert(l,translateLiteral(vv))
      end
      return l
    end
    error("don't know how to literalize "..v.type)
  end
  for _,v in pairs(compiled) do
    if v.type == "symbol" then
      table.insert(res,convert_symbol(v))
    elseif v.type == "number" then
      if symbols[v.value] then
        table.insert(res,convert_symbol(symbols[v.value]))
      else
        table.append(res,quoteValue(v.value))
      end
    elseif v.type == "string" then
      table.append(res,quoteValue(v.value))
    elseif v.type == "bool" then
      if v.value then
        table.insert(res,convert_symbol(symbols["const/true"]))
      else
        table.insert(res,convert_symbol(symbols["const/false"]))
      end
    elseif v.type == "code" then
      if #(v.value) == 0 then
        -- one symbol shorter
        table.insert(res,convert_symbol(symbols["empty_list"]))
      else
        table.append(res,quoteList(translateHexTweaks(v.value)))
      end
    elseif v.type == "list" then
      if #(v.value) == 0 then
        -- one symbol shorter
        table.insert(res,convert_symbol(symbols["empty_list"]))
      else
        table.append(res,quoteList(translateLiteral(v)))
      end
    elseif v.type == "hextweaks" then
      -- life is easy
      table.append(res,quoteValue(v.value))
    else
      error("unhandled type: "..v.type)
    end
  end
  return res
end

local function translateDucky(compiled)
  local function recurse(x)
    if type(x) ~= "table" then
      return x
    end
    x["iota$serde"] = nil
    for k,v in pairs(x) do
      x[k] = recurse(v)
    end
    return x
  end
  return recurse(translateHexTweaks(compiled))
end

local function wandLock()
  while _G.wand_lock do 
    sleep(0) -- TODO: listen for an event instead
  end
  _G.wand_lock = true
end
local function wandUnlock()
  _G.wand_lock = false
end

local function runCompiled(compiled, immediately_pop)
  local translated = translateHexTweaks(compiled)
  wandLock()
  local wand = peripheral.find("wand")
  -- TODO: save old stack and put in a new one if immediately_pop is set
  wand.pushStack(translated)
  wand.runPattern("","deaqq") -- hermes
  local res = nil
  if immediately_pop then
    res = {}
    for i=1,immediately_pop do
      table.insert(res,1,wand.popStack())
    end
  end
  wandUnlock()
  return res
end

local global_dictionary = deepcopy(empty_dictionary)
local function run(program, immediately_pop)
  local compiled, new_dictionary = compile(program,global_dictionary,true)
  global_dictionary = new_dictionary
  return runCompiled(compiled, immediately_pop)
end

local args = {...}
if is_imported(args) then
  return {
    compile=compile,
    run=run,
    runCompiled=runCompiled,
    tokenizer=tokenizer,
  }
else
  --error("TODO")
  local command = args[1]
  if command == "test" then
    compile('t debug! "stdlib.hexc" loadfile!')
  elseif command == "unlock" then
    _G.wand_lock = false
  elseif command == "comp" or command == "compile" or command == "build" then
    local f = fs.open(args[2],"r")
    local program = f.readAll()
    f.close()
    local compiled = compile(program)
    local focal_port = peripheral.find("focal_port")
    local wand = peripheral.find("wand")
    if focal_port then
      focal_port.writeIota(translateDucky(compiled))
      print("written to local port")
    elseif wand then
      wand.pushStack(translateHexTweaks(compiled))
      wand.runPattern("","deeeee") -- write
      print("written to focus (or at least attempted to)")
    else
      error("could not find focal port nor wand")
    end
  end
end



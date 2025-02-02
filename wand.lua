local hexc = require("hexc")
local w = peripheral.find("wand")

local prompt = string.char(16).." "

hexc.run('"stdlib.hx" loadfile!')
hexc.run('t debug!')
local history = {}
while true do
  print(textutils.serialize(w.getStack()))
  term.write(prompt)
  local input = read(nil,history)
  table.insert(history,input)
  hexc.run(input)
end

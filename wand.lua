local hexc = require("hexc")
local w = peripheral.find("wand")

local prompt = string.char(16).." "

hexc.run('"stdlib.hx" loadfile!')
hexc.run('t debug!')
local history = {}

local function main()
  while true do
    print(textutils.serialize(w.getStack()))
    term.write(prompt)
    local input = read(nil,history)
    table.insert(history,input)
    -- attempt to parse as a shell command
    local command = string.match(input, "^(%w+)")
    if command == "cls" then -- clear screen
      shell.run("clear")
    elseif command == "clear" then -- clear stack
      hexc.run(input)
    elseif command and shell.resolveProgram(command) then -- some other command
      shell.run(input)
    else
      hexc.run(input)
    end
  end
end

while true do
  local _, err = pcall(main)
  print(err)
  if err == "Terminated" then
    return
  end
end

local hexc = require("hexc")
local f = fs.open("stdlib.hx", "r")
local stdlib_code = f.readAll()
f.close()
while true do
  local stdlib = hexc.compile(stdlib_code)
  sleep(0)
end


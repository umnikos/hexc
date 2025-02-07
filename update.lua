local files = {
  "hexc.lua",
  "symbols.json",
  "symbol-overrides.json",
  "stdlib.hx",
  "usrlib.hx",
  "wand.lua",
}

local url = "https://raw.githubusercontent.com/umnikos/hexc/refs/heads/main"

for _,f in ipairs(files) do
  shell.run("rm", f)
  shell.run("wget", url.."/"..f)
end

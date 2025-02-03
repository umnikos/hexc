-- for debugging only
local pretty = require("cc.pretty")
local pprint = pretty.pretty_print

local hexc = require("hexc")
hexc.run('"stdlib.hx" loadfile!')
function main()
-- how much your food of choice feeds in non-saturation (20 is fully fed)
local foodiness_default = 8
-- how much hp do you consider low hp (20 is full hp)
local low_health = 16
-- if on low hp, how much do you want the saturation to be
local wanted_saturation = 6
-- what slot do you keep your food in
local food_slot = 27

-- slot for instant health potions, nil if you don't have any
local pot_slot = nil
-- at what point to drink the health pots
local very_low_health = 8

local foodiness_db = {
  ["minecraft:cooked_rabbit"] = 5,
  ["minecraft:melon_slice"] = 2,
  ["minecraft:golden_carrot"] = 6,
  ["minecraft:cooked_cod"] = 5,
  ["minecraft:mushroom_stew"] = 6,
}
local m = peripheral.wrap("back")
local canvas = nil
local text = nil
if m.canvas then 
    canvas = m.canvas()
    canvas.clear()
    text = canvas.addText({x=300,y=260},"")
    text.setScale(0.5)
end
while true do
    -- inv = m.getEnder()
    local food_count = 64 -- inv.list()[food_slot].count
    local food_name = "minecraft:mushroom_stew" -- inv.list()[food_slot].name
    local foodiness = foodiness_db[food_name]
    if not foodiness then
        foodiness = foodiness_default
    end
    --local gapple = food_name == "minecraft:golden_apple"
    if text then
        text.setText(""..food_count)
        if food_count <= 16 then
            text.setColor(255,0,0)
        else
            text.setColor(255,255,0)
        end
    end
    -- player = m.getMetaOwner()
    wand = peripheral.find("wand")
    local stack = hexc.run("me get_player_hunger me get_player_saturation me health", 3)
    local hunger = stack[1] -- player.food.hunger
    local saturation = stack[2] -- player.food.saturation
    local health = stack[3] -- player.health
    local needs_saturation = health <= low_health and (saturation <= wanted_saturation) or hunger < 20
    local needs_hunger = hunger <= 20-foodiness
    if needs_saturation or needs_hunger then
        print("eating!")
        -- inv.consume(food_slot)
        hexc.run("pocket/eat")
    else
        sleep(1)
    end
end

end

while true do
    pcall(main)
    print("errored!")
    sleep(1)
end

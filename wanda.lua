-- program = [[
--     [ 0 fact -> 1 ]
--     [ ]
--     5 fact
-- ]]

local filename = arg[1]
local file = io.open(filename)
local program = file:read("*all")
io.close(file)

redex = {}

for token in string.gmatch(program, "[^%s]+") do
   table.insert(redex, token)
end

rules = {}  -- not really

function find_match(rules, redex, start_index)
    return nil  -- find first rule in rules that matches redex[start-index ... end]
end

start_index = 0
while start_index < table.getn(redex) do
    match_info = find_match(rules, redex, start_index)
    if match_info ~= nil then
        redex = redex -- match-info.rule.replace(redex)
        start_index = 0
    else
        start_index = start_index + 1
    end
end

print(table.concat(redex, " "))

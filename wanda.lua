local filename = arg[1]
local file = io.open(filename)
local program = file:read("*all")
io.close(file)

redex = {}

for token in string.gmatch(program, "[^%s]+") do
   table.insert(redex, token)
end

rules = {}  -- not really

function find_match(rules, redex, i)
    local j = i
    if redex[i] == "[" then
        while redex[j] ~= "]" and redex[j] ~= nil do
           j = j + 1
        end
        return {i, j}
    else
        return nil  -- find first rule in rules that matches redex[i ... end]
    end
end

start_index = 1
while start_index < table.getn(redex) do
    match_info = find_match(rules, redex, start_index)
    if match_info ~= nil then
        local i = match_info[1]
        local j = match_info[2]
        while i <= j do
            table.remove(redex, i)
            j = j - 1
        end
        -- TODO: insert
        -- TODO: also apply the side-effect
        start_index = 1
    else
        start_index = start_index + 1
    end
end

print(table.concat(redex, " "))

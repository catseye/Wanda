function parse_program(program)
    redex = {}
    for token in string.gmatch(program, "[^%s]+") do
       table.insert(redex, token)
    end
    return redex
end

function load_program(filename)
    local file = io.open(filename)
    local program = file:read("*all")
    io.close(file)
    return parse_program(program)
end

function is_number(atom)
    return (atom ~= nil and string.find(atom, "^[+-]?%d+$"))
end

function format_redex(redex)
    return table.concat(redex, " ")
end

function find_match(rules, redex, i)
    local j = i

    if redex[i] == "[" then
        while redex[j] ~= "]" and redex[j] ~= nil do
           j = j + 1
        end
        return {i, j, {}}
    end

    if is_number(redex[i]) and is_number(redex[i+1]) and redex[i+2] == "+" then
        local a = tonumber(redex[i])
        local b = tonumber(redex[i+1])
        local r = tostring(a + b)
        return {i, i+2, {r}}
    end

    if is_number(redex[i]) and is_number(redex[i+1]) and redex[i+2] == "*" then
        local a = tonumber(redex[i])
        local b = tonumber(redex[i+1])
        local r = tostring(a * b)
        return {i, i+2, {r}}
    end

    if is_number(redex[i]) and is_number(redex[i+1]) and redex[i+2] == "-" then
        local a = tonumber(redex[i])
        local b = tonumber(redex[i+1])
        local r = tostring(a - b)
        return {i, i+2, {r}}
    end

    if redex[i] ~= nil and redex[i+i] == "dup" then
        local x = redex[i]
        return {i, i+1, {x, x}}
    end

    if redex[i] ~= nil and redex[i+1] ~= nil and redex[i+2] == "swap" then
        local x = redex[i]
        local y = redex[i+1]
        return {i, i+2, {y, x}}
    end

    -- else find first rule in rules that matches redex[i ... end]

    return nil
end

function run_wanda(redex)
    rules = {}
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

            local replacement = match_info[3]
            for n, v in ipairs(replacement) do
                table.insert(redex, i + (n-1), v)
            end

            -- TODO: also apply the side-effect

            start_index = 1
        else
            start_index = start_index + 1
        end
    end
    return redex
end

--[[========================= main ================= ]]--

local program = load_program(arg[1])
local result = run_wanda(program)
print(format_redex(result))

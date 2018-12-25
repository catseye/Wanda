---
--- wanda.lua - Reference implementation of the Wanda programming language
--- 2019, Chris Pressey, Cat's Eye Technologies
---

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

function fmt(redex)
    return table.concat(redex, " ")
end

function find_match(rules, redex, i)
    if redex[i] == ":" then
        local j = i + 1
        local pattern = {}
        local replacement = {}
        local seen_arrow = false
        while redex[j] ~= ";" and redex[j] ~= nil do
           if redex[j] == "->" then
               seen_arrow = true
           elseif seen_arrow then
               table.insert(replacement, redex[j])
           else
               table.insert(pattern, redex[j])
           end
           j = j + 1
        end
        return {start=i, stop=j, pattern={":", "...", ";"}, replacement={}, newrule={pattern=pattern, replacement=replacement}}
    end

    if is_number(redex[i]) and is_number(redex[i+1]) then
        local a = tonumber(redex[i])
        local b = tonumber(redex[i+1])
        if redex[i+2] == "+" then
            return {start=i, stop=i+2, pattern={redex[i], redex[i+1], "+"}, replacement={tostring(a + b)}}
        end
        if redex[i+2] == "*" then
            return {start=i, stop=i+2, pattern={redex[i], redex[i+1], "*"}, replacement={tostring(a * b)}}
        end
        if redex[i+2] == "-" then
            return {start=i, stop=i+2, pattern={redex[i], redex[i+1], "-"}, replacement={tostring(a - b)}}
        end
    end

    if redex[i+1] == "dup" then
        local x = redex[i]
        return {start=i, stop=i+1, pattern={redex[i], "dup"}, replacement={x, x}}
    end

    if redex[i] ~= nil and redex[i+1] ~= nil and redex[i+2] == "swap" then
        local x = redex[i]
        local y = redex[i+1]
        return {start=i, stop=i+2, pattern={redex[i], redex[i+1], "swap"}, replacement={y, x}}
    end

    -- else find first rule in rules that matches redex[i ... end]

    for n, rule in ipairs(rules) do
        local pattern = rule.pattern
        local patlen = table.getn(pattern)
        local matched = true
        for p, patbit in ipairs(pattern) do
            if patbit ~= redex[i+(p-1)] then
                matched = false
                break
            end
        end
        if matched then
            return {start=i, stop=i+(patlen-1), pattern=pattern, replacement=rule.replacement}
        end
    end

    return nil
end

function run_wanda(redex, options)
    rules = {}
    start_index = 1
    while start_index <= table.getn(redex) do
        match_info = find_match(rules, redex, start_index)
        if match_info ~= nil then
            local i = match_info.start
            local j = match_info.stop

            while i <= j do
                table.remove(redex, i)
                j = j - 1
            end

            for n, v in ipairs(match_info.replacement) do
                table.insert(redex, i + (n-1), v)
            end

            local defn = match_info.newrule
            if defn ~= nil then
                table.insert(rules, defn)
            end

            if options.trace then
                local formatted_rule = fmt(match_info.pattern) .. " -> " .. fmt(match_info.replacement)
                print(":" .. formatted_rule .. "; => " .. fmt(redex))
            end

            start_index = 1
        else
            start_index = start_index + 1
        end
    end
    return redex
end

--[[========================= main ================= ]]--

local program = load_program(arg[1])
local options = {}
--options.trace = true
local result = run_wanda(program, options)
print(fmt(result))

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

function contains_exactly_one(tbl, val)
    local count = 0
    for i, v in ipairs(tbl) do
        if v == val then
           count = count + 1
        end
    end
    return (count == 1)
end

function find_match(rules, redex, i)
    if redex[i] == "$" and redex[i+1] == ":" then
        local j = i + 2
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

        local newrule = nil
        if contains_exactly_one(pattern, "$") and contains_exactly_one(replacement, "$") and replacement[1] == "$" then
            newrule = {pattern=pattern, replacement=replacement}
        end

        return {start=i, stop=j, pattern={"$", ":", "...", ";"}, replacement={"$"}, newrule=newrule}
    end

    if is_number(redex[i]) and is_number(redex[i+1]) and redex[i+2] == "$" then
        local a = tonumber(redex[i])
        local b = tonumber(redex[i+1])
        local op = redex[i+3]
        if op == "+" then
            return {start=i, stop=i+3, pattern={redex[i], redex[i+1], "$", "+"}, replacement={tostring(a + b), "$"}}
        end
        if op == "*" then
            return {start=i, stop=i+3, pattern={redex[i], redex[i+1], "$", "*"}, replacement={tostring(a * b), "$"}}
        end
        if op == "-" then
            return {start=i, stop=i+3, pattern={redex[i], redex[i+1], "$", "-"}, replacement={tostring(a - b), "$"}}
        end
    end

    if is_number(redex[i]) and redex[i+1] == "$" then
        local a = tonumber(redex[i])
        local op = redex[i+2]
        if op == "sgn" then
            if a > 0 then
                return {start=i, stop=i+2, pattern={redex[i], "$", "sgn"}, replacement={"1", "$"}}
            elseif a == 0 then
                return {start=i, stop=i+2, pattern={redex[i], "$", "sgn"}, replacement={"0", "$"}}
            else
                return {start=i, stop=i+2, pattern={redex[i], "$", "sgn"}, replacement={"-1", "$"}}
            end
        end
    end

    if redex[i] ~= nil and redex[i+1] == "$" and redex[i+2] == "pop" then
        return {start=i, stop=i+2, pattern={redex[i], "$", "pop"}, replacement={"$"}}
    end

    if redex[i] ~= nil and redex[i+1] == "$" and redex[i+2] == "dup" then
        local x = redex[i]
        return {start=i, stop=i+2, pattern={x, "$", "dup"}, replacement={x, x, "$"}}
    end

    if redex[i] == "$" and is_number(redex[i+1]) then
        return {start=i, stop=i+1, pattern={"$", redex[i+1]}, replacement={redex[i+1], "$"}}
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
                table.insert(rules, 1, defn)
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

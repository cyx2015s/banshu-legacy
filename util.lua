function mod(a, b)
    local _, rem = math.modf(a / b)
    return math.floor(rem * b + 0.5)
end

function code_to_utf8(codepoint)
    if codepoint < 0 or codepoint > 0x10FFFF then
        error("Invalid code point")
    end

    local utf8 = ""
    if codepoint <= 0x7F then
        utf8 = string.char(codepoint)
    elseif codepoint <= 0x7FF then
        utf8 = string.char(0xC0 + math.floor(codepoint / 64), 0x80 + (codepoint % 0x40))
    elseif codepoint <= 0xFFFF then
        utf8 = string.char(0xE0 + math.floor(codepoint / 64 / 64), 0x80 + mod(math.floor(codepoint / 64), 0x40),
            0x80 + mod(codepoint, 0x40))
    elseif codepoint <= 0x10FFFF then
        utf8 = string.char(0xF0 + math.floor(codepoint / 64 / 64 / 64), 0x80 + mod(math.floor(codepoint / 64 / 64), 0x40),
            0x80 + mod(math.floor(codepoint / 64), 0x40), 0x80 + mod(codepoint, 0x40))
    end

    return utf8
end

function utf8_str_to_code(utf8_str)
    local codes = {}
    local i = 1
    while i <= #utf8_str do
        local first_byte = utf8_str:byte(i)
        if first_byte < 0x80 then
            -- 1-byte sequence
            table.insert(codes, first_byte)
            i = i + 1
        elseif first_byte < 0xE0 then
            -- 2-byte sequence
            local second_byte = utf8_str:byte(i + 1)
            local codepoint = mod(first_byte, 0x20) * 64
            codepoint = codepoint + mod(second_byte, 0x40)
            table.insert(codes, codepoint)
            i = i + 2
        elseif first_byte < 0xF0 then
            -- 3-byte sequence
            local second_byte = utf8_str:byte(i + 1)
            local third_byte = utf8_str:byte(i + 2)
            local codepoint = mod(first_byte, 0x10) * 64 * 64
            codepoint = codepoint + mod(second_byte, 0x40) * 64
            codepoint = codepoint + mod(third_byte, 0x40)
            table.insert(codes, codepoint)
            i = i + 3
        elseif first_byte < 0xF8 then
            -- 4-byte sequence
            local second_byte = utf8_str:byte(i + 1)
            local third_byte = utf8_str:byte(i + 2)
            local fourth_byte = utf8_str:byte(i + 3)
            local codepoint = mod(first_byte, 0x08) * 64 * 64 * 64
            codepoint = codepoint + mod(second_byte, 0x40) * 64 * 64
            codepoint = codepoint + mod(third_byte, 0x40) * 64
            codepoint = codepoint + mod(fourth_byte, 0x40)
            table.insert(codes, codepoint)
            i = i + 4
        else
            error("Invalid UTF-8 byte")
        end
    end
    return codes
end

function utf8_char_to_code(utf8_str, pos)
    pos = pos or 1
    while pos <= #utf8_str do
        local first_byte = utf8_str:byte(pos)
        -- print(first_byte)
        if first_byte < 0x80 then
            return first_byte, 1
        elseif first_byte < 0xE0 then
            local second_byte = utf8_str:byte(pos + 1)
            local codepoint = mod(first_byte, 0x20) * 64
            codepoint = codepoint + mod(second_byte, 0x40)
            return codepoint, 2
        elseif first_byte < 0xF0 then
            -- 3-byte sequence
            local second_byte = utf8_str:byte(pos + 1)
            local third_byte = utf8_str:byte(pos + 2)
            local codepoint = mod(first_byte, 0x10) * 64 * 64
            codepoint = codepoint + mod(second_byte, 0x40) * 64
            codepoint = codepoint + mod(third_byte, 0x40)
            return codepoint, 3
        elseif first_byte < 0xF8 then
            -- 4-byte sequence
            local second_byte = utf8_str:byte(pos + 1)
            local third_byte = utf8_str:byte(pos + 2)
            local fourth_byte = utf8_str:byte(pos + 3)
            local codepoint = mod(first_byte, 0x08) * 64 * 64 * 64
            codepoint = codepoint + mod(second_byte, 0x40) * 64 * 64
            codepoint = codepoint + mod(third_byte, 0x40) * 64
            codepoint = codepoint + mod(fourth_byte, 0x40)
            return codepoint, 4
        else
            error("Invalid UTF-8 byte")
        end
    end
end

-- local tmp_set = require("char_set")
-- print(utf8_char_to_code("𬺓"))
-- for k, v in ipairs(tmp_set) do
--     print(utf8_char_to_code(v))
--     if (k > 200) then
--         break
--     end
-- end

-- bitser.lua - Compact binary serializer for Lua/Love2D
local bitser = {}

local function pack_int4(val)
    if string.pack then
        return string.pack("<I4", val)
    elseif love and love.data and love.data.pack then
        return love.data.pack("string", "<I4", val)
    else
        local b1 = math.floor(val % 256)
        local b2 = math.floor((val / 256) % 256)
        local b3 = math.floor((val / 65536) % 256)
        local b4 = math.floor((val / 16777216) % 256)
        return string.char(b1, b2, b3, b4)
    end
end

local function unpack_int4(str, pos)
    if string.unpack then
        return string.unpack("<I4", str, pos)
    elseif love and love.data and love.data.unpack then
        return love.data.unpack("<I4", str, pos)
    else
        local b1, b2, b3, b4 = string.byte(str, pos, pos + 3)
        local val = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
        return val, pos + 4
    end
end

local function pack_double(val)
    if string.pack then
        return string.pack("<d", val)
    elseif love and love.data and love.data.pack then
        return love.data.pack("string", "<d", val)
    else
        local s = tostring(val)
        return pack_int4(#s) .. s
    end
end

local function unpack_double(str, pos)
    if string.unpack then
        return string.unpack("<d", str, pos)
    elseif love and love.data and love.data.unpack then
        return love.data.unpack("<d", str, pos)
    else
        local len, new_pos = unpack_int4(str, pos)
        local num = tonumber(str:sub(new_pos, new_pos + len - 1))
        return num, new_pos + len
    end
end

local function serialize_value(val, buffer, visited)
    local t = type(val)
    if t == "nil" then
        table.insert(buffer, "\0")
    elseif t == "boolean" then
        table.insert(buffer, val and "\1" or "\2")
    elseif t == "number" then
        table.insert(buffer, "\3" .. pack_double(val))
    elseif t == "string" then
        table.insert(buffer, "\4" .. pack_int4(#val) .. val)
    elseif t == "table" then
        if visited[val] then
            error("Cannot serialize cyclic table in bitser")
        end
        visited[val] = true
        local count = 0
        for _ in pairs(val) do count = count + 1 end
        table.insert(buffer, "\5" .. pack_int4(count))
        for k, v in pairs(val) do
            serialize_value(k, buffer, visited)
            serialize_value(v, buffer, visited)
        end
        visited[val] = nil
    else
        error("Unsupported type for bitser: " .. t)
    end
end

function bitser.dumps(val)
    local buffer = {}
    local visited = {}
    serialize_value(val, buffer, visited)
    return table.concat(buffer)
end

local function deserialize_value(str, pos)
    local tag = str:sub(pos, pos)
    pos = pos + 1
    if tag == "\0" then
        return nil, pos
    elseif tag == "\1" then
        return true, pos
    elseif tag == "\2" then
        return false, pos
    elseif tag == "\3" then
        local num, new_pos = unpack_double(str, pos)
        return num, new_pos
    elseif tag == "\4" then
        local len, new_pos = unpack_int4(str, pos)
        local s = str:sub(new_pos, new_pos + len - 1)
        return s, new_pos + len
    elseif tag == "\5" then
        local count, new_pos = unpack_int4(str, pos)
        pos = new_pos
        local tbl = {}
        for _ = 1, count do
            local k, v
            k, pos = deserialize_value(str, pos)
            v, pos = deserialize_value(str, pos)
            tbl[k] = v
        end
        return tbl, pos
    else
        error("Malformed bitser payload at position " .. tostring(pos - 1))
    end
end

function bitser.loads(str)
    if not str or #str == 0 then return nil end
    local val, _ = deserialize_value(str, 1)
    return val
end

return bitser

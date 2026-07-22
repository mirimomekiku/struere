local constants = require("lib.constants")

local Randomizer = {}

function Randomizer.new()
    return {
        bag = {},
        all_pieces = constants.PIECE_TYPES,
    }
end

function Randomizer.next(r)
    if #r.bag == 0 then
        r.bag = {}
        for _, p in ipairs(r.all_pieces) do
            table.insert(r.bag, p)
        end
        for i = #r.bag, 2, -1 do
            local j = math.random(i)
            r.bag[i], r.bag[j] = r.bag[j], r.bag[i]
        end
    end
    return table.remove(r.bag)
end

return Randomizer

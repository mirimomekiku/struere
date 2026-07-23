-- lib/randomizer.lua
-- All 7 randomizer algorithms, selected at runtime via GameplayOpts.randomizer

local constants = require("lib.constants")

local Randomizer = {}

local PIECES = {"I", "O", "T", "S", "Z", "J", "L"}

-- ─── State constructor ────────────────────────────────────────────────────────

function Randomizer.new()
    return {
        bag      = {},              -- for 7bag / 8bag
        all_pieces = PIECES,
        last     = nil,             -- for classic / gameboy (avoid immediate repeat)
        history  = {"S","Z","S","Z","S","Z"},  -- for TGM (6-slot, per TGM3 spec)
        hist_ptr = 1,               -- ring-buffer pointer
        drought  = {},              -- for TGM2: count of consecutive non-appearances
    }
end

-- ─── 7-Bag ───────────────────────────────────────────────────────────────────
-- Standard modern Tetris: shuffle all 7 into a bag, refill when empty.
function Randomizer.next_7bag(r)
    if #r.bag == 0 then
        r.bag = {}
        for _, p in ipairs(PIECES) do table.insert(r.bag, p) end
        for i = #r.bag, 2, -1 do
            local j = math.random(i)
            r.bag[i], r.bag[j] = r.bag[j], r.bag[i]
        end
    end
    return table.remove(r.bag)
end

-- ─── Classic ─────────────────────────────────────────────────────────────────
-- Pure random, memoryless. Can drought.
function Randomizer.next_classic(r)
    return PIECES[math.random(#PIECES)]
end

-- ─── Game Boy Tetris ─────────────────────────────────────────────────────────
-- 1-slot history. Reroll once if same as last piece.
function Randomizer.next_gameboy(r)
    local pick = PIECES[math.random(#PIECES)]
    if pick == r.last then
        pick = PIECES[math.random(#PIECES)]
    end
    r.last = pick
    return pick
end

-- ─── 8-Bag ───────────────────────────────────────────────────────────────────
-- Like 7-bag but adds one random bonus piece per cycle.
function Randomizer.next_8bag(r)
    if #r.bag == 0 then
        r.bag = {}
        for _, p in ipairs(PIECES) do table.insert(r.bag, p) end
        -- Add one random extra piece
        table.insert(r.bag, PIECES[math.random(#PIECES)])
        for i = #r.bag, 2, -1 do
            local j = math.random(i)
            r.bag[i], r.bag[j] = r.bag[j], r.bag[i]
        end
    end
    return table.remove(r.bag)
end

-- ─── TGM1 ────────────────────────────────────────────────────────────────────
-- 4-slot history. Rerolls up to 4 times if piece is in history. Always accepts 4th roll.
function Randomizer.next_tgm1(r)
    if #r.history > 4 then
        -- Trim history to last 4 for TGM1
        while #r.history > 4 do table.remove(r.history, 1) end
    end

    local function in_hist(p)
        for _, h in ipairs(r.history) do if h == p then return true end end
        return false
    end

    local pick
    for attempt = 1, 4 do
        pick = PIECES[math.random(#PIECES)]
        if not in_hist(pick) or attempt == 4 then break end
    end

    -- Update history (keep last 4)
    table.insert(r.history, pick)
    if #r.history > 4 then table.remove(r.history, 1) end

    return pick
end

-- ─── TGM2 ────────────────────────────────────────────────────────────────────
-- TGM1 + drought avoidance for S and Z.
-- If either S or Z has not appeared in 5+ pieces, it gets priority.
function Randomizer.next_tgm2(r)
    -- Drought counters
    r.drought = r.drought or {}
    for _, p in ipairs(PIECES) do r.drought[p] = r.drought[p] or 0 end

    -- Check if S or Z is over-due (drought > 5)
    for _, emergency in ipairs({"S", "Z"}) do
        if (r.drought[emergency] or 0) > 5 then
            r.drought[emergency] = 0
            return emergency
        end
    end

    -- Otherwise TGM1 logic with 4-slot history (reuse TGM1 but call locally)
    if #r.history > 4 then
        while #r.history > 4 do table.remove(r.history, 1) end
    end

    local function in_hist(p)
        for _, h in ipairs(r.history) do if h == p then return true end end
        return false
    end

    local pick
    for attempt = 1, 4 do
        pick = PIECES[math.random(#PIECES)]
        if not in_hist(pick) or attempt == 4 then break end
    end

    table.insert(r.history, pick)
    if #r.history > 4 then table.remove(r.history, 1) end

    -- Update drought counters
    for _, p in ipairs(PIECES) do
        if p == pick then
            r.drought[p] = 0
        else
            r.drought[p] = (r.drought[p] or 0) + 1
        end
    end

    return pick
end

-- ─── TGM3 ────────────────────────────────────────────────────────────────────
-- 35-roll retry. 6-slot history (seeded S,Z,S,Z,S,Z per TGM3 spec).
-- Most predictable — very rarely droughts.
function Randomizer.next_tgm3(r)
    local HIST_SIZE = 6

    -- Ensure history is exactly HIST_SIZE (seeded on first call via Randomizer.new)
    while #r.history > HIST_SIZE do table.remove(r.history, 1) end
    while #r.history < HIST_SIZE do table.insert(r.history, 1, "S") end

    local function in_hist(p)
        for _, h in ipairs(r.history) do if h == p then return true end end
        return false
    end

    local pick = PIECES[math.random(#PIECES)]
    for _ = 1, 35 do
        if not in_hist(pick) then break end
        pick = PIECES[math.random(#PIECES)]
    end

    -- Update ring history
    table.insert(r.history, pick)
    if #r.history > HIST_SIZE then table.remove(r.history, 1) end

    return pick
end

-- ─── Dispatcher ──────────────────────────────────────────────────────────────

function Randomizer.next(r)
    local ok, GameplayOpts = pcall(require, "lib.gameplay_opts")
    local algo = (ok and GameplayOpts.randomizer) or "7bag"
    local fn = Randomizer["next_" .. algo]
    if fn then
        return fn(r)
    else
        return Randomizer.next_7bag(r)
    end
end

return Randomizer

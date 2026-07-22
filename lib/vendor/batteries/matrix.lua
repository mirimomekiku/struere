-- batteries.matrix
-- 2D Grid / Matrix management library for Lua/Love2D

local Matrix = {}
Matrix.__index = Matrix

function Matrix.new(width, height, default_val)
    local self = setmetatable({}, Matrix)
    self.width = width or 10
    self.height = height or 20
    self.default_val = default_val
    self.data = {}
    self:clear(default_val)
    return self
end

function Matrix:in_bounds(x, y)
    return x >= 1 and x <= self.width and y >= 1 and y <= self.height
end

function Matrix:get(x, y)
    if not self:in_bounds(x, y) then return nil end
    local row = self.data[y]
    return row and row[x] or self.default_val
end

function Matrix:set(x, y, val)
    if self:in_bounds(x, y) then
        if not self.data[y] then self.data[y] = {} end
        self.data[y][x] = val
    end
end

function Matrix:clear(val)
    val = (val ~= nil) and val or self.default_val
    self.data = {}
    for y = 1, self.height do
        self.data[y] = {}
        for x = 1, self.width do
            self.data[y][x] = val
        end
    end
end

function Matrix:fill(val)
    self:clear(val)
end

function Matrix:each(fn)
    for y = 1, self.height do
        for x = 1, self.width do
            local res = fn(x, y, self.data[y][x])
            if res ~= nil then return res end
        end
    end
end

function Matrix:copy()
    local copy = Matrix.new(self.width, self.height, self.default_val)
    for y = 1, self.height do
        for x = 1, self.width do
            copy.data[y][x] = self.data[y][x]
        end
    end
    return copy
end

return Matrix

local area = { minX = 96, maxX = 125, minY = -144, maxY = -98 }
local function gauss(n) return n * (n + 1) / 2 end
local function gauss_inv(n) return math.sqrt(2 * n + 0.25) - 0.5 end

-- The highest Y point is reached when we hit the bottom of the target area.
-- That and the gauss formula gives the high point.
print(string.format('2021-12-17 Part 1: %d', area.minY + gauss(-area.minY)))

local velCount = 0
-- The Y velocity ranges from a straight shot to the lowest point to
-- a shot that uses the highest possible arc to reach it.
for yVel = area.minY, -area.minY do
    -- The X velocity ranges from just reaching the target area (inverse gauss) to
    -- a straight shot to the outer reaches of the target area.
    for xVel = math.ceil(gauss_inv(area.minX)), area.maxX do
        local x, y, curXVel, curYVel = 0, 0, xVel, yVel
        repeat
            -- Run the shot simulation ...
            x, curXVel, y, curYVel = x + curXVel, math.max(0, curXVel - 1), y + curYVel, curYVel - 1
            if area.minX <= x and x <= area.maxX and area.minY <= y and y <= area.maxY then
                -- ... until we hit the target area ...
                velCount = velCount + 1
                goto stopSimulation;
            end
            -- ... or until we go beyond the reaches of the target area.
        until x > area.maxX or y < area.minY
        ::stopSimulation::
    end
end
print(string.format('2021-12-17 Part 2: %d', velCount))
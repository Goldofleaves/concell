Util.World = {}
function Util.World.getOppositeSide(a)
    local array = { dr = "tl", dl = "tr", tr = "dl", tl = "dr" }
    return array[a]
end
---comment
---@param V Vector
function Util.World.toIsoPos(V)
    local isoMatrix = Matrix({Macros.baseTileSize * Util.UI.getScalingFactor(), 0.5 * Macros.baseTileSize * Util.UI.getScalingFactor()}, {-1 * Macros.baseTileSize * Util.UI.getScalingFactor(), 0.5 * Macros.baseTileSize * Util.UI.getScalingFactor()})
    local offset = Vector(G.drawinfo.origin.x, G.drawinfo.origin.y):add(G.worldOffsetVector, true)
    return offset:add(isoMatrix:apply(V, true), true)
end

function Util.World.toNormalPos(V)
    local isoMatrix = Matrix({ Macros.baseTileSize * Util.UI.getScalingFactor(), 0 }, { 0, Macros.baseTileSize * Util.UI.getScalingFactor() })
    local offset = Vector(G.drawinfo.origin.x, G.drawinfo.origin.y)
    return offset:add(isoMatrix:apply(V, true), true)
end

function Util.World.getDoorAdjacentPos(D)
    if D.x == -1 then
        return {x = 0, y = D.y}
    elseif D.y == -1 then
        return { x = D.x, y = 0 }
    elseif D.x == G.flags.saveData.curRoom.size.w then
        return { x = G.flags.saveData.curRoom.size.w - 1, y = D.y }
    else
        return { x = D.x, y = G.flags.saveData.curRoom.size.h - 1 }
    end
end

function Util.World.getOppositeSideDoor(side)
    local s = Util.World.getOppositeSide(side)
    for k, v in ipairs(G.flags.saveData.curRoom.doors) do
        if v.side == s then
            return v
        end
    end
    return G.flags.saveData.curRoom.doors[1]
end

local function coordKey(x, y)
    return x .. "," .. y
end

function Util.World.isFloor(room, x, y)
    if x < 0 or y < 0 or x >= room.size.w or y >= room.size.h then
        return false
    end
    if not room.floor then
        return true
    end
    return room.floor[x] and room.floor[x][y] == true
end

local function isGrassIndex(index)
    return type(index) == "number" and index >= 6 and index <= 11
end

local function isRuinsIndex(index)
    return type(index) == "number" and index >= 12
end

local TRANSITION_ROOM_CONFIGS = {
    [5] = {
        fromArea = "prison",
        toArea = "grass",
        enemies = {"cellmate", "turret"},
    },
    [11] = {
        fromArea = "grass",
        toArea = "ruins",
        enemies = {"hunter", "skeleton"},
    },
}

local function getTransitionRoomConfig(index)
    return type(index) == "number"
        and TRANSITION_ROOM_CONFIGS[index]
        or nil
end

local TURRET_FACING_VECTORS = {
    ["1"] = {-1, 0},
    ["2"] = {0, 1},
    ["3"] = {1, 0},
    ["4"] = {0, -1},
}

local function roomBlocksSight(room, x, y)
    for _, cover in ipairs(room.covers or {}) do
        if cover.x == x and cover.y == y then
            return true
        end
    end
    for _, wall in ipairs(room.walls or {}) do
        if wall.x == x and wall.y == y then
            return true
        end
    end
    for _, gate in ipairs(room.gates or {}) do
        if gate.locked ~= false and gate.x == x and gate.y == y then
            return true
        end
    end
    return false
end

function Util.World.getGridLineCells(fromX, fromY, toX, toY)
    local cells = {}
    local x, y = fromX, fromY
    local distanceX = math.abs(toX - fromX)
    local distanceY = math.abs(toY - fromY)
    local stepX = fromX < toX and 1 or -1
    local stepY = fromY < toY and 1 or -1
    local errorValue = distanceX - distanceY
    while x ~= toX or y ~= toY do
        local doubledError = 2 * errorValue
        if doubledError > -distanceY then
            errorValue = errorValue - distanceY
            x = x + stepX
        end
        if doubledError < distanceX then
            errorValue = errorValue + distanceX
            y = y + stepY
        end
        cells[#cells + 1] = {x, y}
    end
    return cells
end

function Util.World.hasTurretSightlineFrom(
    room,
    turretX,
    turretY,
    facing,
    targetX,
    targetY
)
    if not room then
        return false
    end

    local forward = TURRET_FACING_VECTORS[tostring(facing)]
    if not forward then
        return false
    end
    if turretX == targetX and turretY == targetY then
        return false
    end
    local deltaX = targetX - turretX
    local deltaY = targetY - turretY
    if math.abs(deltaX) + math.abs(deltaY) == 1 then
        return false
    end
    local forwardDistance = deltaX * forward[1] + deltaY * forward[2]
    local lateralDistance = math.abs(
        deltaX * -forward[2] + deltaY * forward[1]
    )
    if forwardDistance <= 0 or lateralDistance > forwardDistance then
        return false
    end

    for _, cell in ipairs(Util.World.getGridLineCells(
        turretX,
        turretY,
        targetX,
        targetY
    )) do
        if roomBlocksSight(room, cell[1], cell[2]) then
            return false
        end
    end
    return true
end

function Util.World.hasTurretSightline(turret, targetX, targetY)
    if not turret or not turret.TMod or not G.flags.saveData.curRoom then
        return false
    end
    return Util.World.hasTurretSightlineFrom(
        G.flags.saveData.curRoom,
        turret.TMod.x.base,
        turret.TMod.y.base,
        turret.extra.facing,
        targetX,
        targetY
    )
end

function Util.World.hasHunterSightlineFrom(
    room,
    hunterX,
    hunterY,
    targetX,
    targetY,
    turrets,
    range
)
    local distance = math.abs(targetX - hunterX)
        + math.abs(targetY - hunterY)
    if distance == 1 or distance > (range or Macros.hunter.range) then
        return false
    end

    for _, cell in ipairs(Util.World.getGridLineCells(
        hunterX,
        hunterY,
        targetX,
        targetY
    )) do
        if roomBlocksSight(room, cell[1], cell[2]) then
            return false
        end
        for _, turret in ipairs(turrets or {}) do
            if turret[1] == cell[1] and turret[2] == cell[2] then
                return false
            end
        end
    end
    return true
end

function Util.World.hasHunterSightline(hunter, targetX, targetY)
    if not hunter or not hunter.TMod or not G.flags.saveData.curRoom then
        return false
    end
    local turrets = {}
    for _, enemy in ipairs(Util.World.getAllWorldMoveablesWithType("enemy")) do
        if enemy ~= hunter and enemy.extra.name == "turret" then
            turrets[#turrets + 1] = {
                enemy.TMod.x.base,
                enemy.TMod.y.base,
            }
        end
    end
    local config = Macros[hunter.extra.name] or Macros.hunter
    return Util.World.hasHunterSightlineFrom(
        G.flags.saveData.curRoom,
        hunter.TMod.x.base,
        hunter.TMod.y.base,
        targetX,
        targetY,
        turrets,
        config.range
    )
end

function Util.World.isPositionInTurretSightline(x, y)
    for _, enemy in ipairs(Util.World.getAllWorldMoveablesWithType("enemy")) do
        if enemy.extra.name == "turret"
            and enemy.extra.hp > 0
            and Util.World.hasTurretSightline(enemy, x, y)
        then
            return true
        end
    end
    return false
end

local function generateAuxDoor(side, w, h, index)
    local aux = {}
    local r = love.math.random(1, h - 2)
    local g = love.math.random(1, w - 2)
    if side == "tl" then
        aux = { x = -1, y = r, a = { x = 0, y = r }, index = index, side = side }
    elseif side == "dr" then
        aux = { x = w, y = r, a = { x = w-1, y = r }, index = index, side = side }
    elseif side == "tr" then
        aux = { x = g, y = -1, a = { x = g, y = 0 }, index = index, side = side }
    else
        aux = { x = g, y = h, a = { x = g, y = h-1 }, index = index, side = side }
    end
    return aux
end

local function generateCenteredAuxDoor(side, w, h, index)
    local x = math.floor((w - 1) / 2)
    local y = math.floor((h - 1) / 2)
    if side == "tl" then
        return {x = -1, y = y, a = {x = 0, y = y}, index = index, side = side}
    elseif side == "dr" then
        return {x = w, y = y, a = {x = w - 1, y = y}, index = index, side = side}
    elseif side == "tr" then
        return {x = x, y = -1, a = {x = x, y = 0}, index = index, side = side}
    end
    return {x = x, y = h, a = {x = x, y = h - 1}, index = index, side = side}
end

local function fillFloor(room)
    room.floor = {}
    for x = 0, room.size.w - 1 do
        room.floor[x] = {}
        for y = 0, room.size.h - 1 do
            room.floor[x][y] = true
        end
    end
end

local function clearFloor(room)
    room.floor = {}
    for x = 0, room.size.w - 1 do
        room.floor[x] = {}
    end
end

local function carveFloor(room, x, y)
    if x >= 0 and y >= 0 and x < room.size.w and y < room.size.h then
        room.floor[x][y] = true
    end
end

local function carveChamber(room, center, radius)
    for x = center[1] - radius, center[1] + radius do
        for y = center[2] - radius, center[2] + radius do
            carveFloor(room, x, y)
        end
    end
end

local function carveCorridor(room, from, to, horizontalFirst, widen)
    local x, y = from[1], from[2]
    carveFloor(room, x, y)

    local function carveStep()
        carveFloor(room, x, y)
        if widen then
            if horizontalFirst then
                carveFloor(room, x, y + 1)
            else
                carveFloor(room, x + 1, y)
            end
        end
    end

    local function moveX()
        while x ~= to[1] do
            x = x + (to[1] > x and 1 or -1)
            carveStep()
        end
    end

    local function moveY()
        while y ~= to[2] do
            y = y + (to[2] > y and 1 or -1)
            carveStep()
        end
    end

    if horizontalFirst then
        moveX()
        moveY()
    else
        moveY()
        moveX()
    end
end

local DOOR_INWARD = {
    tl = { 1, 0 },
    dr = { -1, 0 },
    tr = { 0, 1 },
    dl = { 0, -1 },
}

local function reserveDoorApproaches(room)
    local reserved = {}
    for _, door in ipairs(room.doors) do
        local direction = DOOR_INWARD[door.side]
        for depth = 0, 2 do
            local x = door.a.x + direction[1] * depth
            local y = door.a.y + direction[2] * depth
            if x >= 0 and y >= 0 and x < room.size.w and y < room.size.h then
                reserved[coordKey(x, y)] = true
            end
        end
    end
    return reserved
end

local function getCriticalPaths(room, blocked)
    local start = room.doors[1].a
    local startKey = coordKey(start.x, start.y)
    if not Util.World.isFloor(room, start.x, start.y) or blocked[startKey] then
        return false
    end

    local queue = { { start.x, start.y } }
    local head = 1
    local parents = { [startKey] = false }
    local positions = { [startKey] = { start.x, start.y } }
    local directions = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

    while head <= #queue do
        local current = queue[head]
        head = head + 1
        local currentKey = coordKey(current[1], current[2])
        for _, direction in ipairs(directions) do
            local x = current[1] + direction[1]
            local y = current[2] + direction[2]
            local key = coordKey(x, y)
            if Util.World.isFloor(room, x, y) and not blocked[key] and parents[key] == nil then
                parents[key] = currentKey
                positions[key] = { x, y }
                queue[#queue + 1] = { x, y }
            end
        end
    end

    local critical = {}
    for _, door in ipairs(room.doors) do
        local key = coordKey(door.a.x, door.a.y)
        if parents[key] == nil then
            return false
        end
        while key do
            local position = positions[key]
            critical[key] = true
            key = parents[key]
        end
    end
    return true, critical
end

local function getReachableTiles(room, start, blocked)
    local startKey = coordKey(start.x, start.y)
    if not Util.World.isFloor(room, start.x, start.y) or blocked[startKey] then
        return {}, {}
    end

    local queue = { { start.x, start.y } }
    local head = 1
    local reachable = { [startKey] = { start.x, start.y } }
    local distances = { [startKey] = 0 }
    local directions = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

    while head <= #queue do
        local current = queue[head]
        head = head + 1
        local currentKey = coordKey(current[1], current[2])
        for _, direction in ipairs(directions) do
            local x = current[1] + direction[1]
            local y = current[2] + direction[2]
            local key = coordKey(x, y)
            if Util.World.isFloor(room, x, y)
                and not blocked[key]
                and not reachable[key]
            then
                reachable[key] = { x, y }
                distances[key] = distances[currentKey] + 1
                queue[#queue + 1] = { x, y }
            end
        end
    end

    return reachable, distances
end

local function carveBranchedShape(room)
    clearFloor(room)
    local hub = {
        love.math.random(1, room.size.w - 2),
        love.math.random(1, room.size.h - 2),
    }
    carveChamber(room, hub, 1)

    for _, door in ipairs(room.doors) do
        local entrance = { door.a.x, door.a.y }
        local direction = DOOR_INWARD[door.side]
        local approach = {
            door.a.x + direction[1] * 2,
            door.a.y + direction[2] * 2,
        }
        carveCorridor(room, entrance, approach, direction[1] ~= 0, false)
        carveCorridor(room, approach, hub, Util.Math.chance(1 / 2), Util.Math.chance(1 / 3))
    end

    local branchCount = love.math.random(1, 3)
    for _ = 1, branchCount do
        local endpoint = {
            love.math.random(1, room.size.w - 2),
            love.math.random(1, room.size.h - 2),
        }
        local anchor = Util.Math.chance(1 / 2)
            and hub
            or {
                love.math.random(math.max(0, hub[1] - 1), math.min(room.size.w - 1, hub[1] + 1)),
                love.math.random(math.max(0, hub[2] - 1), math.min(room.size.h - 1, hub[2] + 1)),
            }
        carveCorridor(room, anchor, endpoint, Util.Math.chance(1 / 2), Util.Math.chance(1 / 3))
        carveChamber(room, endpoint, love.math.random(0, 1))
    end
end

local function carveMazeShape(room)
    clearFloor(room)
    local nodes = {}
    for x = 1, room.size.w - 2, 2 do
        for y = 1, room.size.h - 2, 2 do
            nodes[#nodes + 1] = { x, y }
        end
    end

    local start = nodes[love.math.random(1, #nodes)]
    local stack = { start }
    local visited = { [coordKey(start[1], start[2])] = true }
    carveFloor(room, start[1], start[2])
    local directions = { { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 } }

    while #stack > 0 do
        local current = stack[#stack]
        local available = {}
        for _, direction in ipairs(directions) do
            local x = current[1] + direction[1]
            local y = current[2] + direction[2]
            if x >= 1 and y >= 1 and x <= room.size.w - 2 and y <= room.size.h - 2
                and not visited[coordKey(x, y)]
            then
                available[#available + 1] = { x, y }
            end
        end

        if #available > 0 then
            local nextNode = available[love.math.random(1, #available)]
            carveFloor(room, (current[1] + nextNode[1]) / 2, (current[2] + nextNode[2]) / 2)
            carveFloor(room, nextNode[1], nextNode[2])
            visited[coordKey(nextNode[1], nextNode[2])] = true
            stack[#stack + 1] = nextNode
        else
            table.remove(stack)
        end
    end

    for _, node in ipairs(nodes) do
        if Util.Math.chance(1 / 20) then
            local direction = directions[love.math.random(1, #directions)]
            local x = node[1] + direction[1]
            local y = node[2] + direction[2]
            if x >= 1 and y >= 1 and x <= room.size.w - 2 and y <= room.size.h - 2 then
                carveFloor(room, node[1] + direction[1] / 2, node[2] + direction[2] / 2)
            end
        end
    end

    for _, door in ipairs(room.doors) do
        local direction = DOOR_INWARD[door.side]
        local entrance = { door.a.x, door.a.y }
        local approach = {
            door.a.x + direction[1] * 2,
            door.a.y + direction[2] * 2,
        }
        local closestNode = nodes[1]
        local closestDistance = math.huge
        for _, node in ipairs(nodes) do
            local distance = math.abs(node[1] - approach[1]) + math.abs(node[2] - approach[2])
            if distance < closestDistance then
                closestDistance = distance
                closestNode = node
            end
        end
        carveCorridor(room, entrance, approach, direction[1] ~= 0, false)
        carveCorridor(room, approach, closestNode, Util.Math.chance(1 / 2), false)
    end
end

local function carveCompactShape(room, reserved)
    fillFloor(room)
    local corners = {
        { left = true, top = true },
        { left = false, top = true },
        { left = true, top = false },
        { left = false, top = false },
    }
    local notchCount = love.math.random(1, 3)

    for _ = 1, notchCount do
        if #corners == 0 then break end
        local picked = love.math.random(1, #corners)
        local corner = table.remove(corners, picked)
        local notchW = love.math.random(1, math.min(2, room.size.w - 3))
        local notchH = love.math.random(1, math.min(2, room.size.h - 3))
        local xmin = corner.left and 0 or room.size.w - notchW
        local xmax = corner.left and notchW - 1 or room.size.w - 1
        local ymin = corner.top and 0 or room.size.h - notchH
        local ymax = corner.top and notchH - 1 or room.size.h - 1
        local removed = {}

        for x = xmin, xmax do
            for y = ymin, ymax do
                if not reserved[coordKey(x, y)] and room.floor[x][y] then
                    room.floor[x][y] = nil
                    removed[#removed + 1] = { x, y }
                end
            end
        end

        local connected = getCriticalPaths(room, {})
        if not connected then
            for _, position in ipairs(removed) do
                room.floor[position[1]][position[2]] = true
            end
        end
    end
end

local function generateFloorShape(room, reserved, index)
    if isGrassIndex(index) then
        room.layout = "open"
        fillFloor(room)
    elseif room.layout == "maze" then
        carveMazeShape(room)
    elseif Util.Math.chance(3 / 5) then
        room.layout = "branched"
        carveBranchedShape(room)
    else
        room.layout = "notched"
        carveCompactShape(room, reserved)
    end

    for key in pairs(reserved) do
        local comma = string.find(key, ",", 1, true)
        local x = tonumber(string.sub(key, 1, comma - 1))
        local y = tonumber(string.sub(key, comma + 1))
        carveFloor(room, x, y)
    end

    if not getCriticalPaths(room, {}) then
        fillFloor(room)
    end
end

local function addReachableBarrier(room, reserved, identifier, index)
    if room.layout == "maze" or isGrassIndex(index) then
        return identifier
    end
    for _ = 1, 24 do
        local vertical = Util.Math.chance(1 / 2)
        local line = vertical
            and love.math.random(2, room.size.w - 2)
            or love.math.random(2, room.size.h - 2)
        local candidates = {}

        for i = 0, (vertical and room.size.h or room.size.w) - 1 do
            local x = vertical and line or i
            local y = vertical and i or line
            if Util.World.isFloor(room, x, y) and not reserved[coordKey(x, y)] then
                candidates[#candidates + 1] = { x, y }
            end
        end

        if #candidates >= 1 then
            local passageGap = candidates[love.math.random(1, #candidates)]
            local walls = {}
            local blocked = {}
            for i = 0, (vertical and room.size.h or room.size.w) - 1 do
                local x = vertical and line or i
                local y = vertical and i or line
                local key = coordKey(x, y)
                local isGap = x == passageGap[1] and y == passageGap[2]
                if Util.World.isFloor(room, x, y) and not isGap and not reserved[key] then
                    walls[#walls + 1] = {
                        name = "prisonBar",
                        type = "wall",
                        x = x,
                        y = y,
                        dir = vertical and 1 or -1,
                    }
                    blocked[key] = true
                end
            end

            if #walls > 0 and getCriticalPaths(room, blocked) then
                room.walls = walls
                return identifier
            end
        end
    end

    room.walls = {}
    return identifier
end

local function addPrisonGatePuzzle(room, reserved, index)
    room.gates = {}
    room.keys = {}

    if type(index) ~= "number" or index < 2 or index > 5
        or #room.doors < 2 or not Util.Math.chance(2 / 5)
    then
        return false
    end

    local blocked = {}
    for _, wall in ipairs(room.walls) do
        blocked[coordKey(wall.x, wall.y)] = true
    end

    local start = room.doors[1].a
    local reachable, baseDistances = getReachableTiles(room, start, blocked)
    local connected, critical = getCriticalPaths(room, blocked)
    if not connected then
        return false
    end

    local doorTiles = {}
    for _, door in ipairs(room.doors) do
        doorTiles[coordKey(door.a.x, door.a.y)] = true
    end

    local best
    for key, position in pairs(reachable) do
        if not reserved[key] and not doorTiles[key] then
            blocked[key] = true
            local gateReachable, gateDistances = getReachableTiles(room, start, blocked)
            blocked[key] = nil

            local blockedExitCount = 0
            local distanceIncrease = 0
            for doorIndex = 2, #room.doors do
                local door = room.doors[doorIndex]
                local doorKey = coordKey(door.a.x, door.a.y)
                if not gateReachable[doorKey] then
                    blockedExitCount = blockedExitCount + 1
                else
                    distanceIncrease = distanceIncrease
                        + math.max(0, gateDistances[doorKey] - baseDistances[doorKey])
                end
            end

            local keySpace = 0
            for reachableKey in pairs(gateReachable) do
                if reachableKey ~= coordKey(start.x, start.y)
                    and reachableKey ~= key
                    and not doorTiles[reachableKey]
                    and not reserved[reachableKey]
                then
                    keySpace = keySpace + 1
                end
            end

            local blocksEveryExit = blockedExitCount == #room.doors - 1
            local isUseful = (room.layout == "maze" and blocksEveryExit)
                or (room.layout ~= "maze"
                    and (blockedExitCount > 0 or distanceIncrease > 0))
            if keySpace > 0 and isUseful then
                local score = blockedExitCount * 10000
                    + distanceIncrease * 100
                    + (critical[key] and 25 or 0)
                    + baseDistances[key]
                if not best or score > best.score then
                    best = {
                        x = position[1],
                        y = position[2],
                        key = key,
                        score = score,
                        reachable = gateReachable,
                        distances = gateDistances,
                    }
                end
            end
        end
    end

    if not best then
        return false
    end

    local keyPosition
    local keyDistance = -1
    for key, position in pairs(best.reachable) do
        if key ~= coordKey(start.x, start.y)
            and key ~= best.key
            and not doorTiles[key]
            and not reserved[key]
            and best.distances[key] > keyDistance
        then
            keyPosition = position
            keyDistance = best.distances[key]
        end
    end
    if not keyPosition then
        return false
    end

    local horizontalPath = Util.World.isFloor(room, best.x - 1, best.y)
        and Util.World.isFloor(room, best.x + 1, best.y)
    local verticalPath = Util.World.isFloor(room, best.x, best.y - 1)
        and Util.World.isFloor(room, best.x, best.y + 1)
    local direction = horizontalPath and not verticalPath and 1
        or verticalPath and not horizontalPath and -1
        or 1

    room.gates[1] = {
        id = 1,
        x = best.x,
        y = best.y,
        dir = direction,
        locked = true,
    }
    room.keys[1] = {
        id = 1,
        x = keyPosition[1],
        y = keyPosition[2],
        itemKey = "prison_key",
    }
    reserved[best.key] = true
    reserved[coordKey(keyPosition[1], keyPosition[2])] = true
    return true
end

local function getPrisonEnemyCap(room, index)
    if type(index) ~= "number" or index < 2 or index > 5 then
        return math.huge
    end

    local floorTiles = 0
    for x = 0, room.size.w - 1 do
        for y = 0, room.size.h - 1 do
            if Util.World.isFloor(room, x, y) then
                floorTiles = floorTiles + 1
            end
        end
    end
    if floorTiles <= 36 then
        return 2
    elseif floorTiles <= 52 then
        return 3
    end
    return 4
end

local function addRoomEnemies(room, reserved, identifier, index)
    if isGrassIndex(index) or isRuinsIndex(index) then
        return identifier
    end

    local blocked = {}
    for _, wall in ipairs(room.walls) do
        blocked[coordKey(wall.x, wall.y)] = true
    end
    for _, enemy in ipairs(room.enemies) do
        blocked[coordKey(enemy.pos[1], enemy.pos[2])] = true
    end

    local connected, critical = getCriticalPaths(room, blocked)
    if not connected then
        return identifier
    end

    local candidates = {}
    for x = 1, room.size.w - 2 do
        for y = 1, room.size.h - 2 do
            local key = coordKey(x, y)
            if Util.World.isFloor(room, x, y)
                and not reserved[key]
                and not blocked[key]
                and not critical[key]
            then
                candidates[#candidates + 1] = { x, y }
            end
        end
    end

    local availableSlots = math.max(
        0,
        getPrisonEnemyCap(room, index) - #room.enemies
    )
    for _ = 1, math.min(3, availableSlots, #candidates) do
        local picked = love.math.random(1, #candidates)
        local position = table.remove(candidates, picked)
        room.enemies[#room.enemies + 1] = {
            name = Util.World.getEnemy(index),
            pos = position,
            facing = tostring(love.math.random(1, 4)),
            id = identifier,
        }
        identifier = identifier + 1
    end
    return identifier
end

local function roomHasEnemy(room, enemyName)
    for _, enemy in ipairs(room.enemies or {}) do
        if enemy.name == enemyName then
            return true
        end
    end
    return false
end

local function addGrassWizard(
    room,
    reserved,
    identifier,
    index,
    wizardBossRoomIndex
)
    if index ~= wizardBossRoomIndex then
        return identifier
    end

    local blocked = {}
    for _, wall in ipairs(room.walls) do
        blocked[coordKey(wall.x, wall.y)] = true
    end
    for _, gate in ipairs(room.gates or {}) do
        if gate.locked ~= false then
            blocked[coordKey(gate.x, gate.y)] = true
        end
    end
    for _, enemy in ipairs(room.enemies) do
        blocked[coordKey(enemy.pos[1], enemy.pos[2])] = true
    end

    local entrance = room.doors[1] and room.doors[1].a
    local candidates = {}
    for x = 1, room.size.w - 2 do
        for y = 1, room.size.h - 2 do
            local key = coordKey(x, y)
            if Util.World.isFloor(room, x, y)
                and not reserved[key]
                and not blocked[key]
            then
                local entranceDistance = entrance
                    and math.abs(x - entrance.x) + math.abs(y - entrance.y)
                    or 0
                candidates[#candidates + 1] = {
                    x = x,
                    y = y,
                    score = entranceDistance + love.math.random(),
                }
            end
        end
    end
    table.sort(candidates, function(a, b)
        return a.score > b.score
    end)

    for _, candidate in ipairs(candidates) do
        local key = coordKey(candidate.x, candidate.y)
        blocked[key] = true
        if getCriticalPaths(room, blocked) then
            room.enemies[#room.enemies + 1] = {
                name = "wizard",
                pos = {candidate.x, candidate.y},
                facing = tostring(love.math.random(1, 4)),
                id = identifier,
            }
            reserved[key] = true
            return identifier + 1
        end
        blocked[key] = nil
    end

    return identifier
end

local function addGrassTurrets(room, reserved, identifier, index)
    if not isGrassIndex(index) then
        return identifier
    end

    local blocked = {}
    for _, wall in ipairs(room.walls) do
        blocked[coordKey(wall.x, wall.y)] = true
    end
    for _, gate in ipairs(room.gates or {}) do
        if gate.locked ~= false then
            blocked[coordKey(gate.x, gate.y)] = true
        end
    end
    for _, enemy in ipairs(room.enemies) do
        blocked[coordKey(enemy.pos[1], enemy.pos[2])] = true
    end

    local connected, critical = getCriticalPaths(room, blocked)
    if not connected then
        return identifier
    end

    local candidates = {}
    for x = 1, room.size.w - 2 do
        for y = 1, room.size.h - 2 do
            local key = coordKey(x, y)
            if Util.World.isFloor(room, x, y)
                and not blocked[key]
                and not reserved[key]
                and not critical[key]
            then
                for facing, _ in pairs(TURRET_FACING_VECTORS) do
                    local visibleTiles = 0
                    local trafficHits = 0
                    for targetX = 0, room.size.w - 1 do
                        for targetY = 0, room.size.h - 1 do
                            if Util.World.isFloor(room, targetX, targetY)
                                and Util.World.hasTurretSightlineFrom(
                                    room,
                                    x,
                                    y,
                                    facing,
                                    targetX,
                                    targetY
                                )
                            then
                                visibleTiles = visibleTiles + 1
                                if critical[coordKey(targetX, targetY)] then
                                    trafficHits = trafficHits + 1
                                end
                            end
                        end
                    end
                    if visibleTiles >= 5 and trafficHits > 0 then
                        local edgeDistance = math.min(
                            x,
                            y,
                            room.size.w - 1 - x,
                            room.size.h - 1 - y
                        )
                        candidates[#candidates + 1] = {
                            x = x,
                            y = y,
                            facing = facing,
                            score = trafficHits * 10 + visibleTiles
                                - edgeDistance + love.math.random(),
                        }
                    end
                end
            end
        end
    end
    table.sort(candidates, function(a, b)
        return a.score > b.score
    end)

    local desired = roomHasEnemy(room, "wizard")
        and 1
        or (room.size.w * room.size.h >= 60 and 3 or 2)
    local chosen = {}
    for _, candidate in ipairs(candidates) do
        if #chosen >= desired then
            break
        end
        local farEnough = true
        for _, turret in ipairs(chosen) do
            if math.abs(turret.x - candidate.x)
                + math.abs(turret.y - candidate.y) < 3
            then
                farEnough = false
                break
            end
        end

        local key = coordKey(candidate.x, candidate.y)
        if farEnough and not blocked[key] then
            blocked[key] = true
            if getCriticalPaths(room, blocked) then
                local turret = {
                    name = "turret",
                    pos = {candidate.x, candidate.y},
                    facing = candidate.facing,
                    id = identifier,
                }
                room.enemies[#room.enemies + 1] = turret
                chosen[#chosen + 1] = {
                    x = candidate.x,
                    y = candidate.y,
                }
                reserved[key] = true
                identifier = identifier + 1
            else
                blocked[key] = nil
            end
        end
    end
    return identifier
end

local function addGrassHunters(room, reserved, identifier, index)
    if not isGrassIndex(index) then
        return identifier
    end

    local blocked = {}
    for _, wall in ipairs(room.walls) do
        blocked[coordKey(wall.x, wall.y)] = true
    end
    for _, enemy in ipairs(room.enemies) do
        blocked[coordKey(enemy.pos[1], enemy.pos[2])] = true
    end
    local connected, critical = getCriticalPaths(room, blocked)
    if not connected then
        return identifier
    end

    local candidates = {}
    for x = 1, room.size.w - 2 do
        for y = 1, room.size.h - 2 do
            local key = coordKey(x, y)
            if Util.World.isFloor(room, x, y)
                and not reserved[key]
                and not blocked[key]
                and not critical[key]
            then
                local turretLaneScore = 0
                for _, enemy in ipairs(room.enemies) do
                    if enemy.name == "turret"
                        and Util.World.hasTurretSightlineFrom(
                            room,
                            enemy.pos[1],
                            enemy.pos[2],
                            enemy.facing,
                            x,
                            y
                        )
                    then
                        turretLaneScore = turretLaneScore + 4
                    end
                end
                candidates[#candidates + 1] = {
                    x = x,
                    y = y,
                    score = turretLaneScore + love.math.random(),
                }
            end
        end
    end
    table.sort(candidates, function(a, b)
        return a.score > b.score
    end)

    local desired = roomHasEnemy(room, "wizard")
        and 1
        or (room.size.w * room.size.h >= 60 and 2 or 1)
    local chosen = {}
    for _, candidate in ipairs(candidates) do
        if #chosen >= desired then
            break
        end
        local farEnough = true
        for _, hunter in ipairs(chosen) do
            if math.abs(hunter.x - candidate.x)
                + math.abs(hunter.y - candidate.y) < 3
            then
                farEnough = false
                break
            end
        end
        local key = coordKey(candidate.x, candidate.y)
        if farEnough and not blocked[key] then
            blocked[key] = true
            if getCriticalPaths(room, blocked) then
                room.enemies[#room.enemies + 1] = {
                    name = "hunter",
                    pos = {candidate.x, candidate.y},
                    facing = tostring(love.math.random(1, 4)),
                    id = identifier,
                }
                chosen[#chosen + 1] = candidate
                reserved[key] = true
                identifier = identifier + 1
            else
                blocked[key] = nil
            end
        end
    end
    return identifier
end

local function addRuinsEnemies(room, reserved, identifier, index)
    if not isRuinsIndex(index) then
        return identifier
    end

    local blocked = {}
    for _, wall in ipairs(room.walls) do
        blocked[coordKey(wall.x, wall.y)] = true
    end
    for _, gate in ipairs(room.gates or {}) do
        if gate.locked ~= false then
            blocked[coordKey(gate.x, gate.y)] = true
        end
    end
    for _, enemy in ipairs(room.enemies) do
        blocked[coordKey(enemy.pos[1], enemy.pos[2])] = true
    end

    local connected, critical = getCriticalPaths(room, blocked)
    if not connected then
        return identifier
    end

    local candidates = {}
    for x = 1, room.size.w - 2 do
        for y = 1, room.size.h - 2 do
            local key = coordKey(x, y)
            if Util.World.isFloor(room, x, y)
                and not reserved[key]
                and not blocked[key]
                and not critical[key]
            then
                candidates[#candidates + 1] = {x, y}
            end
        end
    end

    local skeletonCount = room.size.w * room.size.h >= 60 and 3 or 2
    local skeletonsPlaced = 0
    while skeletonsPlaced < skeletonCount and #candidates > 0 do
        local candidateIndex = love.math.random(1, #candidates)
        local position = table.remove(candidates, candidateIndex)
        local key = coordKey(position[1], position[2])
        blocked[key] = true
        if getCriticalPaths(room, blocked) then
            room.enemies[#room.enemies + 1] = {
                name = "skeleton",
                pos = position,
                facing = tostring(love.math.random(1, 4)),
                id = identifier,
            }
            reserved[key] = true
            identifier = identifier + 1
            skeletonsPlaced = skeletonsPlaced + 1
        else
            blocked[key] = nil
        end
    end

    if #candidates > 0 and Util.Math.chance(Macros.elite.spawnChance) then
        while #candidates > 0 do
            local position = table.remove(
                candidates,
                love.math.random(1, #candidates)
            )
            local key = coordKey(position[1], position[2])
            blocked[key] = true
            if getCriticalPaths(room, blocked) then
                room.enemies[#room.enemies + 1] = {
                    name = "elite",
                    pos = position,
                    facing = tostring(love.math.random(1, 4)),
                    id = identifier,
                }
                reserved[key] = true
                identifier = identifier + 1
                break
            end
            blocked[key] = nil
        end
    end

    return identifier
end

local function addPrisonOfficer(room, reserved, identifier, index)
    if type(index) ~= "number"
        or index < 2
        or index > 5
        or #room.enemies >= getPrisonEnemyCap(room, index)
        or not Util.Math.chance(Macros.officer.spawnChance)
    then
        return identifier
    end

    local blocked = {}
    for _, wall in ipairs(room.walls) do
        blocked[coordKey(wall.x, wall.y)] = true
    end
    for _, enemy in ipairs(room.enemies) do
        blocked[coordKey(enemy.pos[1], enemy.pos[2])] = true
    end
    for _, gate in ipairs(room.gates or {}) do
        if gate.locked ~= false then
            blocked[coordKey(gate.x, gate.y)] = true
        end
    end

    local connected, critical = getCriticalPaths(room, blocked)
    if not connected then
        return identifier
    end

    local candidates = {}
    for x = 1, room.size.w - 2 do
        for y = 1, room.size.h - 2 do
            local key = coordKey(x, y)
            if Util.World.isFloor(room, x, y)
                and not reserved[key]
                and not blocked[key]
                and not critical[key]
            then
                candidates[#candidates + 1] = {x, y}
            end
        end
    end
    if #candidates == 0 then
        return identifier
    end

    local position = candidates[love.math.random(1, #candidates)]
    room.enemies[#room.enemies + 1] = {
        name = "officer",
        pos = position,
        facing = tostring(love.math.random(1, 4)),
        id = identifier,
    }
    reserved[coordKey(position[1], position[2])] = true
    return identifier + 1
end

local function addPrisonCellBoss(
    room,
    reserved,
    identifier,
    index,
    bossRoomIndex
)
    if index ~= bossRoomIndex
        or #room.enemies >= getPrisonEnemyCap(room, index)
    then
        return identifier
    end

    local blocked = {}
    for _, wall in ipairs(room.walls) do
        blocked[coordKey(wall.x, wall.y)] = true
    end
    for _, enemy in ipairs(room.enemies) do
        blocked[coordKey(enemy.pos[1], enemy.pos[2])] = true
    end
    for _, gate in ipairs(room.gates or {}) do
        if gate.locked ~= false then
            blocked[coordKey(gate.x, gate.y)] = true
        end
    end

    local connected, critical = getCriticalPaths(room, blocked)
    if not connected then
        return identifier
    end

    local candidates = {}
    for x = 1, room.size.w - 2 do
        for y = 1, room.size.h - 2 do
            local key = coordKey(x, y)
            if Util.World.isFloor(room, x, y)
                and not reserved[key]
                and not blocked[key]
                and not critical[key]
            then
                candidates[#candidates + 1] = { x, y }
            end
        end
    end
    if #candidates == 0 then
        return identifier
    end

    room.enemies[#room.enemies + 1] = {
        name = "cellboss",
        pos = table.remove(candidates, love.math.random(1, #candidates)),
        facing = tostring(love.math.random(1, 4)),
        id = identifier,
    }
    return identifier + 1
end

local function coverTileIsClear(room, reserved, occupied, x, y)
    if not Util.World.isFloor(room, x, y)
        or occupied[coordKey(x, y)]
    then
        return false
    end
    for _, door in ipairs(room.doors or {}) do
        if door.a and door.a.x == x and door.a.y == y then
            return false
        end
    end
    for _, enemy in ipairs(room.enemies) do
        if enemy.name == "turret"
            and math.abs(enemy.pos[1] - x)
                + math.abs(enemy.pos[2] - y) <= 1
        then
            return false
        end
    end
    return true
end

local COVER_FACING_AGAINST_TURRET = {
    ["1"] = 3,
    ["2"] = 4,
    ["3"] = 1,
    ["4"] = 2,
}

local function scoreCoverChain(room, turret, tiles, critical)
    local visibleBefore = {}
    for x = 0, room.size.w - 1 do
        for y = 0, room.size.h - 1 do
            if Util.World.isFloor(room, x, y)
                and Util.World.hasTurretSightlineFrom(
                    room,
                    turret.pos[1],
                    turret.pos[2],
                    turret.facing,
                    x,
                    y
                )
            then
                visibleBefore[#visibleBefore + 1] = {x, y}
            end
        end
    end

    local oldCoverCount = #room.covers
    for _, tile in ipairs(tiles) do
        room.covers[#room.covers + 1] = {
            x = tile[1],
            y = tile[2],
            name = "cover2",
        }
    end

    local protectedTiles = 0
    local protectedTraffic = 0
    for _, position in ipairs(visibleBefore) do
        if not Util.World.hasTurretSightlineFrom(
            room,
            turret.pos[1],
            turret.pos[2],
            turret.facing,
            position[1],
            position[2]
        ) then
            protectedTiles = protectedTiles + 1
            if critical[coordKey(position[1], position[2])] then
                protectedTraffic = protectedTraffic + 1
            end
        end
    end
    for index = #room.covers, oldCoverCount + 1, -1 do
        table.remove(room.covers, index)
    end

    if protectedTiles < 2 then
        return 0
    end
    return protectedTraffic * 12 + protectedTiles * 2 + #tiles
end

local function addGrassCovers(room, reserved, index)
    room.covers = {}
    if not isGrassIndex(index) then
        return
    end

    local occupied = {}
    for _, wall in ipairs(room.walls) do
        occupied[coordKey(wall.x, wall.y)] = true
    end
    for _, enemy in ipairs(room.enemies) do
        occupied[coordKey(enemy.pos[1], enemy.pos[2])] = true
    end
    local connected, critical = getCriticalPaths(room, occupied)
    if not connected then
        return
    end

    local candidates = {}
    for _, turret in ipairs(room.enemies) do
        if turret.name == "turret" then
            local forward = TURRET_FACING_VECTORS[turret.facing]
            local perpendicular = {-forward[2], forward[1]}
            local maximumDepth = math.max(room.size.w, room.size.h) - 2
            for depth = 2, maximumDepth do
                for length = 3, math.min(5, math.max(room.size.w, room.size.h) - 2) do
                    local lateralStart = -math.floor(length / 2)
                    local tiles = {}
                    local valid = true
                    for offset = 0, length - 1 do
                        local lateral = lateralStart + offset
                        local x = turret.pos[1] + forward[1] * depth
                            + perpendicular[1] * lateral
                        local y = turret.pos[2] + forward[2] * depth
                            + perpendicular[2] * lateral
                        if not coverTileIsClear(
                            room,
                            reserved,
                            occupied,
                            x,
                            y
                        ) then
                            valid = false
                            break
                        end
                        tiles[#tiles + 1] = {x, y}
                    end
                    if valid then
                        local score = scoreCoverChain(
                            room,
                            turret,
                            tiles,
                            critical
                        )
                        if score > 0 then
                            candidates[#candidates + 1] = {
                                turret = turret,
                                tiles = tiles,
                                orientation = COVER_FACING_AGAINST_TURRET[
                                    turret.facing
                                ],
                                score = score - depth * 0.25
                                    + love.math.random(),
                            }
                        end
                    end
                end
            end
        end
    end
    table.sort(candidates, function(a, b)
        return a.score > b.score
    end)

    local coveredTurrets = {}
    local selectedCover = {}
    local selectedChains = 0
    local desiredChains = room.size.w * room.size.h >= 60 and 2 or 1
    for _, candidate in ipairs(candidates) do
        if selectedChains >= desiredChains then
            break
        end
        if not coveredTurrets[candidate.turret.id] then
            local valid = true
            for _, tile in ipairs(candidate.tiles) do
                if not coverTileIsClear(
                    room,
                    reserved,
                    occupied,
                    tile[1],
                    tile[2]
                ) then
                    valid = false
                    break
                end
                for _, offset in ipairs({
                    {-1, 0},
                    {1, 0},
                    {0, -1},
                    {0, 1},
                }) do
                    if selectedCover[
                        coordKey(tile[1] + offset[1], tile[2] + offset[2])
                    ] then
                        valid = false
                        break
                    end
                end
                if not valid then
                    break
                end
            end
            if valid
                and scoreCoverChain(
                    room,
                    candidate.turret,
                    candidate.tiles,
                    critical
                ) > 0
            then
                for _, tile in ipairs(candidate.tiles) do
                    room.covers[#room.covers + 1] = {
                        x = tile[1],
                        y = tile[2],
                        name = "cover"..candidate.orientation,
                    }
                    occupied[coordKey(tile[1], tile[2])] = true
                    selectedCover[coordKey(tile[1], tile[2])] = true
                end
                coveredTurrets[candidate.turret.id] = true
                selectedChains = selectedChains + 1
            end
        end
    end

    if selectedChains == 0 then
        local fallbackCandidates = {}
        for _, axis in ipairs({"x", "y"}) do
            for x = 0, room.size.w - 1 do
                for y = 0, room.size.h - 1 do
                    local tiles = {}
                    local valid = true
                    for offset = 0, 2 do
                        local tileX = x + (axis == "x" and offset or 0)
                        local tileY = y + (axis == "y" and offset or 0)
                        if not coverTileIsClear(
                            room,
                            reserved,
                            occupied,
                            tileX,
                            tileY
                        ) then
                            valid = false
                            break
                        end
                        tiles[#tiles + 1] = {tileX, tileY}
                    end
                    if valid then
                        local centerX = tiles[2][1]
                        local centerY = tiles[2][2]
                        local nearestTurret
                        local nearestDistance = math.huge
                        for _, enemy in ipairs(room.enemies) do
                            if enemy.name == "turret" then
                                local distance = math.abs(enemy.pos[1] - centerX)
                                    + math.abs(enemy.pos[2] - centerY)
                                if distance < nearestDistance then
                                    nearestDistance = distance
                                    nearestTurret = enemy
                                end
                            end
                        end
                        local traffic = 0
                        for _, tile in ipairs(tiles) do
                            if critical[coordKey(tile[1], tile[2])] then
                                traffic = traffic + 1
                            end
                        end
                        local orientation
                        if axis == "x" then
                            orientation = nearestTurret
                                and nearestTurret.pos[2] < centerY and 4
                                or 2
                        else
                            orientation = nearestTurret
                                and nearestTurret.pos[1] < centerX and 1
                                or 3
                        end
                        fallbackCandidates[#fallbackCandidates + 1] = {
                            tiles = tiles,
                            orientation = orientation,
                            score = traffic * 10
                                - math.abs(centerX - room.size.w / 2)
                                - math.abs(centerY - room.size.h / 2)
                                + love.math.random(),
                        }
                    end
                end
            end
        end
        table.sort(fallbackCandidates, function(a, b)
            return a.score > b.score
        end)
        local fallback = fallbackCandidates[1]
        if fallback then
            for _, tile in ipairs(fallback.tiles) do
                room.covers[#room.covers + 1] = {
                    x = tile[1],
                    y = tile[2],
                    name = "cover"..fallback.orientation,
                }
            end
        end
    end
end

local function addGroundHealingItem(room, reserved, index)
    if getTransitionRoomConfig(index)
        or not Util.Math.chance(Macros.groundHealing.spawnChance)
    then
        return false
    end

    local blocked = {}
    local occupied = {}
    for _, wall in ipairs(room.walls or {}) do
        local key = coordKey(wall.x, wall.y)
        blocked[key] = true
        occupied[key] = true
    end
    for _, gate in ipairs(room.gates or {}) do
        local key = coordKey(gate.x, gate.y)
        occupied[key] = true
        if gate.locked ~= false then
            blocked[key] = true
        end
    end
    for _, enemy in ipairs(room.enemies or {}) do
        local key = coordKey(enemy.pos[1], enemy.pos[2])
        blocked[key] = true
        occupied[key] = true
    end
    for _, cover in ipairs(room.covers or {}) do
        occupied[coordKey(cover.x, cover.y)] = true
    end
    for _, keyPickup in ipairs(room.keys or {}) do
        occupied[coordKey(keyPickup.x, keyPickup.y)] = true
    end
    for _, pickup in ipairs(room.pickups or {}) do
        occupied[coordKey(pickup.x, pickup.y)] = true
    end

    local entrance = room.doors[1] and room.doors[1].a
    if not entrance then
        return false
    end
    local reachable = getReachableTiles(room, entrance, blocked)
    local candidates = {}
    for key, position in pairs(reachable) do
        if not reserved[key] and not occupied[key] then
            candidates[#candidates + 1] = position
        end
    end
    if #candidates == 0 then
        return false
    end

    local itemKey = poolItem(Macros.groundHealing.pool)
    if not itemKey then
        return false
    end
    local position = candidates[love.math.random(1, #candidates)]
    room.pickups[#room.pickups + 1] = {
        id = "mapHealing",
        x = position[1],
        y = position[2],
        itemKey = itemKey,
    }
    reserved[coordKey(position[1], position[2])] = true
    return true
end

local function roomBlockers(room)
    local blocked = {}
    for _, wall in ipairs(room.walls) do
        blocked[coordKey(wall.x, wall.y)] = true
    end
    for _, enemy in ipairs(room.enemies) do
        blocked[coordKey(enemy.pos[1], enemy.pos[2])] = true
    end
    return blocked
end

local function facingForVector(x, y)
    if x < 0 then
        return "1"
    elseif y > 0 then
        return "2"
    elseif x > 0 then
        return "3"
    end
    return "4"
end

local function transitionRoomPosition(room, depth, lateral)
    local entrance = room.doors[1]
    local inward = DOOR_INWARD[entrance.side]
    local perpendicular = {-inward[2], inward[1]}
    return {
        entrance.a.x + inward[1] * depth + perpendicular[1] * lateral,
        entrance.a.y + inward[2] * depth + perpendicular[2] * lateral,
    }
end

local function generateTransitionRoom(room, reserved, index)
    local config = getTransitionRoomConfig(index)
    room.layout = "transition"
    room.transition = {
        fromArea = config.fromArea,
        toArea = config.toArea,
    }
    fillFloor(room)

    local entrance = room.doors[1]
    local inward = DOOR_INWARD[entrance.side]
    local travelLength = inward[1] ~= 0 and room.size.w or room.size.h
    room.tileAreas = {}
    for x = 0, room.size.w - 1 do
        room.tileAreas[x] = {}
        for y = 0, room.size.h - 1 do
            local progress = (
                (x - entrance.a.x) * inward[1]
                + (y - entrance.a.y) * inward[2]
            ) / (travelLength - 1)
            if progress < 0.4 then
                room.tileAreas[x][y] = config.fromArea
            elseif progress > 0.6 then
                room.tileAreas[x][y] = config.toArea
            else
                room.tileAreas[x][y] = (x + y) % 2 == 0
                    and config.fromArea
                    or config.toArea
            end
        end
    end

    local sourcePosition = transitionRoomPosition(room, 3, -2)
    local targetPosition = transitionRoomPosition(
        room,
        travelLength - 3,
        2
    )
    local enemyPositions = {sourcePosition, targetPosition}
    for enemyIndex, enemyName in ipairs(config.enemies) do
        local position = enemyPositions[enemyIndex]
        room.enemies[#room.enemies + 1] = {
            name = enemyName,
            pos = position,
            facing = enemyIndex == 1
                and facingForVector(inward[1], inward[2])
                or facingForVector(-inward[1], -inward[2]),
            id = enemyIndex,
        }
        reserved[coordKey(position[1], position[2])] = true
    end

    local coverDepth = math.floor(travelLength / 2)
    local coverFacing = inward[1] ~= 0
        and (inward[1] > 0 and 3 or 1)
        or (inward[2] > 0 and 2 or 4)
    for lateral = -1, 1 do
        local position = transitionRoomPosition(
            room,
            coverDepth,
            lateral
        )
        room.covers[#room.covers + 1] = {
            x = position[1],
            y = position[2],
            name = "cover"..coverFacing,
        }
    end
end

function Util.World.getWallDirection(room, wall)
    local horizontal = false
    local vertical = false
    for _, other in ipairs(room.walls) do
        if other ~= wall then
            horizontal = horizontal
                or (other.y == wall.y and math.abs(other.x - wall.x) == 1)
            vertical = vertical
                or (other.x == wall.x and math.abs(other.y - wall.y) == 1)
        end
    end
    if horizontal and not vertical then
        return -1
    elseif vertical and not horizontal then
        return 1
    end
    return wall.dir or 1
end

local function randomRoomSize(index)
    if getTransitionRoomConfig(index) then
        return {w = 10, h = 8}, "transition"
    end

    local function orient(shortSide, longSide, layout)
        if Util.Math.chance(1 / 2) then
            return {w = shortSide, h = longSide}, layout
        end
        return {w = longSide, h = shortSide}, layout
    end

    if isRuinsIndex(index) then
        if Util.Math.chance(7 / 25) then
            return orient(8, love.math.random(11, 12), "maze")
        end
        return orient(
            love.math.random(7, 8),
            love.math.random(11, 12),
            nil
        )
    end

    if isGrassIndex(index) then
        if Util.Math.chance(7 / 25) then
            return orient(8, love.math.random(10, 11), "maze")
        end
        return orient(
            love.math.random(7, 8),
            love.math.random(9, 11),
            nil
        )
    end

    if Util.Math.chance(7 / 25) then
        local longSide = love.math.random(8, 10)
        return orient(7, longSide, "maze")
    end

    local largerRoom = Util.Math.chance(1 / 3)
    local shortSide = largerRoom and love.math.random(5, 7) or love.math.random(4, 6)
    local longSide = largerRoom and love.math.random(8, 10) or love.math.random(7, 9)
    return orient(shortSide, longSide, nil)
end

function Util.World.regenerateRoom(room, index)
    local size, layout = randomRoomSize(index)
    local replacement = {
        size = size,
        layout = layout,
        enemies = {},
        doors = {},
        walls = {},
        gates = {},
        keys = {},
        pickups = {},
        covers = {},
    }

    for _, door in ipairs(room.doors) do
        local doorGenerator = getTransitionRoomConfig(index)
            and generateCenteredAuxDoor
            or generateAuxDoor
        replacement.doors[#replacement.doors + 1] = doorGenerator(
            door.side,
            replacement.size.w,
            replacement.size.h,
            door.index
        )
    end

    local reserved = reserveDoorApproaches(replacement)
    if getTransitionRoomConfig(index) then
        generateTransitionRoom(replacement, reserved, index)
        assert(getCriticalPaths(replacement, roomBlockers(replacement)),
            "Transition room regeneration produced an unreachable exit")
        return replacement
    end
    generateFloorShape(replacement, reserved, index)
    local identifier = addReachableBarrier(replacement, reserved, 1, index)
    addPrisonGatePuzzle(replacement, reserved, index)
    local bossRoomIndex
    local wizardBossRoomIndex
    for _, enemy in ipairs(room.enemies or {}) do
        if enemy.name == "cellboss" then
            bossRoomIndex = index
        elseif enemy.name == "wizard" then
            wizardBossRoomIndex = index
        end
    end
    identifier = addPrisonCellBoss(
        replacement,
        reserved,
        identifier,
        index,
        bossRoomIndex
    )
    identifier = addPrisonOfficer(
        replacement,
        reserved,
        identifier,
        index
    )
    identifier = addRoomEnemies(replacement, reserved, identifier, index)
    identifier = addGrassWizard(
        replacement,
        reserved,
        identifier,
        index,
        wizardBossRoomIndex
    )
    identifier = addGrassTurrets(replacement, reserved, identifier, index)
    identifier = addGrassHunters(replacement, reserved, identifier, index)
    identifier = addRuinsEnemies(replacement, reserved, identifier, index)
    addGrassCovers(replacement, reserved, index)
    addGroundHealingItem(replacement, reserved, index)
    assert(getCriticalPaths(replacement, roomBlockers(replacement)),
        "World regeneration produced a room with an unreachable exit")
    return replacement
end

function Util.World.debugRegenerateCurrentRoom()
    if not G or not G.flags.saveData.curRoom or not PLAYER or G.flags.isMoving then
        return false
    end

    local roomIndex = G.flags.saveData.curRoomIndex
    local oldFacing = PLAYER.extra.facing
    local replacement = Util.World.regenerateRoom(G.flags.saveData.curRoom, roomIndex)
    local spawn = replacement.doors[1].a

    local isoGrid = getObjectByNid("isoGrid")
    local isoGridWeb = getObjectByNid("isoGridWeb")
    if isoGrid then isoGrid:remove() end
    if isoGridWeb then isoGridWeb:remove() end

    local worldMoveables = {}
    for _, moveable in ipairs(G.I.MOVEABLES) do
        if moveable.objectType == "WORLDMOVEABLE" then
            worldMoveables[#worldMoveables + 1] = moveable
        end
    end
    for _, moveable in ipairs(worldMoveables) do
        moveable:remove()
    end

    G.flags.saveData.rooms[roomIndex] = replacement
    G.flags.saveData.curRoom = replacement
    G.flags.saveData.playerPos = { x = spawn.x, y = spawn.y }
    G.flags.saveData.playerFacing = oldFacing
    TARGETED_ENEMIES = nil
    for _, item in ipairs(G.flags.saveData.items) do
        item.targets = nil
        item.isBeingUsed = false
    end

    PLAYER = WorldMoveable({
        x = spawn.x,
        y = spawn.y,
        type = "player",
        drawOrder = 31,
        updateOrder = 1,
        extra = { facing = oldFacing },
    })
    Macros.MDef.isometricGrid(
        replacement.size.w,
        replacement.size.h,
        Util.World.getArea(roomIndex)
    )
    WorldMoveable:initRoomStuff()
    PLAYER:checkEaseMusic()

    print("[DEBUG] Regenerated room "..tostring(roomIndex)
        .." as "..tostring(replacement.layout)
        .." ("..replacement.size.w.."x"..replacement.size.h..")")
    return true
end

function Util.World.debugJumpToAreaTransition()
    if not G
        or not G.flags.saveData.curRoom
        or not G.flags.saveData.rooms
        or not PLAYER
        or G.flags.isMoving
        or getEventByNid("transition")
    then
        return false
    end

    local currentIndex = G.flags.saveData.curRoomIndex
    local targetIndex
    if type(currentIndex) == "string" then
        targetIndex = 11
    elseif type(currentIndex) == "number" then
        if currentIndex <= 5 then
            targetIndex = 5
        elseif currentIndex <= 11 then
            targetIndex = 11
        elseif currentIndex <= 17 then
            targetIndex = 17
        end
    end

    local targetRoom = targetIndex
        and G.flags.saveData.rooms[targetIndex]
    if not targetRoom then
        return false
    end
    if currentIndex == targetIndex then
        print("[DEBUG] Already in this area's transition room")
        return true
    end

    local entrance
    for _, door in ipairs(targetRoom.doors or {}) do
        if door.index == targetIndex - 1 then
            entrance = door
            break
        end
    end
    entrance = entrance or targetRoom.doors[1]
    if not entrance or not entrance.a then
        return false
    end

    local isoGrid = getObjectByNid("isoGrid")
    local isoGridWeb = getObjectByNid("isoGridWeb")
    if isoGrid then isoGrid:remove() end
    if isoGridWeb then isoGridWeb:remove() end

    local worldMoveables = {}
    for _, moveable in ipairs(G.I.MOVEABLES) do
        if moveable.objectType == "WORLDMOVEABLE" then
            worldMoveables[#worldMoveables + 1] = moveable
        end
    end
    for _, moveable in ipairs(worldMoveables) do
        moveable:remove()
    end

    TARGETED_ENEMIES = nil
    for _, item in ipairs(G.flags.saveData.items) do
        item.targets = nil
        item.isBeingUsed = false
    end

    local facingByEntrance = {
        tl = "1",
        tr = "4",
        dl = "2",
        dr = "3",
    }
    local facing = facingByEntrance[entrance.side]
        or PLAYER.extra.facing
    local spawn = entrance.a
    G.flags.saveData.curRoomIndex = targetIndex
    G.flags.saveData.curRoom = targetRoom
    G.flags.saveData.playerPos = {x = spawn.x, y = spawn.y}
    G.flags.saveData.playerFacing = facing

    PLAYER = WorldMoveable({
        x = spawn.x,
        y = spawn.y,
        type = "player",
        drawOrder = 31,
        updateOrder = 1,
        extra = {facing = facing},
    })
    Macros.MDef.isometricGrid(
        targetRoom.size.w,
        targetRoom.size.h,
        Util.World.getArea(targetIndex)
    )
    WorldMoveable:initRoomStuff()
    PLAYER:checkEaseMusic()

    print("[DEBUG] Jumped from room "..tostring(currentIndex)
        .." to area transition room "..tostring(targetIndex))
    return true
end

function Util.World.generateRoom(
    type,
    last_side,
    indices,
    getprev,
    index,
    bossRoomIndex,
    wizardBossRoomIndex
)
    local room = {}
    room.size, room.layout = randomRoomSize(index)
    room.enemies = {}
    room.doors = {}
    room.walls = {}
    room.gates = {}
    room.keys = {}
    room.pickups = {}
    room.covers = {}
    local identifier = 1
    if type == "init_room" then
        room.size = { w = 5, h = 5 }
        room.layout = nil
        fillFloor(room)
        local aux = { x = 5, y = 2, a = { x = 4, y = 2 }, index = 2, side = "dr" }

        table.insert(room.doors, aux)

        for i = 0, 4 do
            if i ~= 2 then
                table.insert(room.walls, {
                    name = "prisonBar",
                    type = "wall",
                    x = 2, y = i,
                    dir = 1,
                })
            end
        end
        table.insert(room.enemies, {
            name = "guard",
            pos = {
                2, 2,
            },
            facing = "3",
            id = identifier
        })

        return room
    else
        local r = 1
        if type == "branching" then
            r = 2
        elseif type == "dead_end" then
            r = 0
        end
        local side = Util.World.getOppositeSide(last_side.side)
        local all = table.exclude({ "tl", "tr", "dl", "dr" }, side)
        local doorGenerator = getTransitionRoomConfig(index)
            and generateCenteredAuxDoor
            or generateAuxDoor
        local lastAux = doorGenerator(side, room.size.w, room.size.h, getprev(last_side.index))
        table.insert(room.doors, lastAux)
        for i = 1, r do
            local ttype = getTransitionRoomConfig(index)
                and Util.World.getOppositeSide(side)
                or Util.Math.randomElement(all).v
            all = table.exclude(all, ttype)
            local indice = Util.Math.randomElement(indices).v
            indices = table.exclude(indices, indice)
            table.insert(room.doors, doorGenerator(ttype, room.size.w, room.size.h, indice))
        end

        local reserved = reserveDoorApproaches(room)
        if getTransitionRoomConfig(index) then
            generateTransitionRoom(room, reserved, index)
            assert(getCriticalPaths(room, roomBlockers(room)),
                "World generation produced an unreachable transition room")
            return room
        end
        generateFloorShape(room, reserved, index)
        identifier = addReachableBarrier(room, reserved, identifier, index)
        addPrisonGatePuzzle(room, reserved, index)
        identifier = addPrisonCellBoss(
            room,
            reserved,
            identifier,
            index,
            bossRoomIndex
        )
        identifier = addPrisonOfficer(
            room,
            reserved,
            identifier,
            index
        )
        identifier = addRoomEnemies(room, reserved, identifier, index)
        identifier = addGrassWizard(
            room,
            reserved,
            identifier,
            index,
            wizardBossRoomIndex
        )
        identifier = addGrassTurrets(room, reserved, identifier, index)
        identifier = addGrassHunters(room, reserved, identifier, index)
        identifier = addRuinsEnemies(room, reserved, identifier, index)
        addGrassCovers(room, reserved, index)
        addGroundHealingItem(room, reserved, index)
        assert(getCriticalPaths(room, roomBlockers(room)),
            "World generation produced a room with an unreachable exit")
    end
    return room
end
function Util.World.modTime(m)
    local t = {m} -- stuff it in a table so it's mutable
    CALCULATECONTEXT({modTime = true, time = t})
    G.flags.saveData.timer = G.flags.saveData.timer + t[1]
    if G.flags.saveData.timer >= Macros.maxtime + G.flags.saveData.timemod then
        CALCULATECONTEXT({ death = true, method = "timer" })
        if G.flags.saveData.timer >= Macros.maxtime + G.flags.saveData.timemod then
            Util.World.gameOver()
        end
    end
end

function Util.World.modHP(m)
    local t = { m } -- stuff it in a table so it's mutable
    CALCULATECONTEXT({ modHP = true, hp = t, hurting = PLAYER })
    if t[1] < 0 then
        Util.Audio.playSfx("hit", 2)
        Util.Event.screenShake(2*Util.UI.getScalingFactor(), 0.3, "globalShake")
    elseif t[1] > 0 then
        Util.Audio.playSfx("heal")
    end
    G.flags.saveData.hp = math.min(Macros.maxhp, G.flags.saveData.hp + t[1])
    if G.flags.saveData.hp <= 0 then
        CALCULATECONTEXT({ death = true, method = "hp" })
        if G.flags.saveData.hp <= 0 then
            Util.World.gameOver()
            return true
        end
    end
end
function Util.World.getArea(index)
    if type(index) == "string" then
        return "thorn"
    end
    if index <= 5 then
        return "prison"
    end
    if index == 6 then
        --return "p2g"
        return "grass"
    end
    if index >= 6 and index <= 11 then
        return "grass"
    end
    return "ruins"
end

function Util.World.getEnemy(index)
    if type(index) == "string" then
        return "cellmate"
    end
    if index <= 5 then
        return "cellmate"
    end
    if index >= 6 and index <= 11 then
        return "turret"
    end
    return "skeleton"
end

function Util.World.generateDungeon()
    local rooms = {}
    local main_counter = 1
    local dungeon_counter = 0
    local main_len = 17
    local redirect = love.math.random(8, 10)
    local branch_len = love.math.random(2, 3)
    local prisonBossRooms = {2, 3, 4}
    local prisonBossChance = 1
        - (1 - Macros.cellBoss.spawnChance) ^ #prisonBossRooms
    local bossRoomIndex = Util.Math.chance(prisonBossChance)
        and prisonBossRooms[
            love.math.random(1, #prisonBossRooms)
        ]
        or nil
    local wizardBossRoomIndex = love.math.random(8, 10)
    local alphabet = "abcdefghij"
    local function getprevletter(a)
        return string.char(string.byte(a)-1)
    end
    local function getInfo()
        if main_counter == 1 then
            return {type = "init_room"}
        end
        if main_counter == redirect then
            if dungeon_counter == 0 then
            return {type = "branching", indices = {redirect + 1, "a"}}
            elseif dungeon_counter == branch_len then
                return {type = "dead_end"}
            else
                return { type = "regular", indices = { alphabet:sub(dungeon_counter + 1, dungeon_counter + 1) } }
            end
        end
        return {type = "regular", indices = {main_counter + 1}}
    end
    local function getIndex()
        if dungeon_counter > 0 then
            return alphabet:sub(dungeon_counter, dungeon_counter)
        end
        return main_counter
    end
    local function getPrevIndex(i)
        if type(i) == "number" then
            return i - 1
        elseif i == "a" then
            return redirect
        else
            return getprevletter(i)
        end
    end
    local function incrementCounters()
        if main_counter < redirect then
            main_counter = main_counter + 1
        elseif dungeon_counter < branch_len and dungeon_counter ~= -1 then
            dungeon_counter = dungeon_counter + 1
        else
            dungeon_counter = -1
            main_counter = main_counter + 1
        end
    end
    local last_side
    while main_counter <= main_len do
        local room = Util.World.generateRoom(
            getInfo().type,
            last_side,
            getInfo().indices,
            getPrevIndex,
            getIndex(),
            bossRoomIndex,
            wizardBossRoomIndex
        )
        rooms[getIndex()] = room
        incrementCounters()
        if main_counter == 2 then
            last_side = rooms[1].doors[1]                                                  -- the 1st room only has 1 door, so this is the corresponding last door
        elseif main_counter < main_len then
            local r = rooms[getPrevIndex(getIndex())] -- the previous room
            for k, v in pairs(r.doors) do
                if v.index == getIndex() then
                    last_side = v
                end
            end
        end
    end
    for k, v in ipairs(rooms[17].doors) do
        if v.index == 15 then
            v.index = 16
        end
    end
    return rooms
end
---@param c {[1]:number,[2]:number}
---@return table WorldMoveables
function Util.World.getAllWorldMoveablesWithCoord(c)
    local t = {}
    for k, v in pairs(G.I.MOVEABLES) do
        if v.objectType == "WORLDMOVEABLE" and Util.Math.precisionCheck(v.TMod.x.base, c[1], 0.1) and Util.Math.precisionCheck(v.TMod.y.base, c[2], 0.1) then
            table.insert(t, v)
        end
    end
    return t
end
---@param type string
---@return table WorldMoveables
function Util.World.getAllWorldMoveablesWithType(type)
    local t = {}
    for k, v in pairs(G.I.MOVEABLES) do
        if v.objectType == "WORLDMOVEABLE" and v.properties.type == type then
            table.insert(t, v)
        end
    end
    return t
end
function Util.World.saveGame()
    print("[WORLD] Saving game...")
    local cachedTargets = {}
    for index, item in ipairs(G.flags.saveData.items) do
        if item.targets then
            cachedTargets[index] = item.targets
            item.targets = nil
        end
    end

    local saveSnapshot = Util.Other.copyTable(G.flags.saveData)

    for index, targets in pairs(cachedTargets) do
        G.flags.saveData.items[index].targets = targets
    end

    Util.File.saveTableToFile(saveSnapshot, "runInfo")
end
function Util.World.loadGame()
    print("[WORLD] Loading game...")
    Util.File.setTableWithFile(G.flags.saveData, "runInfo")
end
function getAllValidVertices(www, hhh, blockades)
    blockades = blockades or { "wall" }
    local vertices = {}
    for x = 0, www - 1 do
        vertices[x] = {}
        for y = 0, hhh - 1 do
            local worldMoveables = Util.World.getAllWorldMoveablesWithCoord({ x, y })
            local hasblockade = false
            for k, v in ipairs(worldMoveables) do
                if v.properties.type == "gate" and v.extra.locked then
                    hasblockade = true
                    break
                end
                for kk, vv in ipairs(blockades) do
                    if v.properties.type == vv then
                        hasblockade = true
                        break
                    end
                end
            end
            if Util.World.isFloor(G.flags.saveData.curRoom, x, y) and not hasblockade then
                vertices[x][y] = true
            end
        end
    end
    local doors = Util.World.getAllWorldMoveablesWithType("door")
    for k, door in ipairs(doors) do
        if not vertices[door.TMod.x.base] then
            vertices[door.TMod.x.base] = {}
        end
        vertices[door.TMod.x.base][door.TMod.y.base] = true
    end
    return vertices
end

function isValidVertice(v, c)
    if v[Util.Math.round(c[1])] and v[Util.Math.round(c[1])][Util.Math.round(c[2])] then
        return true
    end
    return false
end

function getAllAdjacentVertices(v, c)
    local vs = {}
    local cCopy = { Util.Math.round(c[1]), Util.Math.round(c[2]) }
    if v[cCopy[1]] then
        if v[cCopy[1]][cCopy[2] - 1] then
            table.insert(vs, { cCopy[1], cCopy[2] - 1 })
        end
        if v[cCopy[1]][cCopy[2] + 1] then
            table.insert(vs, { cCopy[1], cCopy[2] + 1 })
        end
    end
    if v[cCopy[1] + 1] then
        if v[cCopy[1] + 1][cCopy[2]] then
            table.insert(vs, { cCopy[1] + 1, cCopy[2] })
        end
    end
    if v[cCopy[1] - 1] then
        if v[cCopy[1] - 1][cCopy[2]] then
            table.insert(vs, { cCopy[1] - 1, cCopy[2] })
        end
    end
    return vs
end
Util.World.getDir = function (s)
    if #s == 1 then
        return false
    end
    local a, b = s[1].coords, s[2].coords
    if a[1] > b[1] then
        return "1"
    elseif a[1] < b[1] then
        return "3"
    elseif a[2] > b[2] then
        return "4"
    else
        return "2"
    end
end

function Util.World.gameOver()
    for k, v in ipairs(G.audio.music) do
        v.source:stop()
        v.source:release()
    end
    G = Game()
    love.filesystem.remove("runInfo.con")
    Macros.CDefs.Death()
end
function Util.World.gameWin()
    if not getEventByNid("end1") then
        for k, v in ipairs(G.audio.music) do
            v.source:stop()
            v.source:release()
        end
        G.audio = {
            sfx = {},
            music = {},
            musicHandler = {}
        }
        love.filesystem.remove("runInfo.con")
        local data = Util.Other.copyTable(G.flags.saveData)
        Util.Event.addEvent(Event(
            {
                drawOrder = 1e33,
                duration = 3,
                nid = "end1",
                drawFunc = function (t)
                    love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.white, t))
                    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
                end,
                endFunc = function()
                    local s = Util.Audio.musicPush("ambience", "ambienceID", "ambience", 1, 1, 1, { looping = true })
                    Macros.CDefs.Win(s, data)
                    Util.Event.addEvent(Event(
                        {
                            nid = "end",
                            drawOrder = 1e33,
                            duration = 5,
                            drawFunc = function(t)
                                love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.white, 1 - t))
                                love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
                            end
                        }
                    ), "endOfGame")
                
            end
            }
        ),"endOfGame")
    end
end

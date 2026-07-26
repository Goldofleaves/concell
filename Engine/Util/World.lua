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

local function generateFloorShape(room, reserved)
    if room.layout == "maze" then
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

local function addReachableBarrier(room, reserved, identifier)
    if room.layout == "maze" then
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

local function addRoomEnemies(room, reserved, identifier, index)
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

    for _ = 1, math.min(3, #candidates) do
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

local function randomRoomSize()
    if Util.Math.chance(7 / 25) then
        local longSide = love.math.random(8, 10)
        if Util.Math.chance(1 / 2) then
            return { w = 7, h = longSide }, "maze"
        end
        return { w = longSide, h = 7 }, "maze"
    end

    local largerRoom = Util.Math.chance(1 / 3)
    local shortSide = largerRoom and love.math.random(5, 7) or love.math.random(4, 6)
    local longSide = largerRoom and love.math.random(8, 10) or love.math.random(7, 9)
    if Util.Math.chance(1 / 2) then
        return { w = shortSide, h = longSide }, nil
    end
    return { w = longSide, h = shortSide }, nil
end

function Util.World.regenerateRoom(room, index)
    local size, layout = randomRoomSize()
    local replacement = {
        size = size,
        layout = layout,
        enemies = {},
        doors = {},
        walls = {},
    }

    for _, door in ipairs(room.doors) do
        replacement.doors[#replacement.doors + 1] = generateAuxDoor(
            door.side,
            replacement.size.w,
            replacement.size.h,
            door.index
        )
    end

    local reserved = reserveDoorApproaches(replacement)
    generateFloorShape(replacement, reserved)
    local identifier = addReachableBarrier(replacement, reserved, 1)
    addRoomEnemies(replacement, reserved, identifier, index)
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

function Util.World.generateRoom(type, last_side, indices, getprev, index)
    local room = {}
    room.size, room.layout = randomRoomSize()
    room.enemies = {}
    room.doors = {}
    room.walls = {}
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
        local lastAux = generateAuxDoor(side, room.size.w, room.size.h, getprev(last_side.index))
        table.insert(room.doors, lastAux)
        for i = 1, r do
            local ttype = Util.Math.randomElement(all).v
            all = table.exclude(all, ttype)
            local indice = Util.Math.randomElement(indices).v
            indices = table.exclude(indices, indice)
            table.insert(room.doors, generateAuxDoor(ttype, room.size.w, room.size.h, indice))
        end

        local reserved = reserveDoorApproaches(room)
        generateFloorShape(room, reserved)
        identifier = addReachableBarrier(room, reserved, identifier)
        addRoomEnemies(room, reserved, identifier, index)
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
    Util.Audio.playSfx("hit", 2)
    Util.Event.screenShake(2*Util.UI.getScalingFactor(), 0.3, "globalShake")
    G.flags.saveData.hp = G.flags.saveData.hp + t[1]
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
    if index == 12 then
        return "f2r"
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
    if index == 6 then
        return Util.Math.chance(1/2) and "cellmate" or "turret"
    end
    if index >= 6 and index <= 11 then
        return "turret"
    end
    if index == 12 then
        return "turret"
    end
    return "cellmate"
end

function Util.World.generateDungeon()
    local rooms = {}
    local main_counter = 1
    local dungeon_counter = 0
    local main_len = 17
    local redirect = love.math.random(8, 10)
    local branch_len = love.math.random(2, 3)
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
        local room = Util.World.generateRoom(getInfo().type, last_side, getInfo().indices, getPrevIndex, getIndex())
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
    print(G.flags.saveData)
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
    print(G.flags.saveData)
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
    G = nil
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

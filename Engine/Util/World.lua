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
    local offset = Vector(G.drawinfo.origin.x, G.drawinfo.origin.y):add(G.worldOffsetVector, true)
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

local function generateAuxDoor(side, w, h, index)
    local aux = {}
    local r = love.math.random(1, h - 1)
    local g = love.math.random(1, w - 1)
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
function Util.World.generateRoom(type, last_side, indices, getprev)
    local room = {}
    local a, b = love.math.random(4, 6), love.math.random(7, 9)
    local coin_flip = Util.Math.chance(1/2)
    if coin_flip then
        room.size = { w = a, h = b }
    else
        room.size = { w = b, h = a }
    end
    room.enemies = {}
    room.doors = {}
    local r = 1
    if type == "branching" then
        r = 2
    elseif type == "init_room" then
        local side = Util.Math.randomElement({"tl", "tr", "dl", "dr"}).v
        local aux = generateAuxDoor(side, room.size.w, room.size.h, 2)
        table.insert(room.doors, aux)
        return room
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
    return room
end
function Util.World.modTime(m)
    G.flags.saveData.timer = G.flags.saveData.timer + m
end
function Util.World.getArea(index)
    if index <= 5 then
        return "prison"
    end
    if index == 6 then
        --return "p2g"
        return "grass"
    end
    if index > 6 and index <= 11 then
        return "grass"
    end
    if index == 12 then
        return "f2r"
    end
    if type(index) == "string" then
        return "thorn"
    end
    return "ruins"
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
        local array = {
            j = "i",
            i = "h",
            h = "g",
            g = "f",
            f = "e",
            e = "d",
            d = "c",
            c = "b",
            b = "a"
        }
        return array[a]
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
        local room = Util.World.generateRoom(getInfo().type, last_side, getInfo().indices, getPrevIndex)
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

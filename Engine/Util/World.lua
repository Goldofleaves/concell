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
    room.walls = {}
    lookup = {
        a = {},
        b = {}
    }
    local function getUniqueRandom(queue, min, max, cond)
        local result = love.math.random(min, max)
        if not lookup[queue][result] and cond(result) then
            lookup[queue][result] = true
            return result
        else
            return getUniqueRandom(queue, min, max, cond)
        end
    end
    local identifier = 1
    if type == "init_room" then
        a, b = 5, 5
        room.size = { w = a, h = b }
        local aux = { x = 5, y = 2, a = { x = 4, y = 2 }, index = 2, side = "dr" }

        table.insert(room.doors, aux)

        for i = 0, 4 do
            if i ~= 2 then
                table.insert(room.walls, {
                    name = "prisonBar",
                    type = "wall",
                    x = 2, y = i
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
        for _ = 1, 3 do -- temp 3 enemies per room
            table.insert(room.enemies, {
                name = "turret", -- every enemy is of cellmate kind
                pos = {
                    getUniqueRandom("a", 0, room.size.w - 1, function(r) return r ~= math.floor(room.size.w / 2) end),
                    getUniqueRandom("b", 0, room.size.h - 1, function(r) return r ~= math.floor(room.size.h / 2) end),
                },
                facing = tostring(math.random(1, 4)),
                id = identifier
            })
            identifier = identifier + 1
        end
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
    Util.Event.screenShake(2*Util.UI.getScalingFactor(), 0.5, "globalShake")
    G.flags.saveData.hp = G.flags.saveData.hp + t[1]
    if G.flags.saveData.hp <= 0 then
        CALCULATECONTEXT({ death = true, method = "hp" })
        if G.flags.saveData.hp <= 0 then
            Util.World.gameOver()
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
    Util.File.saveTableToFile(G.flags.saveData, "runInfo")
end
function Util.World.loadGame()
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
                    end
                end
            end
            if not hasblockade then
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
    local function remove()
        local t = false
        for k, v in pairs(G.I) do
            for kk, vv in ipairs(v) do
                if vv.remove then vv:remove(true) end
                t = true
            end
        end
        if t then
            remove()
        end
    end
    remove()
    love.filesystem.remove("runInfo.con")
    for k, v in ipairs(G.audio.music) do
        v.source:stop()
        v.source:release()
    end
    G = nil
    G = Game()
    Macros.CDefs.Death()
end
function Util.World.gameWin()
    local function remove()
        local t = false
        for k, v in pairs(G.I) do
            for kk, vv in ipairs(v) do
                if vv.remove then vv:remove(true) end
                t = true
            end
        end
        if t then
            remove()
        end
    end
    remove()
    love.filesystem.remove("runInfo.con")
    for k, v in ipairs(G.audio.music) do
        v.source:stop()
        v.source:release()
    end
    G = nil
    G = Game()
    Util.Audio.musicPush("ambience", "ambienceID", "ambience", 1, 1, 1, { looping = true })
    Macros.CDefs.Win()
end

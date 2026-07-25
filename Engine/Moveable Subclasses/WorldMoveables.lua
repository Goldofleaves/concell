WorldMoveable = Moveable:extend()
function WorldMoveable:new(args)
    Moveable.new(self, args)
    self.objectType = "WORLDMOVEABLE"
    self.properties.type = args.type or "door"
    self.properties.mult = 1
    return self
end
function WorldMoveable:juice(r)
    r = r or 2
    Util.Event.addEvent(
        Event({
            duration = 0.3,
            easeFunc = function (t, s)
                self.properties.mult = Util.EaseSplines.createEase(r, 1, nil, {preset = "eoc"})(t)
            end,
            endFunc = function(s)
                self.properties.mult = 1
            end
        }),"juice"..self.id
    )
end
function WorldMoveable:draw()
    Moveable.draw(self)
    local lookup = {
        door = {
            color = Macros.colors.transparent,
            radius = 5 * self.properties.mult
        },
        player = {
            color = Macros.colors.red,
            radius = 5 * self.properties.mult
        },
        enemy = {
            color = Macros.colors.transparent,
            radius = 5 * self.properties.mult
        },
        wall = {
            color = Macros.colors.transparent,
            radius = 7 * self.properties.mult
        },
    }
    local r, g, b, a = love.graphics.getColor()
    local vector = Util.World.toIsoPos(Vector(self.TMod.x.base + 0.2, self.TMod.y.base + 0.2))
    love.graphics.setColor(lookup[self.properties.type].color)
    if self.properties.type == "enemy" and self.extra.goalVertice then
        local goalVector = Util.World.toIsoPos(Vector(self.extra.goalVertice[1] + 0.2, self.extra.goalVertice[2] + 0.2))
        love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.darkGreen, 0.7))
        love.graphics.setLineWidth(2.5 * Util.UI.getScalingFactor())
        love.graphics.line(vector.contents[1], vector.contents[2], goalVector.contents[1], goalVector.contents[2])
        love.graphics.setLineWidth(1.5 * Util.UI.getScalingFactor())
        love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.green, 0.7))
        love.graphics.circle("fill", goalVector.contents[1], goalVector.contents[2], lookup[self.properties.type].radius / 5 * 3 * Util.UI.getScalingFactor())
    end
    love.graphics.circle("fill", vector.contents[1], vector.contents[2], lookup[self.properties.type].radius*Util.UI.getScalingFactor())
    if self.properties.type == "door" then
        love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.white,0.67))
        local v = Util.World.toIsoPos(Vector(self.TMod.x.base, self.TMod.y.base))
        love.graphics.draw(
            Atlases.Door.image,
            Atlases.Door.splicedImages[0][0],
            v.contents[1] - 40 * Util.UI.getScalingFactor(),
            v.contents[2] - 80 * Util.UI.getScalingFactor(),
            0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
        )
    end
    if self.properties.type == "wall" or self.properties.type == "enemy" then
        love.graphics.setColor(Macros.colors.white)
        local v = Util.World.toIsoPos(Vector(self.TMod.x.base, self.TMod.y.base))
        love.graphics.draw(
            Atlases[self.extra.name].image,
            Atlases[self.extra.name].splicedImages[0][0],
            v.contents[1] - 40 * Util.UI.getScalingFactor(),
            v.contents[2] - 80 * Util.UI.getScalingFactor(),
            0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
        )
    end
    love.graphics.setColor(r,g,b,a)
end
function WorldMoveable:update(dt)
    Moveable.update(self, dt)
    self.drawOrder = self.TMod.x.base + self.TMod.y.base + 10
end
function WorldMoveable:switchRoom()
    if self.properties.type == "door" then
        Util.Event.transition(2, function()
            G.flags.saveData.curRoomIndex = self.extra.index
            G.flags.saveData.curRoom = G.flags.saveData.rooms[self.extra.index]
            getObjectByNid("isoGrid"):remove()
            getObjectByNid("isoGridWeb"):remove()
            Macros.MDef.isometricGrid(G.flags.saveData.curRoom.size.w, G.flags.saveData.curRoom.size.h,
            Util.World.getArea(self.extra.index))
            local list = {}
            for k, v in ipairs(G.I.MOVEABLES) do
                if v.objectType == "WORLDMOVEABLE" then
                    table.insert(list, v)
                end
            end
            for k, v in ipairs(list) do
                v:remove()
            end
            PLAYER = WorldMoveable({
                x = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra.side)).x,
                y = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra.side)).y,
                type = "player",
                drawOrder = 31,
                updateOrder = 1
            })
            WorldMoveable:initRoomStuff()
            G.flags.saveData.playerPos = { x = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra
            .side)).x, y = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra.side)).y }
            Util.World.saveGame()
        end, "delay2")
    end
end
function WorldMoveable:decideMove()
    if self.properties.type == "enemy" then
        if self.extra.name == "guard" then return nil end
        local vertices = getAllValidVertices(G.flags.saveData.curRoom.size.w, G.flags.saveData.curRoom.size.h, {"wall", "enemy", "door"})
        local adjacents = getAllAdjacentVertices(vertices, {self.TMod.x.base,self.TMod.y.base})
        while next(adjacents) do
            local randomAdjacent = Util.Math.randomElement(adjacents).v
            adjacents = table.exclude(adjacents, randomAdjacent)
            local allEnemies = Util.World.getAllWorldMoveablesWithType("enemy")
            local hassamevertice = false
            for k,v in ipairs(allEnemies) do
                if v.extra.goalVertice and v.extra.goalVertice[1] == randomAdjacent[1] and v.extra.goalVertice[2] == randomAdjacent[2] then
                    hassamevertice = true
                end
            end
            if not hassamevertice then
                self.extra.goalVertice = randomAdjacent
            end
        end
    end
end
function WorldMoveable:initRoomStuff()
    for k, v in ipairs(G.flags.saveData.curRoom.enemies) do
        local j = WorldMoveable({
            x = v.pos[1],
            y = v.pos[2],
            type = "enemy",
            extra = {
                index = v.index,
                side = v.side,
                name = v.name,
            },
            updateOrder = 2,
            drawOrder = 10
        })
        j:decideMove()
    end
    for k, v in ipairs(G.flags.saveData.curRoom.doors) do
        WorldMoveable({
            x = v.x,
            y = v.y,
            type = "door",
            extra = {
                index = v.index,
                side = v.side,
                name = v.name,
            },
            updateOrder = 2,
            drawOrder = 30
        })
    end
    for k, v in ipairs(G.flags.saveData.curRoom.walls) do
        WorldMoveable({
            x = v.x,
            y = v.y,
            type = "wall",
            extra = {
                index = v.index,
                side = v.side,
                name = v.name,
            },
            updateOrder = 2,
            drawOrder = 11
        })
    end
end
WorldMoveable = Moveable:extend()
function WorldMoveable:new(args)
    Moveable.new(self, args)
    self.objectType = "WORLDMOVEABLE"
    self.properties.type = args.type or "door"
    self.properties.mult = 1
    return self
end

local IN_COMBAT = false

function WorldMoveable:checkEaseMusic()
    local should_be_in_combat = false
    for _, enemy in ipairs(Util.World.getAllWorldMoveablesWithType("enemy")) do
        if enemy.extra and enemy.extra.hp > 0 then
            if enemy.properties.name == "guard" then
                return nil
            end
            should_be_in_combat = true
        end
    end
    if should_be_in_combat and not IN_COMBAT then
        IN_COMBAT = true
        Util.Audio.musicPush("battle", "battleID", "normal", 3, 1, 1)
    elseif not should_be_in_combat and IN_COMBAT then
        IN_COMBAT = false
        Util.Audio.musicPop("battleID")
    end
end

function WorldMoveable:modHP(m, silent)
    if self.properties.type == "enemy" then
        local t = {m}
        CALCULATECONTEXT({ modHP = true, hp = t, hurting = self })
        self.extra.hp = self.extra.hp + t[1]
        if t[1] < 0 then
            G.flags.saveData.totalDamage = G.flags.saveData.totalDamage - t[1]
        end
        if self.extra.hp <= 0 then
            Util.Event.screenShake(5 * Util.UI.getScalingFactor(), 0.5, "localShake" .. self.id)
            Util.Audio.playSfx("fatalhit", 2)
            for k, v in ipairs(G.flags.saveData.curRoom.enemies) do
                if v.id == self.extra.identifier then
                    table.remove(G.flags.saveData.curRoom.enemies, k)
                end
            end
            G.flags.saveData.enemiesSlain = G.flags.saveData.enemiesSlain + 1
            WorldMoveable:checkEaseMusic()
            self:remove()
        else
            Util.Event.screenShake(2 * Util.UI.getScalingFactor(), 0.5, "localShake" .. self.id)
            if not silent then
                Util.Audio.playSfx("hit", 2)
            end
        end
    end
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
            color = Macros.colors.transparent,
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
    if self.properties.type == "enemy" and TARGETED_ENEMIES then
        for _, t in ipairs(TARGETED_ENEMIES) do
            if t == self then
                love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.white,0.67))
                local v = Util.World.toIsoPos(Vector(self.TMod.x.base, self.TMod.y.base))
                love.graphics.draw(
                    Atlases.Target.image,
                    Atlases.Target.splicedImages[0][0],
                    v.contents[1] - 40 * Util.UI.getScalingFactor(),
                    v.contents[2] - 80 * Util.UI.getScalingFactor(),
                    0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
                )
                break
            end
        end
    end
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
    -- Util.World.getDir
    if self.properties.type == "wall" then
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
    if self.properties.type == "enemy" then
        love.graphics.setColor(Macros.colors.white)
        local v = Util.World.toIsoPos(Vector(self.TMod.x.base, self.TMod.y.base))
        if Atlases[self.extra.name .. self.extra.facing] and Atlases[self.extra.name .. self.extra.facing].image then
            love.graphics.draw(
                Atlases[self.extra.name..self.extra.facing].image,
                Atlases[self.extra.name..self.extra.facing].splicedImages[0][0],
                v.contents[1] - 40 * Util.UI.getScalingFactor(),
                v.contents[2] - 80 * Util.UI.getScalingFactor(),
                0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
            )
        end
        love.graphics.push()
        love.graphics.translate(0, -14 * Util.UI.getScalingFactor())
        love.graphics.draw(
            Atlases.hpSymbol.image,
            Atlases.hpSymbol.splicedImages[0][0],
            v.contents[1] - 30 * Util.UI.getScalingFactor(),
            v.contents[2] - 80 * Util.UI.getScalingFactor(),
            0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
        )
        love.graphics.setColor(Macros.colors.night)
        love.graphics.rectangle("fill", v.contents[1] - 14 * Util.UI.getScalingFactor(),
            v.contents[2] - 76 * Util.UI.getScalingFactor(),
            44 * Util.UI.getScalingFactor(), 14 * Util.UI.getScalingFactor())
        local delta = 40 * Util.UI.getScalingFactor() * self.extra.hp / Macros.maxHps[self.extra.name]
        love.graphics.setColor(Macros.colors.red)
        love.graphics.rectangle("fill", v.contents[1] - 12 * Util.UI.getScalingFactor(),
            v.contents[2] - 74 * Util.UI.getScalingFactor(),
            delta, 10 * Util.UI.getScalingFactor())
        local txt = AdvancedText("|o:night||c:red||s:2,2|" .. self.extra.hp .. "/" .. Macros.maxHps[self.extra.name])
        txt:draw(v.contents[1] - txt:getTotalWidth() / 2,
        v.contents[2] - 60 * Util.UI.getScalingFactor())
        
        local name = AdvancedText("|o:night||s:2,2|" .. Macros.names[self.extra.name])
        name:draw(v.contents[1] - name:getTotalWidth() / 2,
        v.contents[2] - 92 * Util.UI.getScalingFactor())
        love.graphics.pop()
        -- Enemy names (SERIOUSLY GUYS, PLS COMMENT YOUR CODE WHY AM I THE ONLY ONE DOING IT)
    end
    if self.properties.type == "player" then
        love.graphics.setColor(Macros.colors.white)
        local v = Util.World.toIsoPos(Vector(self.TMod.x.base, self.TMod.y.base))
        love.graphics.draw(
            Atlases["dawn"..self.extra.facing].image,
            Atlases["dawn"..self.extra.facing].splicedImages[0][0],
            v.contents[1] - 40 * Util.UI.getScalingFactor(),
            v.contents[2] - 80 * Util.UI.getScalingFactor(),
            0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
        )
    end
    love.graphics.setColor(r,g,b,a)
end
function WorldMoveable:update(dt)
    Moveable.update(self, dt)
    self.drawOrder = self.TMod.x.base + self.TMod.y.base + 12 + (self.properties.type == "door" and -.5 or 0)
    -- self:decideMove()
end
function move_all_enemies()
    local allEnemies = Util.World.getAllWorldMoveablesWithType("enemy")
    for k, v in ipairs(allEnemies) do
        if v.extra.goalVertice then
            if v.extra.goalVertice[1] ~= PLAYER.TMod.x.base or v.extra.goalVertice[2] ~= PLAYER.TMod.y.base then
                v.extra.facing = Util.World.getDir({{coords = {v.TMod.x.base, v.TMod.y.base}}, {coords = v.extra.goalVertice}})
                v.TMod.x.base = v.extra.goalVertice[1]
                v.TMod.y.base = v.extra.goalVertice[2]
            else
                Util.World.modHP(-2)
            end
            v.extra.goalVertice = nil
            v:juice()
        end
    end
    for k, v in ipairs(allEnemies) do
        v:decideMove()
    end
end
function WorldMoveable:switchRoom()
    if self.extra.index == 18 then
        Util.World.gameWin()
        return
    end
    if self.properties.type == "door" then
        Util.Event.transition(2, function()
            local old_facing = PLAYER.extra.facing
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
            local convert = function(s)
                local array = {
                    tl = '1',
                    tr = '4',
                    dl = '2',
                    dr = '3'
                }
                return array[s]
            end
            PLAYER = WorldMoveable({
                x = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra.side)).x,
                y = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra.side)).y,
                type = "player",
                drawOrder = 31,
                updateOrder = 1,
                extra = {facing = old_facing}
            })
            WorldMoveable:initRoomStuff()
            G.flags.saveData.playerPos = { x = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra
            .side)).x, y = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra.side)).y }
            G.flags.saveData.playerFacing = convert(Util.World.getOppositeSide(self.extra.side))
            self:checkEaseMusic()
            Util.World.saveGame()
        end, "delay2")
    end
end
function WorldMoveable:decideMove()
    if self.properties.type == "enemy" then
        if self.extra.name == "guard" then return nil end
        if self.extra.name == "turret" then return nil end
        local vertices = getAllValidVertices(G.flags.saveData.curRoom.size.w, G.flags.saveData.curRoom.size.h, {"wall", "enemy", "door"})
        local adjacents = getAllAdjacentVertices(vertices, {self.TMod.x.base,self.TMod.y.base})
        table.sort(adjacents, function (a, b)
            local v = Vector(PLAYER.TMod.x.base, PLAYER.TMod.y.base)
            local va, vb = Vector(a[1], a[2]):sub(v, true), Vector(b[1], b[2]):sub(v, true)
            return va:abs() < vb:abs()
        end)
        while #adjacents > 1 do
            adjacent = adjacents[1]
            table.remove(adjacents, 1)
            local allEnemies = Util.World.getAllWorldMoveablesWithType("enemy")
            local hassamevertice = false
            for k,v in ipairs(allEnemies) do
                if  v ~= self and v.extra.goalVertice and v.extra.goalVertice[1] == adjacent[1] and v.extra.goalVertice[2] == adjacent[2] then
                    hassamevertice = true
                    break
                end
            end
            if not hassamevertice then
                self.extra.goalVertice = {adjacent[1], adjacent[2]}
                return
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
                hp = Macros.maxHps[v.name],
                facing = v.facing,
                identifier = v.id
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
WorldMoveable = Moveable:extend()
function WorldMoveable:new(args)
    Moveable.new(self, args)
    self.objectType = "WORLDMOVEABLE"
    self.properties.type = args.type or "door"
    self.properties.mult = 1
    return self
end

local IN_COMBAT = false

local ITEM_DROP_EXCLUSIONS = {
    knife = true,
    prison_key = true,
}

local function getEnemyRoomRecord(enemy)
    if not G or not G.flags.saveData.curRoom then
        return nil
    end
    for _, record in ipairs(G.flags.saveData.curRoom.enemies or {}) do
        if record.id == enemy.extra.identifier then
            return record
        end
    end
end

function Util.World.spawnGroundItemPickup(itemKey, x, y, requiresPlayerExit)
    local saveData = G.flags.saveData
    local room = saveData.curRoom
    room.pickups = room.pickups or {}
    saveData.nextPickupId = saveData.nextPickupId or 1
    local identifier = "pickup"..tostring(saveData.nextPickupId)
    saveData.nextPickupId = saveData.nextPickupId + 1
    room.pickups[#room.pickups + 1] = {
        id = identifier,
        x = x,
        y = y,
        itemKey = itemKey,
        requiresPlayerExit = requiresPlayerExit == true,
    }
    return WorldMoveable({
        x = x,
        y = y,
        type = "pickup",
        extra = {
            itemKey = itemKey,
            identifier = identifier,
            collection = "pickups",
            requiresPlayerExit = requiresPlayerExit == true,
        },
        updateOrder = 2,
        drawOrder = 10,
    })
end

local function spawnEnemyItemDrop(x, y)
    local saveData = G.flags.saveData
    saveData.nextItemDropAt = saveData.nextItemDropAt
        or love.math.random(4, 6)
    if saveData.enemiesSlain < saveData.nextItemDropAt then
        return
    end

    saveData.nextItemDropAt = saveData.nextItemDropAt
        + love.math.random(4, 6)
    local itemKey = poolItem(nil, ITEM_DROP_EXCLUSIONS)
    if not itemKey then
        return
    end

    Util.World.spawnGroundItemPickup(itemKey, x, y, false)
end

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
        WorldMoveable:onRoomClear()
    end
end

function WorldMoveable:modHP(m, silent)
    if self.properties.type == "enemy" then
        if self.extra.name == "skeleton"
            and self.extra.downedTurns
            and m < 0
        then
            return
        end
        local t = {m}
        CALCULATECONTEXT({ modHP = true, hp = t, hurting = self })
        self.extra.hp = math.min(self.extra.hp + t[1], Macros.maxHps[self.extra.name])
        local roomRecord = getEnemyRoomRecord(self)
        if roomRecord and self.extra.name == "skeleton" then
            roomRecord.hp = self.extra.hp
        end
        if t[1] < 0 then
            G.flags.saveData.totalDamage = G.flags.saveData.totalDamage - t[1]
            if self.extra.hp <= 0 then
                CALCULATECONTEXT({ enemyKill = true, enemy = self })
                Util.Event.screenShake(5 * Util.UI.getScalingFactor(), 0.5, "localShake" .. self.id)
                Util.Audio.playSfx("fatalhit", 2)
                if self.extra.name == "skeleton" then
                    self.extra.hp = 0
                    self.extra.downedTurns = Macros.skeleton.downedTurns
                    self.extra.justDowned = true
                    self.extra.goalVertice = nil
                    self.extra.goalPath = nil
                    if not self.extra.killCredited then
                        self.extra.killCredited = true
                        G.flags.saveData.enemiesSlain =
                            G.flags.saveData.enemiesSlain + 1
                        spawnEnemyItemDrop(self.TMod.x.base, self.TMod.y.base)
                    end
                    if roomRecord then
                        roomRecord.hp = 0
                        roomRecord.downedTurns = self.extra.downedTurns
                        roomRecord.killCredited = self.extra.killCredited
                    end
                    WorldMoveable:checkEaseMusic()
                    return
                end
                if self.extra.name == "cellboss" then
                    self:clearCellBossDanger()
                end
                if self.extra.name == "elite"
                    or self.extra.name == "abraham"
                then
                    self:clearEliteDanger()
                end
                if self.extra.name == "wizard" then
                    self:clearWizardDanger()
                    self.extra.wizardAction = nil
                    self.extra.goalVertice = nil
                    self.extra.goalPath = nil
                end
                for k, v in ipairs(G.flags.saveData.curRoom.enemies) do
                    if v.id == self.extra.identifier then
                        table.remove(G.flags.saveData.curRoom.enemies, k)
                    end
                end
                G.flags.saveData.enemiesSlain = G.flags.saveData.enemiesSlain + 1
                spawnEnemyItemDrop(self.TMod.x.base, self.TMod.y.base)
                WorldMoveable:checkEaseMusic()
                self:remove()
            else
                Util.Event.screenShake(2 * Util.UI.getScalingFactor(), 0.5, "localShake" .. self.id)
                if not silent then
                    Util.Audio.playSfx("hit", 2)
                end
            end
        elseif t[1] > 0 then
            if not silent then
                Util.Audio.playSfx("heal")
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

function WorldMoveable:getVisualGridPosition()
    return self.extra.visualGridX or self.TMod.x.base,
        self.extra.visualGridY or self.TMod.y.base
end

function WorldMoveable:moveToGrid(x, y, duration)
    local startX, startY = self:getVisualGridPosition()
    self.TMod.x.base = x
    self.TMod.y.base = y

    duration = duration or 0.22
    if duration <= 0 or (startX == x and startY == y) then
        self.extra.gridMove = nil
        self.extra.visualGridX = nil
        self.extra.visualGridY = nil
        return
    end

    self.extra.visualGridX = startX
    self.extra.visualGridY = startY
    self.extra.gridMove = {
        elapsed = 0,
        duration = duration,
        ease = Util.EaseSplines.createEase(
            { x = startX, y = startY },
            { x = x, y = y },
            nil,
            { preset = "eoc" }
        ),
    }
end

function WorldMoveable:moveAlongGridPath(path, durationPerTile)
    if not path or #path == 0 then
        return
    end

    local startX, startY = self:getVisualGridPosition()
    local points = {{startX, startY}}
    for _, position in ipairs(path) do
        points[#points + 1] = {position[1], position[2]}
    end

    local eases = {}
    for index = 1, #points - 1 do
        eases[index] = Util.EaseSplines.createEase(
            {x = points[index][1], y = points[index][2]},
            {x = points[index + 1][1], y = points[index + 1][2]},
            nil,
            {preset = "eoc"}
        )
    end

    local destination = path[#path]
    self.TMod.x.base = destination[1]
    self.TMod.y.base = destination[2]
    self.extra.visualGridX = startX
    self.extra.visualGridY = startY
    self.extra.gridMove = {
        elapsed = 0,
        duration = math.max(0.01, (durationPerTile or 0.14) * #path),
        eases = eases,
    }
end

local function drawWorldTileAtlas(atlasKey, x, y)
    local position = Util.World.toIsoPos(Vector(x, y))
    love.graphics.draw(
        Atlases[atlasKey].image,
        Atlases[atlasKey].splicedImages[0][0],
        position.contents[1] - 40 * Util.UI.getScalingFactor(),
        position.contents[2] - 80 * Util.UI.getScalingFactor(),
        0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
    )
end

local function drawPixelLockedLine(fromX, fromY, toX, toY)
    love.graphics.setLineWidth(2)
    love.graphics.line(
        math.floor(fromX + 0.5),
        math.floor(fromY + 0.5),
        math.floor(toX + 0.5),
        math.floor(toY + 0.5)
    )
end

local TURRET_AIM_ORIGIN_OFFSETS = {
    ["1"] = {-14, -32},
    ["2"] = {-12, -26},
    ["3"] = {10, -26},
    ["4"] = {12, -32},
}

local RANGED_ENEMY_NAMES = {
    hunter = true,
    officer = true,
    elite = true,
    abraham = true,
}

local function isRangedEnemyName(name)
    return RANGED_ENEMY_NAMES[name] == true
end

local function getEnemyAimOrigin(enemy, gridX, gridY)
    local position = Util.World.toIsoPos(Vector(gridX, gridY))
    local offset = enemy.extra.name == "turret"
        and TURRET_AIM_ORIGIN_OFFSETS[enemy.extra.facing]
    local scale = Util.UI.getScalingFactor()
    if offset then
        return position.contents[1] + offset[1] * scale,
            position.contents[2] + offset[2] * scale
    end
    return position.contents[1],
        position.contents[2] - 30 * scale
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
        gate = {
            color = Macros.colors.transparent,
            radius = 7 * self.properties.mult
        },
        pickup = {
            color = Macros.colors.transparent,
            radius = 5 * self.properties.mult
        },
        cover = {
            color = Macros.colors.transparent,
            radius = 7 * self.properties.mult
        },
        danger = {
            color = Macros.colors.transparent,
            radius = 5 * self.properties.mult
        },
    }
    local r, g, b, a = love.graphics.getColor()
    local visualX, visualY = self:getVisualGridPosition()
    local vector = Util.World.toIsoPos(Vector(visualX + 0.2, visualY + 0.2))
    love.graphics.setColor(lookup[self.properties.type].color)
    if (self.properties.type == "enemy" or self.properties.type == "gate") and TARGETED_ENEMIES then
        for _, t in ipairs(TARGETED_ENEMIES) do
            if t == self then
                love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.white,0.67))
                local v = Util.World.toIsoPos(Vector(visualX, visualY))
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
        local predictedPlayerX = PLAYER.TMod.x.base
        local predictedPlayerY = PLAYER.TMod.y.base
        local grid = getObjectByNid("isoGridWeb")
        if grid and grid.extra.path[#grid.extra.path] then
            local endpoint = grid.extra.path[#grid.extra.path].coords
            predictedPlayerX = Util.Math.round(endpoint[1] - 0.2)
            predictedPlayerY = Util.Math.round(endpoint[2] - 0.2)
        end
        local willDamagePlayer = self.extra.name == "cellmate"
            and self.extra.goalVertice[1] == predictedPlayerX
            and self.extra.goalVertice[2] == predictedPlayerY
        local pathColor = willDamagePlayer and Macros.colors.darkRed or Macros.colors.darkGreen
        local goalColor = willDamagePlayer and Macros.colors.red or Macros.colors.green
        local goalVector = Util.World.toIsoPos(Vector(self.extra.goalVertice[1] + 0.2, self.extra.goalVertice[2] + 0.2))
        love.graphics.setColor(Util.Color.SetOpacity(pathColor, 0.7))
        love.graphics.setLineWidth(2.5 * Util.UI.getScalingFactor())
        love.graphics.line(vector.contents[1], vector.contents[2], goalVector.contents[1], goalVector.contents[2])
        love.graphics.setLineWidth(1.5 * Util.UI.getScalingFactor())
        love.graphics.setColor(Util.Color.SetOpacity(goalColor, 0.7))
        love.graphics.circle("fill", goalVector.contents[1], goalVector.contents[2], lookup[self.properties.type].radius / 5 * 3 * Util.UI.getScalingFactor())
    end
    love.graphics.circle("fill", vector.contents[1], vector.contents[2], lookup[self.properties.type].radius*Util.UI.getScalingFactor())
    if self.properties.type == "door" then
        love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.white,0.67))
        local v = Util.World.toIsoPos(Vector(visualX, visualY))
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
        local v = Util.World.toIsoPos(Vector(visualX, visualY))
        local direction = self.extra.dir or 1
        love.graphics.draw(
            Atlases[self.extra.name].image,
            Atlases[self.extra.name].splicedImages[0][0],
            v.contents[1] - 40 * direction * Util.UI.getScalingFactor(),
            v.contents[2] - 80 * Util.UI.getScalingFactor(),
            0, 2 * direction * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
        )
    end
    if self.properties.type == "gate" then
        love.graphics.setColor(Macros.colors.white)
        local v = Util.World.toIsoPos(Vector(visualX, visualY))
        local direction = self.extra.dir or 1
        local sprite = self.extra.locked and "prisonGate" or "prisonGateOpen"
        love.graphics.draw(
            Atlases[sprite].image,
            Atlases[sprite].splicedImages[0][0],
            v.contents[1] - 40 * direction * Util.UI.getScalingFactor(),
            v.contents[2] - 80 * Util.UI.getScalingFactor(),
            0, 2 * direction * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
        )
    end
    if self.properties.type == "pickup" then
        love.graphics.setColor(Macros.colors.white)
        local v = Util.World.toIsoPos(Vector(visualX, visualY))
        local atlasKey = self.extra.itemKey == "prison_key"
            and "prisonKey"
            or (
                self.extra.itemKey == "excalibur"
                and "excalibur_throne"
                or (type(self.extra.itemKey) == "table" and "hp_package" or "regular_package")
            )
        local atlas = Atlases[atlasKey]
        local scale = Util.UI.getScalingFactor()
        local drawX = v.contents[1] - 40 * scale
        local drawY = v.contents[2] - 80 * scale
        if self.extra.itemKey ~= "prison_key" then
            drawX = v.contents[1] - atlas.singleDimention.w * scale
            drawY = v.contents[2]
                - (atlas.singleDimention.h * 2 - 40) * scale
        end
        love.graphics.draw(
            atlas.image,
            atlas.splicedImages[0][0],
            drawX,
            drawY,
            0, 2 * scale, 2 * scale
        )
    end
    if self.properties.type == "cover" then
        love.graphics.setColor(Macros.colors.white)
        local v = Util.World.toIsoPos(Vector(visualX, visualY))
        love.graphics.draw(
            Atlases[self.extra.name].image,
            Atlases[self.extra.name].splicedImages[0][0],
            v.contents[1] - 40 * Util.UI.getScalingFactor(),
            v.contents[2] - 80 * Util.UI.getScalingFactor(),
            0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
        )
    end
    if self.properties.type == "danger" then
        local frame = math.floor(love.timer.getTime() * 5) % 2 + 1
        love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.black, 0.2))
        drawWorldTileAtlas("danger_" .. frame, visualX+0.05, visualY+0.05)
        love.graphics.setColor(Macros.colors.white)
        drawWorldTileAtlas("danger_" .. frame, visualX, visualY)
    end
    if self.properties.type == "enemy" then
        love.graphics.setColor(Macros.colors.white)
        local v = Util.World.toIsoPos(Vector(visualX, visualY))
        if not self.extra.name then
            print(self.extra)
            goto exit
        end
        local enemyAtlas = self.extra.name == "skeleton"
            and self.extra.downedTurns
            and "skeletonDowned"
            or (
                Atlases[self.extra.name .. self.extra.facing]
                and self.extra.name .. self.extra.facing
                or self.extra.name
            )
        if Atlases[enemyAtlas] and Atlases[enemyAtlas].image then
            love.graphics.draw(
                Atlases[enemyAtlas].image,
                Atlases[enemyAtlas].splicedImages[0][0],
                v.contents[1] - 40 * Util.UI.getScalingFactor(),
                v.contents[2] - 80 * Util.UI.getScalingFactor(),
                0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
            )
        end
        if self.extra.name == "turret"
            and PLAYER
            and Util.World.hasTurretSightline(
                self,
                PLAYER.TMod.x.base,
                PLAYER.TMod.y.base
            )
        then
            local playerX, playerY = PLAYER:getVisualGridPosition()
            local playerVector = Util.World.toIsoPos(Vector(playerX, playerY))
            local aimX, aimY = getEnemyAimOrigin(self, visualX, visualY)
            local oldLineWidth = love.graphics.getLineWidth()
            love.graphics.setColor(Macros.colors.red)
            drawPixelLockedLine(
                aimX,
                aimY,
                playerVector.contents[1],
                playerVector.contents[2] - 30 * Util.UI.getScalingFactor()
            )
            love.graphics.setLineWidth(oldLineWidth)
            love.graphics.setColor(Macros.colors.white)
        end
        if isRangedEnemyName(self.extra.name)
            and self.extra.shotsRemaining > 0
            and PLAYER
            and Util.World.hasHunterSightline(
                self,
                PLAYER.TMod.x.base,
                PLAYER.TMod.y.base
            )
        then
            local playerX, playerY = PLAYER:getVisualGridPosition()
            local playerVector = Util.World.toIsoPos(Vector(playerX, playerY))
            local oldLineWidth = love.graphics.getLineWidth()
            love.graphics.setColor(Macros.colors.red)
            drawPixelLockedLine(
                v.contents[1],
                v.contents[2] - 30 * Util.UI.getScalingFactor(),
                playerVector.contents[1],
                playerVector.contents[2] - 30 * Util.UI.getScalingFactor()
            )
            love.graphics.setLineWidth(oldLineWidth)
            love.graphics.setColor(Macros.colors.white)
        end
        if not (self.extra.name == "skeleton" and self.extra.downedTurns) then
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
        end
        -- Enemy names (SERIOUSLY GUYS, PLS COMMENT YOUR CODE WHY AM I THE ONLY ONE DOING IT)
    end
    if self.properties.type == "player" then
        love.graphics.setColor(Macros.colors.white)
        local v = Util.World.toIsoPos(Vector(visualX, visualY))
        love.graphics.draw(
            Atlases["dawn"..self.extra.facing].image,
            Atlases["dawn"..self.extra.facing].splicedImages[0][0],
            v.contents[1] - 40 * Util.UI.getScalingFactor(),
            v.contents[2] - 80 * Util.UI.getScalingFactor(),
            0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
        )
    end
    ::exit::
    love.graphics.setColor(r,g,b,a)
end
function WorldMoveable:update(dt)
    Moveable.update(self, dt)
    if self.extra.gridMove then
        local movement = self.extra.gridMove
        movement.elapsed = math.min(movement.elapsed + dt, movement.duration)
        local progress = movement.elapsed / movement.duration
        local position
        if movement.eases then
            local segmentProgress = progress * #movement.eases
            local segment = math.min(#movement.eases, math.floor(segmentProgress) + 1)
            local segmentTime = segmentProgress - segment + 1
            if movement.elapsed >= movement.duration then
                segmentTime = 1
            end
            position = movement.eases[segment](segmentTime)
        else
            position = movement.ease(progress)
        end
        self.extra.visualGridX = position.x
        self.extra.visualGridY = position.y
        if movement.elapsed >= movement.duration then
            self.extra.gridMove = nil
            self.extra.visualGridX = nil
            self.extra.visualGridY = nil
        end
    end

    local visualX, visualY = self:getVisualGridPosition()
    local layerOffset = self.properties.type == "danger" and 9
        or self.properties.type == "cover" and 11.5
        or 12
    local getNum = function (a)
        local a = tonumber(a)
        local array = {
            -1,
            1,
            1,
            -1
        }
        return array[a]
    end
    self.drawOrder = visualX + visualY + layerOffset +
        (self.properties.type == "cover" and getNum(self.extra.name:sub(#self.extra.name, #self.extra.name)) or 0)
        + (self.properties.type == "door" and -.5 or 0)
    if self.properties.type == "danger" then
        self.drawOrder = 9
    end
    local playerIsOnPickup = self.properties.type == "pickup"
        and PLAYER
        and PLAYER.TMod.x.base == self.TMod.x.base
        and PLAYER.TMod.y.base == self.TMod.y.base
    if self.properties.type == "pickup"
        and self.extra.requiresPlayerExit
        and not playerIsOnPickup
    then
        self.extra.requiresPlayerExit = false
        local collection = self.extra.collection or "keys"
        for _, pickup in ipairs(
            G.flags.saveData.curRoom[collection] or {}
        ) do
            if pickup.id == self.extra.identifier then
                pickup.requiresPlayerExit = false
                break
            end
        end
    end
    if self.properties.type == "pickup" then
        if type(self.extra.itemKey) == "string" then
            if not self.extra.collected
           and not self.extra.requiresPlayerExit
           and PLAYER
           and not PLAYER.extra.gridMove
           and playerIsOnPickup
           and addItem(self.extra.itemKey) then
                self.extra.collected = true
                local collection = self.extra.collection or "keys"
                local pickups = G.flags.saveData.curRoom[collection] or {}
                for index, key in ipairs(pickups) do
                    if key.id == self.extra.identifier then
                        table.remove(pickups, index)
                        break
                    end
                end
                Util.Audio.playSfx("key_pick")
                self:remove()
            end
        else
            local str = Util.Math.randomElement(self.extra.itemKey).v
            if not self.extra.collected
            and not self.extra.requiresPlayerExit
            and PLAYER
            and not PLAYER.extra.gridMove
            and playerIsOnPickup
            and addItem(str) then
                self.extra.collected = true
                local collection = self.extra.collection or "keys"
                local pickups = G.flags.saveData.curRoom[collection] or {}
                for index, key in ipairs(pickups) do
                    if key.id == self.extra.identifier then
                        table.remove(pickups, index)
                        break
                    end
                end
                Util.Audio.playSfx("key_pick")
                self:remove()
            end
        end
    end
    -- self:decideMove()
end

function WorldMoveable:unlock()
    if self.properties.type ~= "gate" or not self.extra.locked then
        return false
    end

    self.extra.locked = false
    for _, gate in ipairs(G.flags.saveData.curRoom.gates) do
        if gate.id == self.extra.identifier then
            gate.locked = false
            break
        end
    end
    Util.Audio.playSfx("gate_unlock")
    self:juice()
    return true
end

function WorldMoveable:clearCellBossDanger()
    for _, marker in ipairs(self.extra.dangerMarkers or {}) do
        marker:remove()
    end
    self.extra.dangerMarkers = nil
    self.extra.dangerTiles = nil
end

local CELL_BOSS_FACING_VECTORS = {
    ["1"] = {-1, 0},
    ["2"] = {0, 1},
    ["3"] = {1, 0},
    ["4"] = {0, -1},
}

local function faceCellBossTowardPlayer(boss)
    local bossX, bossY = boss.TMod.x.base, boss.TMod.y.base
    local deltaX = PLAYER.TMod.x.base - bossX
    local deltaY = PLAYER.TMod.y.base - bossY
    local target
    if math.abs(deltaX) >= math.abs(deltaY) and deltaX ~= 0 then
        target = {bossX + math.sign(deltaX), bossY}
    elseif deltaY ~= 0 then
        target = {bossX, bossY + math.sign(deltaY)}
    end
    if target then
        boss.extra.facing = Util.World.getDir({
            {coords = {bossX, bossY}},
            {coords = target},
        })
    end
end

function WorldMoveable:prepareCellBossAttack()
    faceCellBossTowardPlayer(self)
    local forward = CELL_BOSS_FACING_VECTORS[self.extra.facing]
    if not forward then
        return false
    end

    self:clearCellBossDanger()
    local perpendicular = {-forward[2], forward[1]}
    local playerOffsetX = PLAYER.TMod.x.base - self.TMod.x.base
    local playerOffsetY = PLAYER.TMod.y.base - self.TMod.y.base
    local playerLateral = playerOffsetX * perpendicular[1]
        + playerOffsetY * perpendicular[2]
    local lateralStart = playerLateral < 0 and -1 or 0
    local tiles = {}
    local markers = {}

    for depth = 1, 3 do
        for lateral = lateralStart, lateralStart + 1 do
            local x = self.TMod.x.base + forward[1] * depth
                + perpendicular[1] * lateral
            local y = self.TMod.y.base + forward[2] * depth
                + perpendicular[2] * lateral
            if Util.World.isFloor(G.flags.saveData.curRoom, x, y) then
                tiles[#tiles + 1] = {x, y}
                markers[#markers + 1] = WorldMoveable({
                    x = x,
                    y = y,
                    type = "danger",
                    extra = {bossIdentifier = self.extra.identifier},
                    updateOrder = 2,
                    drawOrder = x + y + 9,
                })
            end
        end
    end

    if #tiles == 0 then
        return false
    end
    self.extra.goalVertice = nil
    self.extra.goalPath = nil
    self.extra.bossAction = "attack"
    self.extra.dangerTiles = tiles
    self.extra.dangerMarkers = markers
    return true
end

local function cellBossCoordKey(x, y)
    return x..","..y
end

local function enemyTileIsBlocked(enemy, x, y)
    if not Util.World.isFloor(G.flags.saveData.curRoom, x, y) then
        return true
    end
    for _, moveable in ipairs(Util.World.getAllWorldMoveablesWithCoord({x, y})) do
        if moveable ~= enemy then
            local moveableType = moveable.properties.type
            local passableDownedSkeleton =
                moveableType == "enemy"
                and moveable.extra.name == "skeleton"
                and moveable.extra.downedTurns
            if moveableType == "wall"
                or (moveableType == "enemy" and not passableDownedSkeleton)
                or moveableType == "door"
                or (moveableType == "gate" and moveable.extra.locked)
            then
                return true
            end
        end
    end
    return false
end

local function cellBossGoalIsReserved(boss, x, y)
    for _, enemy in ipairs(Util.World.getAllWorldMoveablesWithType("enemy")) do
        if enemy ~= boss
            and enemy.extra.goalVertice
            and enemy.extra.goalVertice[1] == x
            and enemy.extra.goalVertice[2] == y
        then
            return true
        end
    end
    return false
end

function WorldMoveable:planCellBossMove()
    local width = G.flags.saveData.curRoom.size.w
    local height = G.flags.saveData.curRoom.size.h
    local startX, startY = self.TMod.x.base, self.TMod.y.base
    local targetX, targetY = PLAYER.TMod.x.base, PLAYER.TMod.y.base
    local vertices = getAllValidVertices(
        width,
        height,
        {"wall", "enemy", "door"}
    )
    vertices[startX] = vertices[startX] or {}
    vertices[startX][startY] = true
    for _, door in ipairs(Util.World.getAllWorldMoveablesWithType("door")) do
        if vertices[door.TMod.x.base] then
            vertices[door.TMod.x.base][door.TMod.y.base] = nil
        end
    end

    local startKey = cellBossCoordKey(startX, startY)
    local targetKey = cellBossCoordKey(targetX, targetY)
    local queue = {{startX, startY}}
    local queueIndex = 1
    local previous = {[startKey] = startKey}
    local positions = {[startKey] = {startX, startY}}

    while queueIndex <= #queue and not previous[targetKey] do
        local current = queue[queueIndex]
        queueIndex = queueIndex + 1
        for _, adjacent in ipairs(getAllAdjacentVertices(vertices, current)) do
            local key = cellBossCoordKey(adjacent[1], adjacent[2])
            if not previous[key] then
                previous[key] = cellBossCoordKey(current[1], current[2])
                positions[key] = {adjacent[1], adjacent[2]}
                queue[#queue + 1] = positions[key]
            end
        end
    end
    if not previous[targetKey] then
        return false
    end

    local path = {}
    local key = targetKey
    while key ~= startKey do
        table.insert(path, 1, positions[key])
        key = previous[key]
    end

    local travel = math.min(
        love.math.random(Macros.cellBoss.minMove, Macros.cellBoss.maxMove),
        #path - 1
    )
    for index = 1, travel do
        if cellBossGoalIsReserved(self, path[index][1], path[index][2]) then
            travel = index - 1
            break
        end
    end
    if travel < 1 then
        return false
    end

    self.extra.goalPath = {}
    for index = 1, travel do
        self.extra.goalPath[index] = {path[index][1], path[index][2]}
    end
    local destination = self.extra.goalPath[#self.extra.goalPath]
    self.extra.goalVertice = {destination[1], destination[2]}
    self.extra.bossAction = "move"
    return true
end

local function cellBossTileIsBlocked(boss, x, y)
    return enemyTileIsBlocked(boss, x, y)
end

function WorldMoveable:resolveCellBossMove()
    local path = {}
    for _, position in ipairs(self.extra.goalPath or {}) do
        if position[1] == PLAYER.TMod.x.base
            and position[2] == PLAYER.TMod.y.base
        then
            break
        end
        if cellBossTileIsBlocked(self, position[1], position[2]) then
            break
        end
        path[#path + 1] = {position[1], position[2]}
    end

    self.extra.goalPath = nil
    self.extra.goalVertice = nil
    self.extra.bossAction = nil
    if #path == 0 then
        return
    end

    local fromX, fromY = self.TMod.x.base, self.TMod.y.base
    if #path > 1 then
        fromX, fromY = path[#path - 1][1], path[#path - 1][2]
    end
    local destination = path[#path]
    self.extra.facing = Util.World.getDir({
        {coords = {fromX, fromY}},
        {coords = destination},
    })
    self:moveAlongGridPath(path, 0.14)
    self:juice()
end

function WorldMoveable:resolveCellBossAttack()
    local tiles = self.extra.dangerTiles or {}
    self.extra.attackSequence = (self.extra.attackSequence or 0) + 1
    local sequence = self.extra.attackSequence
    self:clearCellBossDanger()
    self.extra.goalVertice = nil
    self.extra.goalPath = nil
    self.extra.bossAction = nil

    for index, position in ipairs(tiles) do
        local x, y = position[1], position[2]
        Util.Event.addEvent(Event({
            duration = 0.4,
            drawOrder = x + y + 10,
            drawFunc = function(time)
                local r, g, b, a = love.graphics.getColor()
                love.graphics.setColor(Macros.colors.white)
                local frame = math.min(4, math.floor(time * 4) + 1)
                drawWorldTileAtlas("tileAttack_"..frame, x, y)
                love.graphics.setColor(r, g, b, a)
            end,
        }), "cellBossAttack"..self.id.."_"..sequence.."_"..index)
    end
    Util.Audio.playSfx("slam")
    self:juice(4)

    for _, position in ipairs(tiles) do
        if position[1] == PLAYER.TMod.x.base
            and position[2] == PLAYER.TMod.y.base
        then
            return Util.World.modHP(-Macros.cellBoss.damage)
        end
    end
    return false
end

function WorldMoveable:resolveCellBossTurn()
    if self.extra.bossAction == "attack" then
        return self:resolveCellBossAttack()
    elseif self.extra.bossAction == "move" then
        self:resolveCellBossMove()
    end
    return false
end

local function getFacingTowardPoint(fromX, fromY, toX, toY)
    local deltaX = toX - fromX
    local deltaY = toY - fromY
    if math.abs(deltaX) >= math.abs(deltaY) and deltaX ~= 0 then
        return deltaX < 0 and "1" or "3"
    elseif deltaY ~= 0 then
        return deltaY < 0 and "4" or "2"
    end
end

local function getWizardCastRange()
    local size = G.flags.saveData.curRoom.size
    return math.ceil(
        math.max(size.w, size.h) * Macros.wizard.rangeFraction
    )
end

function WorldMoveable:clearWizardDanger()
    for _, marker in ipairs(self.extra.dangerMarkers or {}) do
        marker:remove()
    end
    self.extra.dangerMarkers = nil
    self.extra.dangerTiles = nil
    self.extra.dangerCenter = nil
end

function WorldMoveable:prepareWizardAttack()
    local centerX = PLAYER.TMod.x.base
    local centerY = PLAYER.TMod.y.base
    local radius = Macros.wizard.aoeRadius
    local tiles = {}
    local markers = {}

    self:clearWizardDanger()
    for x = centerX - radius, centerX + radius do
        for y = centerY - radius, centerY + radius do
            local deltaX = x - centerX
            local deltaY = y - centerY
            if deltaX * deltaX + deltaY * deltaY <= radius * radius
                and Util.World.isFloor(G.flags.saveData.curRoom, x, y)
            then
                tiles[#tiles + 1] = {x, y}
                markers[#markers + 1] = WorldMoveable({
                    x = x,
                    y = y,
                    type = "danger",
                    extra = {wizardIdentifier = self.extra.identifier},
                    updateOrder = 2,
                    drawOrder = x + y + 9,
                })
            end
        end
    end
    if #tiles == 0 then
        return false
    end

    self.extra.facing = getFacingTowardPoint(
        self.TMod.x.base,
        self.TMod.y.base,
        centerX,
        centerY
    ) or self.extra.facing
    self.extra.wizardAction = "attack"
    self.extra.goalVertice = nil
    self.extra.goalPath = nil
    self.extra.dangerCenter = {centerX, centerY}
    self.extra.dangerTiles = tiles
    self.extra.dangerMarkers = markers
    self:juice(3)
    return true
end

function WorldMoveable:planWizardMove(towardPlayer)
    local room = G.flags.saveData.curRoom
    local startX, startY = self.TMod.x.base, self.TMod.y.base
    local vertices = getAllValidVertices(
        room.size.w,
        room.size.h,
        {"wall", "enemy", "door"}
    )
    vertices[startX] = vertices[startX] or {}
    vertices[startX][startY] = true

    local queue = {{
        x = startX,
        y = startY,
        path = {},
    }}
    local queueIndex = 1
    local seen = {[startX..","..startY] = true}
    local candidates = {}
    while queueIndex <= #queue do
        local current = queue[queueIndex]
        queueIndex = queueIndex + 1
        if #current.path < Macros.wizard.moveDistance then
            for _, position in ipairs(getAllAdjacentVertices(
                vertices,
                {current.x, current.y}
            )) do
                local x, y = position[1], position[2]
                local key = x..","..y
                if not seen[key]
                    and not (
                        x == PLAYER.TMod.x.base
                        and y == PLAYER.TMod.y.base
                    )
                    and not enemyTileIsBlocked(self, x, y)
                    and not cellBossGoalIsReserved(self, x, y)
                then
                    seen[key] = true
                    local path = {}
                    for index, step in ipairs(current.path) do
                        path[index] = {step[1], step[2]}
                    end
                    path[#path + 1] = {x, y}
                    local candidate = {
                        x = x,
                        y = y,
                        path = path,
                    }
                    candidates[#candidates + 1] = candidate
                    queue[#queue + 1] = candidate
                end
            end
        end
    end
    if #candidates == 0 then
        return false
    end

    local castRange = getWizardCastRange()
    local best
    for _, candidate in ipairs(candidates) do
        local distance = math.abs(PLAYER.TMod.x.base - candidate.x)
            + math.abs(PLAYER.TMod.y.base - candidate.y)
        local score
        if towardPlayer then
            score = -distance * 20 + #candidate.path
        else
            score = -math.abs(distance - castRange) * 20
                + distance
                + #candidate.path
        end
        score = score + love.math.random()
        if not best or score > best.score then
            best = {
                x = candidate.x,
                y = candidate.y,
                path = candidate.path,
                score = score,
            }
        end
    end

    self.extra.wizardAction = "move"
    self.extra.goalPath = best.path
    self.extra.goalVertice = {best.x, best.y}
    return true
end

function WorldMoveable:resolveWizardMove()
    local movement = {}
    for _, position in ipairs(self.extra.goalPath or {}) do
        if position[1] == PLAYER.TMod.x.base
            and position[2] == PLAYER.TMod.y.base
        then
            break
        end
        if enemyTileIsBlocked(self, position[1], position[2]) then
            break
        end
        movement[#movement + 1] = {position[1], position[2]}
    end

    self.extra.wizardAction = nil
    self.extra.goalPath = nil
    self.extra.goalVertice = nil
    if #movement == 0 then
        return
    end

    local fromX, fromY = self.TMod.x.base, self.TMod.y.base
    if #movement > 1 then
        fromX, fromY = movement[#movement - 1][1], movement[#movement - 1][2]
    end
    local destination = movement[#movement]
    self.extra.facing = getFacingTowardPoint(
        fromX,
        fromY,
        destination[1],
        destination[2]
    ) or self.extra.facing
    self:moveAlongGridPath(movement, 0.1)
    self:juice()
end

function WorldMoveable:resolveWizardAttack()
    local tiles = self.extra.dangerTiles or {}
    self.extra.attackSequence = (self.extra.attackSequence or 0) + 1
    local sequence = self.extra.attackSequence
    self:clearWizardDanger()
    self.extra.wizardAction = nil

    for index, position in ipairs(tiles) do
        local x, y = position[1], position[2]
        Util.Event.addEvent(Event({
            duration = 0.4,
            drawOrder = x + y + 10,
            drawFunc = function(time)
                local r, g, b, a = love.graphics.getColor()
                love.graphics.setColor(Macros.colors.white)
                local frame = math.min(4, math.floor(time * 4) + 1)
                drawWorldTileAtlas("tileAttack_"..frame, x, y)
                love.graphics.setColor(r, g, b, a)
            end,
        }), "wizardAttack"..self.id.."_"..sequence.."_"..index)
    end
    Util.Audio.playSfx("slam")
    self:juice(4)

    for _, position in ipairs(tiles) do
        if position[1] == PLAYER.TMod.x.base
            and position[2] == PLAYER.TMod.y.base
        then
            return Util.World.modHP(-Macros.wizard.damage)
        end
    end
    return false
end

function WorldMoveable:resolveWizardTurn()
    if self.extra.wizardAction == "attack" then
        return self:resolveWizardAttack()
    elseif self.extra.wizardAction == "move" then
        self:resolveWizardMove()
    end
    return false
end

function WorldMoveable:planWizardAction()
    if self.extra.wizardAction then
        return
    end

    local distance = math.abs(PLAYER.TMod.x.base - self.TMod.x.base)
        + math.abs(PLAYER.TMod.y.base - self.TMod.y.base)
    if distance > getWizardCastRange() then
        self:planWizardMove(true)
    elseif distance < Macros.wizard.minDistance
        and self:planWizardMove(false)
    then
        return
    elseif not self:prepareWizardAttack() then
        self:planWizardMove(true)
    end
end

function WorldMoveable:clearEliteDanger()
    for _, marker in ipairs(self.extra.dangerMarkers or {}) do
        marker:remove()
    end
    self.extra.dangerMarkers = nil
    self.extra.dangerTiles = nil
    self.extra.dangerCenter = nil
end

local function eliteDangerCellIsBlocked(elite, x, y)
    for _, moveable in ipairs(Util.World.getAllWorldMoveablesWithCoord(
        {x, y}
    )) do
        if moveable ~= elite then
            local moveableType = moveable.properties.type
            if moveableType == "cover"
                or moveableType == "wall"
                or (moveableType == "gate" and moveable.extra.locked)
                or (
                    moveableType == "enemy"
                    and moveable.extra.name == "turret"
                )
            then
                return true
            end
        end
    end
    return false
end

function WorldMoveable:prepareEliteAttack()
    local config = Macros[self.extra.name] or Macros.elite
    local startX, startY = self.TMod.x.base, self.TMod.y.base
    local playerX, playerY = PLAYER.TMod.x.base, PLAYER.TMod.y.base
    local cells = Util.World.getGridLineCells(
        startX,
        startY,
        playerX,
        playerY
    )
    if #cells == 0 then
        return false
    end

    local previous = #cells > 1 and cells[#cells - 1] or {startX, startY}
    local last = cells[#cells]
    local stepX = last[1] - previous[1]
    local stepY = last[2] - previous[2]
    while #cells < config.attackRange do
        last = {
            last[1] + stepX,
            last[2] + stepY,
        }
        cells[#cells + 1] = last
    end

    self:clearEliteDanger()
    local tiles = {}
    local markers = {}
    for index = 1, math.min(#cells, config.attackRange) do
        local x, y = cells[index][1], cells[index][2]
        if not Util.World.isFloor(G.flags.saveData.curRoom, x, y)
            or eliteDangerCellIsBlocked(self, x, y)
        then
            break
        end
        tiles[#tiles + 1] = {x, y}
        markers[#markers + 1] = WorldMoveable({
            x = x,
            y = y,
            type = "danger",
            extra = {eliteIdentifier = self.extra.identifier},
            updateOrder = 2,
            drawOrder = x + y + 9,
        })
    end
    if #tiles == 0 then
        return false
    end

    self.extra.facing = getFacingTowardPoint(
        startX,
        startY,
        playerX,
        playerY
    ) or self.extra.facing
    self.extra.eliteAction = "attack"
    self.extra.dangerTiles = tiles
    self.extra.dangerMarkers = markers
    self:juice()
    return true
end

function WorldMoveable:resolveEliteAttack()
    local config = Macros[self.extra.name] or Macros.elite
    local tiles = self.extra.dangerTiles or {}
    self.extra.attackSequence = (self.extra.attackSequence or 0) + 1
    local sequence = self.extra.attackSequence
    self:clearEliteDanger()
    self.extra.eliteAction = nil
    self.extra.shotsRemaining = config.magazine

    for index, position in ipairs(tiles) do
        local x, y = position[1], position[2]
        Util.Event.addEvent(Event({
            duration = 0.4,
            drawOrder = x + y + 10,
            drawFunc = function(time)
                local r, g, b, a = love.graphics.getColor()
                love.graphics.setColor(Macros.colors.white)
                local frame = math.min(4, math.floor(time * 4) + 1)
                drawWorldTileAtlas("tileAttack_"..frame, x, y)
                love.graphics.setColor(r, g, b, a)
            end,
        }), "eliteAttack"..self.id.."_"..sequence.."_"..index)
    end
    Util.Audio.playSfx("slam")
    self:juice(4)

    for _, position in ipairs(tiles) do
        if position[1] == PLAYER.TMod.x.base
            and position[2] == PLAYER.TMod.y.base
        then
            return Util.World.modHP(-config.attackDamage)
        end
    end
    return false
end

function WorldMoveable:prepareAbrahamAoe()
    local config = Macros.abraham
    local centerX = PLAYER.TMod.x.base
    local centerY = PLAYER.TMod.y.base
    local distance = math.abs(centerX - self.TMod.x.base)
        + math.abs(centerY - self.TMod.y.base)
    if distance > config.aoeRange then
        return false
    end

    self:clearEliteDanger()
    local tiles = {}
    local markers = {}
    for x = centerX - config.aoeRadius, centerX + config.aoeRadius do
        for y = centerY - config.aoeRadius, centerY + config.aoeRadius do
            local deltaX = x - centerX
            local deltaY = y - centerY
            if deltaX * deltaX + deltaY * deltaY
                <= config.aoeRadius * config.aoeRadius
                and Util.World.isFloor(G.flags.saveData.curRoom, x, y)
            then
                tiles[#tiles + 1] = {x, y}
                markers[#markers + 1] = WorldMoveable({
                    x = x,
                    y = y,
                    type = "danger",
                    extra = {abrahamIdentifier = self.extra.identifier},
                    updateOrder = 2,
                    drawOrder = x + y + 9,
                })
            end
        end
    end
    if #tiles == 0 then
        return false
    end

    self.extra.facing = getFacingTowardPoint(
        self.TMod.x.base,
        self.TMod.y.base,
        centerX,
        centerY
    ) or self.extra.facing
    self.extra.eliteAction = "aoe"
    self.extra.dangerTiles = tiles
    self.extra.dangerMarkers = markers
    self.extra.dangerCenter = {centerX, centerY}
    self:juice(3)
    return true
end

function WorldMoveable:resolveAbrahamAoe()
    local tiles = self.extra.dangerTiles or {}
    self.extra.attackSequence = (self.extra.attackSequence or 0) + 1
    local sequence = self.extra.attackSequence
    self:clearEliteDanger()
    self.extra.eliteAction = nil
    self.extra.dangerCenter = nil
    self.extra.shotsRemaining = Macros.abraham.magazine

    for index, position in ipairs(tiles) do
        local x, y = position[1], position[2]
        Util.Event.addEvent(Event({
            duration = 0.4,
            drawOrder = x + y + 10,
            drawFunc = function(time)
                local r, g, b, a = love.graphics.getColor()
                love.graphics.setColor(Macros.colors.white)
                local frame = math.min(4, math.floor(time * 4) + 1)
                drawWorldTileAtlas("tileAttack_"..frame, x, y)
                love.graphics.setColor(r, g, b, a)
            end,
        }), "abrahamAoe"..self.id.."_"..sequence.."_"..index)
    end
    Util.Audio.playSfx("slam")
    self:juice(5)

    for _, position in ipairs(tiles) do
        if position[1] == PLAYER.TMod.x.base
            and position[2] == PLAYER.TMod.y.base
        then
            return Util.World.modHP(-Macros.abraham.aoeDamage)
        end
    end
    return false
end

local function addEnemyShotEffect(shooter, target)
    local startX, startY = shooter:getVisualGridPosition()
    local targetX, targetY = target:getVisualGridPosition()
    Util.Event.addEvent(Event({
        duration = 0.16,
        drawOrder = 100,
        drawFunc = function(time)
            local r, g, b, a = love.graphics.getColor()
            local oldLineWidth = love.graphics.getLineWidth()
            local finish = Util.World.toIsoPos(Vector(targetX, targetY))
            local aimX, aimY = getEnemyAimOrigin(shooter, startX, startY)
            love.graphics.setColor(Util.Color.SetOpacity(
                Macros.colors.red,
                1 - time
            ))
            drawPixelLockedLine(
                aimX,
                aimY,
                finish.contents[1],
                finish.contents[2] - 30 * Util.UI.getScalingFactor()
            )
            love.graphics.setLineWidth(oldLineWidth)
            love.graphics.setColor(r, g, b, a)
        end,
    }), "enemyShot"..shooter.id)
end

local function rangedEnemyPositionIsClear(shooter, x, y)
    if enemyTileIsBlocked(shooter, x, y)
        or (x == PLAYER.TMod.x.base and y == PLAYER.TMod.y.base)
    then
        return false
    end
    for _, enemy in ipairs(Util.World.getAllWorldMoveablesWithType("enemy")) do
        if enemy ~= shooter
            and enemy.extra.goalVertice
            and enemy.extra.goalVertice[1] == x
            and enemy.extra.goalVertice[2] == y
        then
            return false
        end
    end
    return true
end

local function jumpAbraham(shooter)
    local room = G.flags.saveData.curRoom
    local startX, startY = shooter.TMod.x.base, shooter.TMod.y.base
    local minimumJump = math.ceil(math.max(room.size.w, room.size.h) / 2)
    local candidates = {}
    local fallback = {}

    for x = 0, room.size.w - 1 do
        for y = 0, room.size.h - 1 do
            if rangedEnemyPositionIsClear(shooter, x, y) then
                local jumpDistance = math.abs(x - startX)
                    + math.abs(y - startY)
                local playerDistance = math.abs(PLAYER.TMod.x.base - x)
                    + math.abs(PLAYER.TMod.y.base - y)
                local candidate = {
                    x = x,
                    y = y,
                    score = jumpDistance * 3
                        - math.abs(
                            playerDistance - Macros.abraham.idealDistance
                        ) * 10
                        + love.math.random(),
                }
                fallback[#fallback + 1] = candidate
                if jumpDistance >= minimumJump then
                    candidates[#candidates + 1] = candidate
                end
            end
        end
    end

    if #candidates == 0 then
        candidates = fallback
    end
    if #candidates == 0 then
        return false
    end
    table.sort(candidates, function(a, b)
        return a.score > b.score
    end)

    local destination = candidates[1]
    shooter.extra.facing = getFacingTowardPoint(
        destination.x,
        destination.y,
        PLAYER.TMod.x.base,
        PLAYER.TMod.y.base
    ) or shooter.extra.facing
    shooter:moveToGrid(destination.x, destination.y, 0.3)
    shooter.extra.shotsRemaining = Macros.abraham.magazine
    shooter:juice(4)
    return true
end

local function repositionRangedEnemy(shooter)
    local config = Macros[shooter.extra.name]
    local startX, startY = shooter.TMod.x.base, shooter.TMod.y.base
    local playerX, playerY = PLAYER.TMod.x.base, PLAYER.TMod.y.base
    local vertices = getAllValidVertices(
        G.flags.saveData.curRoom.size.w,
        G.flags.saveData.curRoom.size.h,
        {"wall", "enemy", "door"}
    )
    vertices[startX] = vertices[startX] or {}
    vertices[startX][startY] = true
    local candidates = {}
    local queue = {{
        x = startX,
        y = startY,
        path = {},
    }}
    local queueIndex = 1
    local seen = {[startX..","..startY] = true}
    while queueIndex <= #queue do
        local current = queue[queueIndex]
        queueIndex = queueIndex + 1
        if #current.path < (config.moveDistance or 1) then
            for _, position in ipairs(getAllAdjacentVertices(
                vertices,
                {current.x, current.y}
            )) do
                local key = position[1]..","..position[2]
                if not seen[key]
                    and rangedEnemyPositionIsClear(
                        shooter,
                        position[1],
                        position[2]
                    )
                then
                    seen[key] = true
                    local path = {}
                    for index, step in ipairs(current.path) do
                        path[index] = {step[1], step[2]}
                    end
                    path[#path + 1] = {position[1], position[2]}
                    local candidate = {
                        x = position[1],
                        y = position[2],
                        path = path,
                    }
                    candidates[#candidates + 1] = candidate
                    queue[#queue + 1] = candidate
                end
            end
        end
    end
    if #candidates == 0 then
        candidates[1] = {
            x = startX,
            y = startY,
            path = {},
        }
    end

    local turretPositions = {}
    for _, enemy in ipairs(Util.World.getAllWorldMoveablesWithType("enemy")) do
        if enemy.extra.name == "turret" then
            turretPositions[#turretPositions + 1] = {
                enemy.TMod.x.base,
                enemy.TMod.y.base,
            }
        end
    end

    local best
    for _, position in ipairs(candidates) do
        local x, y = position.x, position.y
        local distance = math.abs(playerX - x) + math.abs(playerY - y)
        local hasNextShot = Util.World.hasHunterSightlineFrom(
            G.flags.saveData.curRoom,
            x,
            y,
            playerX,
            playerY,
            turretPositions,
            config.range
        )
        local score = -math.abs(distance - config.idealDistance) * 10
            - math.max(0, config.idealDistance - distance) * 4
            + (hasNextShot and 6 or 0)
            + love.math.random()
        if not best or score > best.score then
            best = {
                x = x,
                y = y,
                path = position.path,
                score = score,
            }
        end
    end

    shooter.extra.facing = getFacingTowardPoint(
        best.x,
        best.y,
        playerX,
        playerY
    ) or shooter.extra.facing
    if best.x ~= startX or best.y ~= startY then
        if #best.path > 1 then
            shooter:moveAlongGridPath(best.path, 0.14)
        else
            shooter:moveToGrid(best.x, best.y)
        end
    end
    shooter:juice()
end

local function getRangedFriendlyFireTarget(shooter)
    local cells = Util.World.getGridLineCells(
        shooter.TMod.x.base,
        shooter.TMod.y.base,
        PLAYER.TMod.x.base,
        PLAYER.TMod.y.base
    )
    for index = 1, #cells - 1 do
        local cell = cells[index]
        for _, enemy in ipairs(Util.World.getAllWorldMoveablesWithType(
            "enemy"
        )) do
            if enemy ~= shooter
                and enemy.extra.name ~= "turret"
                and enemy.extra.hp > 0
                and enemy.TMod.x.base == cell[1]
                and enemy.TMod.y.base == cell[2]
            then
                return enemy
            end
        end
    end
end

local function chooseAbrahamAction(shooter, config)
    if shooter.extra.shotsRemaining > 0 then
        if Util.Math.chance(config.jumpChance) and jumpAbraham(shooter) then
            return
        end
        repositionRangedEnemy(shooter)
        shooter.extra.shotsRemaining = config.magazine
        return
    end

    local choice = love.math.random()
    if choice < config.aoeChance then
        if shooter:prepareAbrahamAoe() then
            return
        end
    elseif choice < config.aoeChance + config.jumpChance then
        if jumpAbraham(shooter) then
            return
        end
    elseif choice
        < config.aoeChance + config.jumpChance + config.lineAttackChance
    then
        if shooter:prepareEliteAttack() then
            return
        end
    end

    repositionRangedEnemy(shooter)
    shooter.extra.shotsRemaining = config.magazine
end

local function resolveRangedEnemyActions(allEnemies)
    for _, shooter in ipairs(allEnemies) do
        if isRangedEnemyName(shooter.extra.name) and shooter.extra.hp > 0 then
            local config = Macros[shooter.extra.name]
            if (shooter.extra.name == "elite"
                    or shooter.extra.name == "abraham")
                and shooter.extra.eliteAction == "attack" then
                if shooter:resolveEliteAttack() then
                    return true
                end
                goto continue
            end
            if shooter.extra.name == "abraham"
                and shooter.extra.eliteAction == "aoe"
            then
                if shooter:resolveAbrahamAoe() then
                    return true
                end
                goto continue
            end
            local canShoot = shooter.extra.shotsRemaining > 0
                and Util.World.hasHunterSightline(
                    shooter,
                    PLAYER.TMod.x.base,
                    PLAYER.TMod.y.base
                )
            if canShoot then
                shooter.extra.facing = getFacingTowardPoint(
                    shooter.TMod.x.base,
                    shooter.TMod.y.base,
                    PLAYER.TMod.x.base,
                    PLAYER.TMod.y.base
                ) or shooter.extra.facing
                shooter.extra.shotsRemaining = shooter.extra.shotsRemaining - 1
                local friendlyFireTarget =
                    getRangedFriendlyFireTarget(shooter)
                local target = friendlyFireTarget or PLAYER
                addEnemyShotEffect(shooter, target)
                shooter:juice()
                if friendlyFireTarget then
                    friendlyFireTarget:modHP(-config.damage)
                elseif Util.World.modHP(-config.damage) then
                    return true
                end
            elseif shooter.extra.name == "abraham" then
                chooseAbrahamAction(shooter, config)
            else
                local preparedAttack = shooter.extra.name == "elite"
                    and shooter.extra.shotsRemaining <= 0
                    and Util.Math.chance(config.attackChance)
                    and shooter:prepareEliteAttack()
                if not preparedAttack then
                    repositionRangedEnemy(shooter)
                    shooter.extra.shotsRemaining = config.magazine
                end
            end
        end
        ::continue::
    end
    return false
end

local function turnTurretTowardPlayer(turret)
    turret.extra.facing = getFacingTowardPoint(
        turret.TMod.x.base,
        turret.TMod.y.base,
        PLAYER.TMod.x.base,
        PLAYER.TMod.y.base
    ) or turret.extra.facing
    turret:juice()
end

local function getHunterBetweenTurretAndPlayer(turret)
    local cells = Util.World.getGridLineCells(
        turret.TMod.x.base,
        turret.TMod.y.base,
        PLAYER.TMod.x.base,
        PLAYER.TMod.y.base
    )
    for index = 1, #cells - 1 do
        local cell = cells[index]
        for _, enemy in ipairs(Util.World.getAllWorldMoveablesWithType("enemy")) do
            if enemy.extra.name == "hunter"
                and enemy.extra.hp > 0
                and enemy.TMod.x.base == cell[1]
                and enemy.TMod.y.base == cell[2]
            then
                return enemy
            end
        end
    end
end

local function resolveTurretActions(allEnemies)
    for _, enemy in ipairs(allEnemies) do
        if enemy.extra.name == "turret" and enemy.extra.hp > 0 then
            if Util.World.hasTurretSightline(
                enemy,
                PLAYER.TMod.x.base,
                PLAYER.TMod.y.base
            )
            then
                local friendlyFireTarget = getHunterBetweenTurretAndPlayer(
                    enemy
                )
                if friendlyFireTarget then
                    addEnemyShotEffect(enemy, friendlyFireTarget)
                    friendlyFireTarget:modHP(-2)
                else
                    addEnemyShotEffect(enemy, PLAYER)
                    if Util.World.modHP(-2) then
                        return true
                    end
                end
            else
                turnTurretTowardPlayer(enemy)
            end
        end
    end
    return false
end

function WorldMoveable:advanceSkeletonRevival()
    if not self.extra.downedTurns then
        return false
    end
    if self.extra.justDowned then
        self.extra.justDowned = nil
        return true
    end

    local roomRecord = getEnemyRoomRecord(self)
    self.extra.downedTurns = self.extra.downedTurns - 1
    if self.extra.downedTurns <= 0 then
        local tileOccupied = PLAYER
            and PLAYER.TMod.x.base == self.TMod.x.base
            and PLAYER.TMod.y.base == self.TMod.y.base
        if not tileOccupied then
            for _, enemy in ipairs(
                Util.World.getAllWorldMoveablesWithType("enemy")
            ) do
                if enemy ~= self
                    and enemy.extra.hp > 0
                    and enemy.TMod.x.base == self.TMod.x.base
                    and enemy.TMod.y.base == self.TMod.y.base
                then
                    tileOccupied = true
                    break
                end
            end
        end
        if tileOccupied then
            self.extra.downedTurns = 1
            if roomRecord then
                roomRecord.downedTurns = 1
            end
            return true
        end

        self.extra.downedTurns = nil
        self.extra.hp = Macros.maxHps.skeleton
        if roomRecord then
            roomRecord.hp = self.extra.hp
            roomRecord.downedTurns = nil
            roomRecord.killCredited = self.extra.killCredited
        end
        self:juice(3)
        self:checkEaseMusic()
        return false
    end
    if roomRecord then
        roomRecord.downedTurns = self.extra.downedTurns
    end
    return true
end
function WorldMoveable:planSkeletonMove()
    if self.extra.downedTurns then
        return false
    end

    local currentX, currentY = self.TMod.x.base, self.TMod.y.base
    local path = {}
    local visited = {[currentX..","..currentY] = true}
    for _ = 1, Macros.skeleton.moveDistance do
        local candidates = {}
        local bestDistance
        for _, offset in ipairs({
            {-1, 0},
            {1, 0},
            {0, -1},
            {0, 1},
        }) do
            local x = currentX + offset[1]
            local y = currentY + offset[2]
            local key = x..","..y
            local isPlayer = x == PLAYER.TMod.x.base
                and y == PLAYER.TMod.y.base
            if not visited[key]
                and (
                    isPlayer
                    or (
                        not enemyTileIsBlocked(self, x, y)
                        and not cellBossGoalIsReserved(self, x, y)
                    )
                )
            then
                local distance = math.abs(PLAYER.TMod.x.base - x)
                    + math.abs(PLAYER.TMod.y.base - y)
                if not bestDistance or distance < bestDistance then
                    bestDistance = distance
                    candidates = {{x, y}}
                elseif distance == bestDistance then
                    candidates[#candidates + 1] = {x, y}
                end
            end
        end
        if #candidates == 0 then
            break
        end
        local position = candidates[love.math.random(1, #candidates)]
        path[#path + 1] = position
        currentX, currentY = position[1], position[2]
        visited[currentX..","..currentY] = true
        if currentX == PLAYER.TMod.x.base
            and currentY == PLAYER.TMod.y.base
        then
            break
        end
    end

    if #path == 0 then
        return false
    end
    self.extra.goalPath = path
    local destination = path[#path]
    self.extra.goalVertice = {destination[1], destination[2]}
    return true
end
function WorldMoveable:onRoomClear()
    if not G.flags.saveData.curRoom.hasHeals then
        G.flags.saveData.curRoom.hasHeals = true
        local blocked = {}
        for _, wall in ipairs(G.flags.saveData.curRoom.walls) do
            blocked[coordKey(wall.x, wall.y)] = true
        end
        local tiles = getReachableTiles(G.flags.saveData.curRoom, { x = PLAYER.TMod.x.base, y = PLAYER.TMod.y.base },
            blocked)
        tiles[coordKey(PLAYER.TMod.x.base, PLAYER.TMod.y.base)] = nil
        local randomTile = Util.Math.randomElement(tiles).v
        Util.Audio.playSfx("start_jingle", 2)
        WorldMoveable({
            x = randomTile[1],
            y = randomTile[2],
            type = "pickup",
            extra = {
                itemKey = Pools.misc.keys,
                identifier = "mapHealing",
                collection = "pickups",
            },
            updateOrder = 2,
            drawOrder = 10
        })
        G.flags.saveData.curRoom.maxId = G.flags.saveData.curRoom.maxId + 1
    end
end
function WorldMoveable:resolveSkeletonMove()
    local movement = {}
    local hitPlayer = false
    for _, position in ipairs(self.extra.goalPath or {}) do
        if position[1] == PLAYER.TMod.x.base
            and position[2] == PLAYER.TMod.y.base
        then
            hitPlayer = true
            break
        end
        if enemyTileIsBlocked(self, position[1], position[2]) then
            break
        end
        movement[#movement + 1] = {position[1], position[2]}
    end
    self.extra.goalPath = nil
    self.extra.goalVertice = nil

    if #movement > 0 then
        local fromX, fromY = self.TMod.x.base, self.TMod.y.base
        local destination = movement[#movement]
        if #movement > 1 then
            fromX, fromY = movement[#movement - 1][1], movement[#movement - 1][2]
        end
        self.extra.facing = Util.World.getDir({
            {coords = {fromX, fromY}},
            {coords = destination},
        })
        self:moveAlongGridPath(movement, 0.12)
    elseif hitPlayer then
        self.extra.facing = getFacingTowardPoint(
            self.TMod.x.base,
            self.TMod.y.base,
            PLAYER.TMod.x.base,
            PLAYER.TMod.y.base
        ) or self.extra.facing
    end
    self:juice()

    if hitPlayer then
        return Util.World.modHP(-Macros.skeleton.damage)
    end
    return false
end

function move_all_enemies()
    local allEnemies = Util.World.getAllWorldMoveablesWithType("enemy")
    if resolveRangedEnemyActions(allEnemies) then
        return
    end
    if resolveTurretActions(allEnemies) then
        return
    end
    for k, v in ipairs(allEnemies) do
        if v.extra.hp > 0 or v.extra.name == "skeleton" then
            if v.extra.name == "skeleton" and v:advanceSkeletonRevival() then
                -- A downed skeleton keeps occupying its tile until it revives.
            elseif v.extra.name == "skeleton" and v.extra.goalPath then
                if v:resolveSkeletonMove() then
                    return
                end
            elseif v.extra.name == "cellboss" then
                if v:resolveCellBossTurn() then
                    return
                end
            elseif v.extra.name == "wizard" then
                if v:resolveWizardTurn() then
                    return
                end
            elseif v.extra.goalVertice then
                local goalX, goalY = v.extra.goalVertice[1], v.extra.goalVertice[2]
                if goalX == PLAYER.TMod.x.base and goalY == PLAYER.TMod.y.base then
                    local ret = Util.World.modHP(-2)
                    if ret then return end
                elseif not enemyTileIsBlocked(v, goalX, goalY) then
                    v.extra.facing = Util.World.getDir({
                        {coords = {v.TMod.x.base, v.TMod.y.base}},
                        {coords = {goalX, goalY}},
                    })
                    v:moveToGrid(goalX, goalY)
                else
                    v.extra.goalVertice = nil
                end
                v.extra.goalVertice = nil
                v:juice()
            end
        end
    end
    for k, v in ipairs(allEnemies) do
        if v.extra.hp > 0 then
            v:decideMove()
        end
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
            local oldRoomIndex = G.flags.saveData.curRoomIndex
            local targetRoomIndex = self.extra.index
            local targetRoom = G.flags.saveData.rooms[targetRoomIndex]

            local entrance
            for _, door in ipairs(targetRoom.doors) do
                if door.index == oldRoomIndex then
                    entrance = door
                    break
                end
            end

            local spawn = entrance.a
            G.flags.saveData.curRoomIndex = targetRoomIndex
            G.flags.saveData.curRoom = targetRoom

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
                x = spawn.x,
                y = spawn.y,
                type = "player",
                drawOrder = 31,
                updateOrder = 1,
                extra = {facing = old_facing}
            })
            WorldMoveable:initRoomStuff()
            G.flags.saveData.playerPos = { x = spawn.x, y = spawn.y }
            G.flags.saveData.playerFacing = convert(entrance.side)
            self:checkEaseMusic()
            Util.World.saveGame()
        end, "delay2")
    end
end
function WorldMoveable:decideMove()
    if self.properties.type == "enemy" then
        if self.extra.name == "guard" then return nil end
        if self.extra.name == "turret" then return nil end
        if isRangedEnemyName(self.extra.name) then return nil end
        if self.extra.name == "skeleton" then
            self:planSkeletonMove()
            return
        end
        if self.extra.name == "wizard" then
            self:planWizardAction()
            return
        end
        if self.extra.name == "cellboss" then
            if self.extra.bossAction then
                return
            end
            if Util.Math.chance(1 / 2) and self:planCellBossMove() then
                return
            end
            if self:prepareCellBossAttack() then
                return
            end
            self:planCellBossMove()
            return
        end
        local vertices = getAllValidVertices(G.flags.saveData.curRoom.size.w, G.flags.saveData.curRoom.size.h, {"wall", "enemy", "door"})
        local adjacents = getAllAdjacentVertices(vertices, {self.TMod.x.base,self.TMod.y.base})
        table.sort(adjacents, function (a, b)
            local v = Vector(PLAYER.TMod.x.base, PLAYER.TMod.y.base)
            local va, vb = Vector(a[1], a[2]):sub(v, true), Vector(b[1], b[2]):sub(v, true)
            return va:abs() < vb:abs()
        end)
        while #adjacents > 0 do
            local adjacent = adjacents[1]
            table.remove(adjacents, 1)
            local allEnemies = Util.World.getAllWorldMoveablesWithType("enemy")
            local hassamevertice = false
            for k,v in ipairs(allEnemies) do
                if  v ~= self and v.extra.goalVertice and v.extra.goalVertice[1] == adjacent[1] and v.extra.goalVertice[2] == adjacent[2] then
                    hassamevertice = true
                    break
                end
            end
            if not hassamevertice
                and not enemyTileIsBlocked(self, adjacent[1], adjacent[2])
            then
                self.extra.goalVertice = {adjacent[1], adjacent[2]}
                return
            end
        end
    end
end
function WorldMoveable:initRoomStuff()
    for _, v in ipairs(G.flags.saveData.curRoom.gates or {}) do
        WorldMoveable({
            x = v.x,
            y = v.y,
            type = "gate",
            extra = {
                locked = v.locked ~= false,
                dir = v.dir,
                identifier = v.id,
            },
            updateOrder = 2,
            drawOrder = 11
        })
    end
    for _, v in ipairs(G.flags.saveData.curRoom.keys or {}) do
        WorldMoveable({
            x = v.x,
            y = v.y,
            type = "pickup",
            extra = {
                itemKey = v.itemKey,
                identifier = v.id,
                collection = "keys",
            },
            updateOrder = 2,
            drawOrder = 10
        })
    end
    for _, v in ipairs(G.flags.saveData.curRoom.pickups or {}) do
        WorldMoveable({
            x = v.x,
            y = v.y,
            type = "pickup",
            extra = {
                itemKey = v.itemKey,
                identifier = v.id,
                collection = "pickups",
                requiresPlayerExit = v.requiresPlayerExit == true,
            },
            updateOrder = 2,
            drawOrder = 10
        })
    end
    for _, v in ipairs(G.flags.saveData.curRoom.covers or {}) do
        WorldMoveable({
            x = v.x,
            y = v.y,
            type = "cover",
            extra = {
                name = v.name,
            },
            updateOrder = 2,
            drawOrder = 11
        })
    end
    for k, v in ipairs(G.flags.saveData.curRoom.enemies) do
        local j = WorldMoveable({
            x = v.pos[1],
            y = v.pos[2],
            type = "enemy",
            extra = {
                index = v.index,
                side = v.side,
                name = v.name,
                hp = v.hp or Macros.maxHps[v.name],
                facing = v.facing,
                identifier = v.id,
                downedTurns = v.downedTurns,
                killCredited = v.killCredited,
                shotsRemaining = isRangedEnemyName(v.name)
                    and Macros[v.name].magazine
                    or nil,
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
        local direction = Util.World.getWallDirection(G.flags.saveData.curRoom, v)
        WorldMoveable({
            x = v.x,
            y = v.y,
            type = "wall",
            extra = {
                index = v.index,
                side = v.side,
                name = v.name,
                dir = direction,
            },
            updateOrder = 2,
            drawOrder = 11
        })
    end
end

Macros.MDef = {}
function getClosestPointAndDistance()
    local m = Util.Math.get2dMatrixInverse(Matrix(
    { Macros.baseTileSize * Util.UI.getScalingFactor(), 0.5 * Macros.baseTileSize * Util.UI.getScalingFactor() },
        { -1 * Macros.baseTileSize * Util.UI.getScalingFactor(), 0.5 * Macros.baseTileSize *
        Util.UI.getScalingFactor() }))
    local mousePos = m:apply(Vector(love.mouse.getX(), love.mouse.getY()):sub(Vector(G.drawinfo.origin.x,
        G.drawinfo.origin.y):add(G.worldOffsetVector, true), true), true)
    local closestPoint = Vector(Util.Math.round(mousePos.contents[1]-0.2)+0.2, Util.Math.round(mousePos.contents[2]-0.2)+0.2)
    local r = Util.World.toIsoPos(closestPoint):sub(Vector(love.mouse.getX(), love.mouse.getY()), true)
    return closestPoint, r:abs()
end
function Macros.MDef.isometricGrid(w, h, area)
    local phi1, phi2, chi, a1, a2 = math.betterrandom(0.5, 1.1), math.betterrandom(0.5, 1.1),
    math.betterrandom(0, math.tau), math.betterrandom(1, 2), math.betterrandom(1, 2)
    w = w or 4
    h = h or 7
    local deltawV = Util.World.toIsoPos(Vector(w - 1, 0)):sub(Util.World.toIsoPos(Vector(0, h - 1)), true)
    local ddeltawV = Util.World.toIsoPos(Vector(h - 1, 0)):sub(Util.World.toIsoPos(Vector(0, 0)), true)
    local deltahV = Util.World.toIsoPos(Vector(0, 0)):sub(Util.World.toIsoPos(Vector(w - 1, h - 1)), true)
    local dw = math.abs(deltawV.contents[1])
    local ddw = math.abs(ddeltawV.contents[1])
    local dh = math.abs(deltahV.contents[2])
    local ww = G.drawinfo.gridUnit * Macros.screenDimentions.x * Macros.gridSingleSubdivision
    local hh = G.drawinfo.gridUnit * Macros.screenDimentions.y * Macros.gridSingleSubdivision
    G.worldOffsetVector = Vector((ww - dw) / 2 + ddw, (hh - dh) / 2)

    local room = G.flags.saveData.curRoom
    local tileAreaFallbacks = {
        ruins = "prison",
    }
    local function hasFloor(x, y)
        return Util.World.isFloor(room, x, y)
    end
    local function getTileAtlasKey(x, y, suffix)
        local tileArea = room.tileAreas
            and room.tileAreas[x]
            and room.tileAreas[x][y]
            or area
        local atlasKey = tileArea..suffix
        if Atlases[atlasKey] then
            return atlasKey
        end
        local substituteArea = tileAreaFallbacks[tileArea]
        if substituteArea and Atlases[substituteArea..suffix] then
            return substituteArea..suffix
        end

        local fallbackArea = room.transition
            and room.transition.fromArea
            or area
        atlasKey = fallbackArea..suffix
        if Atlases[atlasKey] then
            return atlasKey
        end
        return (Atlases["grass"..suffix] and "grass" or "prison")
            ..suffix
    end
    local function makeTileSprites(suffix, chance)
        local sprites = {}
        for x = 0, w - 1 do
            for y = 0, h - 1 do
                local include = not chance
                    or (room.layout == "transition"
                        and (x * 3 + y * 5) % 4 == 0)
                    or (room.layout ~= "transition"
                        and Util.Math.chance(chance))
                if hasFloor(x, y) and include then
                    local vertex = Util.World.toIsoPos(Vector(x, y))
                    sprites[#sprites + 1] = {
                        pos = { x, y },
                        sprite = Sprite {
                            scaleX = 2,
                            scaleY = 2,
                            atlasKey = getTileAtlasKey(x, y, suffix),
                            x = vertex.contents[1] + G.drawinfo.gridUnit,
                            y = vertex.contents[2] - G.drawinfo.gridUnit / 20,
                            worldCoords = false,
                            drawOrder = chance and 4 or 3,
                        }
                    }
                end
            end
        end
        return sprites
    end
    local function makeEdgeSprites(edge, dx, dy)
        local sprites = {}
        for x = 0, w - 1 do
            for y = 0, h - 1 do
                if hasFloor(x, y) and not hasFloor(x + dx, y + dy) then
                    local vertex = Util.World.toIsoPos(Vector(x, y))
                    sprites[#sprites + 1] = {
                        pos = { x, y },
                        sprite = Sprite {
                            scaleX = 2,
                            scaleY = 2,
                            atlasKey = getTileAtlasKey(
                                x,
                                y,
                                "Edge"..edge
                            ),
                            x = vertex.contents[1] + G.drawinfo.gridUnit,
                            y = vertex.contents[2] - G.drawinfo.gridUnit / 20,
                            worldCoords = false,
                            drawOrder = 4,
                        }
                    }
                end
            end
        end
        return sprites
    end

    local t1 = {
        nid = "isoGrid",
        extra = {
            w = w,
            h = h,
            sprites = {
                base = makeTileSprites("Base"),
                foley = makeTileSprites("Foley", 1 / 4),
                edge = {
                    makeEdgeSprites(1, -1, 0),
                    makeEdgeSprites(2, 0, 1),
                    makeEdgeSprites(3, 1, 0),
                    makeEdgeSprites(4, 0, -1),
                }
            }
        },
        updateOrder = 0,
        drawOrder = 8,
        updateFunc = function(s, dt)
            local vec = Vector(a1 * math.sin(phi1 * G.timer) * Util.UI.getScalingFactor(), a2 * math.sin(phi2 * (chi + G.timer))* Util.UI.getScalingFactor())
            local deltawV = Util.World.toIsoPos(Vector(s.extra.w - 1, 0)):sub(Util.World.toIsoPos(Vector(0, s.extra.h - 1)), true)
            local ddeltawV = Util.World.toIsoPos(Vector(s.extra.h - 1, 0)):sub(Util.World.toIsoPos(Vector(0, 0)), true)
            local deltahV = Util.World.toIsoPos(Vector(0, 0)):sub(Util.World.toIsoPos(Vector(s.extra.w - 1, s.extra.h - 1)), true)
            local dw = math.abs(deltawV.contents[1])
            local ddw = math.abs(ddeltawV.contents[1])
            local dh = math.abs(deltahV.contents[2])
            local w = G.drawinfo.gridUnit * Macros.screenDimentions.x * Macros.gridSingleSubdivision
            local h = G.drawinfo.gridUnit * Macros.screenDimentions.y * Macros.gridSingleSubdivision
            G.worldOffsetVector = Vector((w-dw)/2+ddw,(h-dh)/2):add(vec, true)
            for k, venue in pairs(s.extra.sprites) do
                if k ~= "edge" then
                    for kk, obj in ipairs(venue) do
                        obj.sprite.T.x = Util.World.toIsoPos(Vector(obj.pos[1], obj.pos[2])).contents[1] - G.drawinfo.gridUnit
                        obj.sprite.T.y = Util.World.toIsoPos(Vector(obj.pos[1], obj.pos[2])).contents[2] - G.drawinfo.gridUnit/20
                    end
                else
                    for kk, subvenue in ipairs(venue) do
                        for kkk, obj in ipairs(subvenue) do
                            obj.sprite.T.x = Util.World.toIsoPos(Vector(obj.pos[1], obj.pos[2])).contents[1] - G.drawinfo.gridUnit
                            obj.sprite.T.y = Util.World.toIsoPos(Vector(obj.pos[1], obj.pos[2])).contents[2] - G.drawinfo.gridUnit/20
                        end
                    end
                end
            end
        end,
        drawFunc = function (s)
            if G.debug.drawIsoGrid then
                love.graphics.setColor(Macros.colors.green)
                for i = 1, s.extra.w do
                    for j = 1, s.extra.h do
                        local x = i - 1
                        local y = j - 1
                        if hasFloor(x, y) then
                            local vertices = {
                                Util.World.toIsoPos(Vector(x, y)),
                                Util.World.toIsoPos(Vector(x+1, y)),
                                Util.World.toIsoPos(Vector(x+1, y+1)),
                                Util.World.toIsoPos(Vector(x, y+1)),
                            }
                            Util.Draw.drawVectorPolygon("line", vertices)
                        end
                    end
                end
            end
        end
    }
    local function tryPlanMove(grid, dx, dy)
        if not PLAYER or G.flags.isMoving then
            return false
        end

        local path = grid.extra.path
        local last = path[#path].coords
        local targetX = Util.Math.round(last[1] - 0.2) + dx
        local targetY = Util.Math.round(last[2] - 0.2) + dy
        local targetCoords = { targetX + 0.2, targetY + 0.2 }

        if #path > 1 then
            local previous = path[#path - 1].coords
            if previous[1] == targetCoords[1] and previous[2] == targetCoords[2] then
                table.remove(path)
                grid.extra.drawAlpha = 1
                return true
            end
        end

        for index = 2, #path do
            if path[index].statuePush then
                return false
            end
        end

        local vertices = getAllValidVertices(w, h, { "wall", "enemy" })
        local statue = Util.World.getStatueAt(targetX, targetY)
        local statuePush
        if statue then
            local destinationX = targetX + dx
            local destinationY = targetY + dy
            if not Util.World.canPushStatueTo(
                statue,
                destinationX,
                destinationY
            ) then
                return false
            end
            statuePush = {
                identifier = statue.extra.identifier,
                fromX = targetX,
                fromY = targetY,
                toX = destinationX,
                toY = destinationY,
            }
        elseif not isValidVertice(vertices, { targetX, targetY }) then
            return false
        end

        local hasEnemies = #Util.World.getAllWorldMoveablesWithType("enemy") > 0
        if hasEnemies and #path >= G.flags.saveData.gridsPerMove + 1 then
            return false
        end

        for _, point in ipairs(path) do
            if point.coords[1] == targetCoords[1] and point.coords[2] == targetCoords[2] then
                return false
            end
        end

        table.insert(path, {
            point = Vector(targetCoords[1], targetCoords[2]),
            coords = targetCoords,
            statuePush = statuePush,
        })
        grid.extra.drawAlpha = 1
        return true
    end

    local t2 = {
        extra = {
            w = w,
            h = h,
            drawAlpha = 0,
            held = false,
            tryPlanMove = tryPlanMove,
            path = {
                { point = Vector(PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2), coords = { PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2 } }
            }
        },
        nid = "isoGridWeb",
        drawOrder = 10,
        updateOrder = 1,
        updateFunc = function (s, dt)
            s.extra.path[1] = {point = Vector(PLAYER.TMod.x.base+0.2, PLAYER.TMod.y.base+0.2), coords = {PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2}}
            if PLAYER then
                local vector = Util.World.toIsoPos(Vector(PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2))
                local mousePos = Vector(love.mouse.getX(), love.mouse.getY())
                local r = vector:sub(mousePos, true):abs()
                local max = 30
                local min = 20
                if s.extra.held then
                    if G.mouseController[1].released then
                        s.extra.held = false
                    end
                    s.extra.drawAlpha = 1
                    local p, rr = getClosestPointAndDistance()
                    if rr < min and not G.flags.isMoving then
                        local last = s.extra.path[#s.extra.path].coords
                        local dx = Util.Math.round(p.contents[1] - 0.2)
                            - Util.Math.round(last[1] - 0.2)
                        local dy = Util.Math.round(p.contents[2] - 0.2)
                            - Util.Math.round(last[2] - 0.2)
                        if math.abs(dx) + math.abs(dy) == 1 then
                            s.extra.tryPlanMove(s, dx, dy)
                        end
                    end
                elseif #s.extra.path > 1 then
                    s.extra.drawAlpha = 1
                    if G.mouseController[1].pressed then
                        s.extra.held = true
                    end
                else
                    if r > max then
                        s.extra.drawAlpha = Util.Math.lerpDt(s.extra.drawAlpha, 0, 0.005)
                    elseif r < min then
                        s.extra.drawAlpha = Util.Math.lerpDt(s.extra.drawAlpha, 1, 0.005)
                        if G.mouseController[1].pressed then
                            s.extra.held = true
                        end
                    else
                        s.extra.drawAlpha = Util.Math.lerpDt(s.extra.drawAlpha, 1 - (r - min) / (max - min), 0.005)
                    end
                end
            else
                s.extra.drawAlpha = 0
            end
        end,
        drawFunc = function (s)
            love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.night, 0.1 * s.extra.drawAlpha))
            local vertices = getAllValidVertices(w, h)
            for x, v in pairs(vertices) do
                for y, _ in pairs(v) do
                    local c = {x, y}
                    local adjacents = getAllAdjacentVertices(vertices, c)
                    local vv = Util.World.toIsoPos(Vector(x+0.5, y+0.5))
                    for k, vr in ipairs(adjacents) do
                        local vrv = Util.World.toIsoPos(Vector(vr[1] + 0.5, vr[2] + 0.5))
                        love.graphics.line(vv.contents[1], vv.contents[2], vrv.contents[1], vrv.contents[2])
                    end
                end
            end
            love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.white, s.extra.drawAlpha))
            for x, v in pairs(vertices) do
                for y, _ in pairs(v) do
                    local c = { x, y }
                    local adjacents = getAllAdjacentVertices(vertices, c)
                    local vv = Util.World.toIsoPos(Vector(x + 0.2, y + 0.2))
                    for k, vr in ipairs(adjacents) do
                        local vrv = Util.World.toIsoPos(Vector(vr[1] + 0.2, vr[2] + 0.2))
                        love.graphics.line(vv.contents[1], vv.contents[2], vrv.contents[1], vrv.contents[2])
                    end
                    love.graphics.circle("fill", vv.contents[1], vv.contents[2], 3 * Util.UI.getScalingFactor())
                end
            end
            love.graphics.setLineWidth(2.5 * Util.UI.getScalingFactor())
            local function isDangerousPathPoint(point)
                return Util.World.isPositionInTurretSightline(
                    Util.Math.round(point.coords[1] - 0.2),
                    Util.Math.round(point.coords[2] - 0.2)
                )
            end
            for i = 1, #s.extra.path - 1 do
                local dangerous = isDangerousPathPoint(s.extra.path[i])
                    or isDangerousPathPoint(s.extra.path[i + 1])
                love.graphics.setColor(dangerous
                    and Macros.colors.darkRed
                    or Macros.colors.darkGreen)
                local grp = { Util.World.toIsoPos(s.extra.path[i].point), Util.World.toIsoPos(s.extra.path[i + 1].point) }
                love.graphics.line(grp[1].contents[1], grp[1].contents[2], grp[2].contents[1], grp[2].contents[2])
            end
            if s.extra.held then
                love.graphics.setColor(Macros.colors.white)
                local grp = { Util.World.toIsoPos(s.extra.path[#s.extra.path].point), Vector(love.mouse.getX(),
                love.mouse.getY()) }
                if grp[1]:sub(grp[2], true):abs() < 100 * Util.UI.getScalingFactor() then
                    love.graphics.line(grp[1].contents[1], grp[1].contents[2], grp[2].contents[1], grp[2].contents[2])
                end
            end
            love.graphics.setLineWidth(1.5 * Util.UI.getScalingFactor())
            for _, point in ipairs(s.extra.path) do
                love.graphics.setColor(isDangerousPathPoint(point)
                    and Macros.colors.red
                    or Macros.colors.green)
                local vector = Util.World.toIsoPos(point.point)
                love.graphics.circle("fill", vector.contents[1], vector.contents[2],
                    4 * Util.UI.getScalingFactor())
            end
        end
    }
    local m1 = Moveable(t1)
    local m2 = Moveable(t2)
    local old = m1.remove
    function m1:remove(...)
        for k, venue in pairs(self.extra.sprites) do
            if k ~= "edge" then
                for kk, obj in ipairs(venue) do
                    obj.sprite:remove()
                end
            else
                for kk, subvenue in ipairs(venue) do
                    for kkk, obj in ipairs(subvenue) do
                        obj.sprite:remove()
                    end
                end
            end
        end
        return old(self, ...)
    end
    return m1, m2
end

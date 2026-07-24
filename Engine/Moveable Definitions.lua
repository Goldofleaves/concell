Macros.MDef = {}
function Macros.MDef.isometricGrid(w, h)
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
    local t1 = {
        nid = "isoGrid",
        extra = {
            w = w,
            h = h,
            sprites = {
                base = (function ()
                    local t = {}
                    for x = 0, w - 1 do
                        for y = 0, h - 1 do
                            local vertex = Util.World.toIsoPos(Vector(x, y))
                            table.insert(t, {
                                pos = { x, y },
                                sprite = Sprite {
                                    scaleX = 2,
                                    scaleY = 2,
                                    atlasKey = "grassBase",
                                    x = vertex.contents[1] + G.drawinfo.gridUnit,
                                    y = vertex.contents[2] - G.drawinfo.gridUnit / 20,
                                    worldCoords = false,
                                    drawOrder = 3
                                }
                            })
                        end
                    end
                    return t
                end)(),
                foley = (function()
                    local t = {}
                    for x = 0, w - 1 do
                        for y = 0, h - 1 do
                            if Util.Math.chance(1/4) then
                                local vertex = Util.World.toIsoPos(Vector(x, y))
                                table.insert(t, {
                                    pos = { x, y },
                                    sprite = Sprite {
                                        scaleX = 2,
                                        scaleY = 2,
                                        atlasKey = "grassFoley",
                                        x = vertex.contents[1] + G.drawinfo.gridUnit,
                                        y = vertex.contents[2] - G.drawinfo.gridUnit / 20,
                                        worldCoords = false,
                                        drawOrder = 4
                                    }
                                })
                            end
                        end
                    end
                    return t
                end)(),
                edge = {
                    (function()
                        local t = {}
                        for y = 0, h - 1 do
                            local vertex = Util.World.toIsoPos(Vector(0, y))
                            table.insert(t, {
                                pos = { 0, y },
                                sprite = Sprite {
                                    scaleX = 2,
                                    scaleY = 2,
                                    atlasKey = "grassEdge1",
                                    x = vertex.contents[1] + G.drawinfo.gridUnit,
                                    y = vertex.contents[2] - G.drawinfo.gridUnit / 20,
                                    worldCoords = false,
                                    drawOrder = 4
                                }
                            })
                        end
                        return t
                    end)(),
                    (function()
                        local t = {}
                        for x = 0, w - 1 do
                            local vertex = Util.World.toIsoPos(Vector(x, h-1))
                            table.insert(t, {
                                pos = { x, h-1 },
                                sprite = Sprite {
                                    scaleX = 2,
                                    scaleY = 2,
                                    atlasKey = "grassEdge2",
                                    x = vertex.contents[1] + G.drawinfo.gridUnit,
                                    y = vertex.contents[2] - G.drawinfo.gridUnit / 20,
                                    worldCoords = false,
                                    drawOrder = 4
                                }
                            })
                        end
                        return t
                    end)(),
                    (function()
                        local t = {}
                        for y = 0, h - 1 do
                            local vertex = Util.World.toIsoPos(Vector(w-1, y))
                            table.insert(t, {
                                pos = { w - 1, y },
                                sprite = Sprite {
                                    scaleX = 2,
                                    scaleY = 2,
                                    atlasKey = "grassEdge3",
                                    x = vertex.contents[1] + G.drawinfo.gridUnit,
                                    y = vertex.contents[2] - G.drawinfo.gridUnit / 20,
                                    worldCoords = false,
                                    drawOrder = 4
                                }
                            })
                        end
                        return t
                    end)(),
                    (function()
                        local t = {}
                        for x = 0, w - 1 do
                            local vertex = Util.World.toIsoPos(Vector(x, 0))
                            table.insert(t, {
                                pos = { x, 0 },
                                sprite = Sprite {
                                    scaleX = 2,
                                    scaleY = 2,
                                    atlasKey = "grassEdge4",
                                    x = vertex.contents[1] + G.drawinfo.gridUnit,
                                    y = vertex.contents[2] - G.drawinfo.gridUnit / 20,
                                    worldCoords = false,
                                    drawOrder = 4
                                }
                            })
                        end
                        return t
                    end)()
                }
            }
        },
        updateOrder = 0,
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
    }
    local function getClosestPointAndDistance()
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
    local t2 = {
        extra = {
            w = w,
            h = h,
            drawAlpha = 0,
            held = false,
            path = {
                { point = Vector(PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2), coords = { PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2 } }
            }
        },
        nid = "isoGridWeb",
        drawOrder = 10,
        updateOrder = 1,
        updateFunc = function (s, dt)
            local function alreadyExists(coords, k)
                for kk, v in ipairs(s.extra.path) do
                    if v.coords[1] == coords[1] and v.coords[2] == coords[2] and kk ~= k then
                        return true
                    end
                end
                return false
            end
            local function existsDoor(coords)
                for k, v in pairs(G.I.MOVEABLES) do
                    if v.objectType == "WORLDMOVEABLE" then
                        if v.properties.type == "door" and Util.Math.precisionCheck(coords[1] - 0.2, v.TMod.x.base, 0.1) and Util.Math.precisionCheck(coords[2] - 0.2, v.TMod.y.base, 0.1) then
                            return true
                        end
                    end
                end
                return false
            end
            local function getDoor(coords)
                for k, v in pairs(G.I.MOVEABLES) do
                    if v.objectType == "WORLDMOVEABLE" then
                        if v.properties.type == "door" and Util.Math.precisionCheck(coords[1] - 0.2, v.TMod.x.base, 0.1) and Util.Math.precisionCheck(coords[2] - 0.2, v.TMod.y.base, 0.1) then
                            return v
                        end
                    end
                end
            end
            local function isAdjacent(coords)
                if Vector(unpack(s.extra.path[#s.extra.path].coords)):sub(Vector(unpack(coords)),true):abs() <= 1.1 then
                    return true
                end
                return false
            end
            s.extra.path[1] = {point = Vector(PLAYER.TMod.x.base+0.2, PLAYER.TMod.y.base+0.2), coords = {PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2}}
            if PLAYER then
                local vector = Util.World.toIsoPos(Vector(PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2))
                local mousePos = Vector(love.mouse.getX(), love.mouse.getY())
                local r = vector:sub(mousePos, true):abs()
                local max = 30
                local min = 10
                if s.extra.held then
                    if G.mouseController[1].released then
                        s.extra.held = false
                    end
                    s.extra.drawAlpha = 1
                    local p, rr = getClosestPointAndDistance()
                    if rr < min and
                    (p.contents[1] >= 0 and
                    p.contents[1] <= G.flags.saveData.curRoom.size.w and
                    p.contents[2] >= 0 and
                    p.contents[2] <= G.flags.saveData.curRoom.size.h)
                    or existsDoor(p.contents)
                    then
                        if not alreadyExists(p.contents) and isAdjacent(p.contents) then
                            table.insert(s.extra.path, { point = p, coords = p.contents })
                        end
                        if alreadyExists(p.contents) and isAdjacent(p.contents) and #s.extra.path>1 and
                        p.contents[1] == s.extra.path[#s.extra.path-1].coords[1] and p.contents[2] == s.extra.path[#s.extra.path-1].coords[2] then
                            table.remove(s.extra.path,#s.extra.path)
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
            if G.controller.select.pressed then
                PLAYER.TMod.x.base = Util.Math.round(s.extra.path[#s.extra.path].coords[1] - 0.2)
                PLAYER.TMod.y.base = Util.Math.round(s.extra.path[#s.extra.path].coords[2] - 0.2)
                if getDoor(s.extra.path[#s.extra.path].coords) then
                    getDoor(s.extra.path[#s.extra.path].coords):switchRoom()
                end
                s.extra.path = {
                    { point = Vector(PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2), coords = { PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2 } }
                }
                PLAYER:juice()
            end
            if G.controller.cancel.pressed then
                s.extra.path = {
                    { point = Vector(PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2), coords = { PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2 } }
                }
            end
        end,
        drawFunc = function (s)
            love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.night, 0.1 * s.extra.drawAlpha))
            for i = 1, s.extra.w - 1 do
                for j = 1, s.extra.h - 1 do
                    local x = i - 1 + 0.5
                    local y = j - 1 + 0.5
                    local vertices = {
                        Util.World.toIsoPos(Vector(x, y)),
                        Util.World.toIsoPos(Vector(x + 1, y)),
                        Util.World.toIsoPos(Vector(x + 1, y + 1)),
                        Util.World.toIsoPos(Vector(x, y + 1)),
                    }
                    Util.Draw.drawVectorPolygon("line", vertices)
                end
            end
            Util.Draw.drawVectorPolygon("line", {
                Util.World.toIsoPos(Vector(0.5, 0.5)),
                Util.World.toIsoPos(Vector(0.5, h - 0.5)),
                Util.World.toIsoPos(Vector(w - 0.5, h - 0.5)),
                Util.World.toIsoPos(Vector(w - 0.5, 0.5)),
            })
            love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.white, s.extra.drawAlpha))
            for i = 1, s.extra.w - 1 do
                for j = 1, s.extra.h - 1 do
                    local x = i - 1 + 0.2
                    local y = j - 1 + 0.2
                    local vertices = {
                        Util.World.toIsoPos(Vector(x, y)),
                        Util.World.toIsoPos(Vector(x + 1, y)),
                        Util.World.toIsoPos(Vector(x + 1, y + 1)),
                        Util.World.toIsoPos(Vector(x, y + 1)),
                    }
                    Util.Draw.drawVectorPolygon("line", vertices)
                    for k, v in ipairs(vertices) do
                        love.graphics.circle("fill", v.contents[1], v.contents[2], 3 * Util.UI.getScalingFactor())
                    end
                end
            end
            love.graphics.setLineWidth(2.5 * Util.UI.getScalingFactor())
            love.graphics.setColor(Macros.colors.darkRed)
            for i = 1, #s.extra.path - 1 do
                local grp = { Util.World.toIsoPos(s.extra.path[i].point), Util.World.toIsoPos(s.extra.path[i + 1].point) }
                love.graphics.line(grp[1].contents[1], grp[1].contents[2], grp[2].contents[1], grp[2].contents[2])
            end
            if s.extra.held then
                local grp = { Util.World.toIsoPos(s.extra.path[#s.extra.path].point), Vector(love.mouse.getX(),
                love.mouse.getY()) }
                love.graphics.line(grp[1].contents[1], grp[1].contents[2], grp[2].contents[1], grp[2].contents[2])
                love.graphics.setLineWidth(1.5 * Util.UI.getScalingFactor())
            end
            love.graphics.setColor(Macros.colors.red)
            for i = 1, #s.extra.path - 1 do
                local grp = { Util.World.toIsoPos(s.extra.path[i].point), Util.World.toIsoPos(s.extra.path[i + 1].point) }
                love.graphics.circle("fill", grp[1].contents[1], grp[1].contents[2], 4 * Util.UI.getScalingFactor())
            end
            love.graphics.circle("fill", Util.World.toIsoPos(s.extra.path[#s.extra.path].point).contents[1],
                Util.World.toIsoPos(s.extra.path[#s.extra.path].point).contents[2], 4 * Util.UI.getScalingFactor())
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
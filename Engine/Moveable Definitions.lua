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
    local t = {
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
                                    y = vertex.contents[2] - G.drawinfo.gridUnit / 21,
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
                                        y = vertex.contents[2] - G.drawinfo.gridUnit / 21,
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
                                    y = vertex.contents[2] - G.drawinfo.gridUnit / 21,
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
                                    y = vertex.contents[2] - G.drawinfo.gridUnit / 21,
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
                                    y = vertex.contents[2] - G.drawinfo.gridUnit / 21,
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
                                    y = vertex.contents[2] - G.drawinfo.gridUnit / 21,
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
        drawOrder = 5,
        updateFunc = function (s, dt)
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
                        obj.sprite.T.y = Util.World.toIsoPos(Vector(obj.pos[1], obj.pos[2])).contents[2] - G.drawinfo.gridUnit/21
                    end
                else
                    for kk, subvenue in ipairs(venue) do
                        for kkk, obj in ipairs(subvenue) do
                            obj.sprite.T.x = Util.World.toIsoPos(Vector(obj.pos[1], obj.pos[2])).contents[1] - G.drawinfo.gridUnit
                            obj.sprite.T.y = Util.World.toIsoPos(Vector(obj.pos[1], obj.pos[2])).contents[2] - G.drawinfo.gridUnit/21
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
    local m = Moveable(t)
    return m
end
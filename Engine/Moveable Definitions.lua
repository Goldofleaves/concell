Macros.MDef = {}
function Macros.MDef.isometricGrid()
    local t = {
        extra = {
            w = 4,
            h = 7,
        },
        updateFunc = function (s, dt)
            local deltawV = Util.World.toIsoPos(Vector(s.extra.w - 1, 0)):sub(Util.World.toIsoPos(Vector(0, s.extra.h - 1)), true)
            local ddeltawV = Util.World.toIsoPos(Vector(s.extra.h - 1, 0)):sub(Util.World.toIsoPos(Vector(0, 0)), true)
            local deltahV = Util.World.toIsoPos(Vector(0, 0)):sub(Util.World.toIsoPos(Vector(s.extra.w - 1, s.extra.h - 1)), true)
            local dw = math.abs(deltawV.contents[1])
            local ddw = math.abs(ddeltawV.contents[1])
            local dh = math.abs(deltahV.contents[2])
            local w = G.drawinfo.gridUnit * Macros.screenDimentions.x * Macros.gridSingleSubdivision
            local h = G.drawinfo.gridUnit * Macros.screenDimentions.y * Macros.gridSingleSubdivision
            G.worldOffsetVector = Vector((w-dw)/2+ddw,(h-dh)/2)
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
    return Moveable(t)
end
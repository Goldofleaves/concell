Macros.MDef = {}
function Macros.MDef.isometricGrid()
    local t = {
        extra = {
            w = 10,
            h = 10
        },
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
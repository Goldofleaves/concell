Macros.MDef = {}
local isoMatrix = Matrix({1, 0.5}, {-1, 0.5})
function Macros.MDef.isometricGrid()
    local t = {
        extra = {
            w = 10,
            h = 10
        },
        drawFunc = function (s)
            local shift = Vector(G.drawinfo.origin.x, G.drawinfo.origin.y)
            local iHat, jHat = Vector(G.drawinfo.gridUnit, 0), Vector(0, G.drawinfo.gridUnit)
            isoMatrix:apply(iHat)
            isoMatrix:apply(jHat)
            if G.debug.drawIsoGrid then
                love.graphics.setColor(Macros.colors.green)
                for i = 1, s.extra.w do
                    for j = 1, s.extra.h do
                        local x = i - 1
                        local y = j - 1
                        local vertices = {
                            shift:add(iHat:scale(x, true):add(jHat:scale(y,true),true),true),
                            shift:add(iHat:scale(x + 1, true):add(jHat:scale(y, true), true),true),
                            shift:add(iHat:scale(x + 1, true):add(jHat:scale(y + 1, true), true),true),
                            shift:add(iHat:scale(x, true):add(jHat:scale(y + 1, true), true), true),
                        }
                        Util.Draw.drawVectorPolygon("line", vertices)
                    end
                end
            end
        end
    }
    return Moveable(t)
end
Util.World = {}
---comment
---@param V Vector
function Util.World.toIsoPos(V)
    local isoMatrix = Matrix({1 * G.drawinfo.gridUnit, 0.5 * G.drawinfo.gridUnit}, {-1 * G.drawinfo.gridUnit, 0.5 * G.drawinfo.gridUnit})
    local offset = Vector(G.drawinfo.origin.x, G.drawinfo.origin.y):add(G.worldOffsetVector, true)
    return offset:add(isoMatrix:apply(V, true), true)
end
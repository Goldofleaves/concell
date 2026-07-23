Util.World = {}
---comment
---@param V Vector
function Util.World.toIsoPos(V)
    local isoMatrix = Matrix({Macros.baseTileSize * Util.UI.getScalingFactor(), 0.5 * Macros.baseTileSize * Util.UI.getScalingFactor()}, {-1 * Macros.baseTileSize * Util.UI.getScalingFactor(), 0.5 * Macros.baseTileSize * Util.UI.getScalingFactor()})
    local offset = Vector(G.drawinfo.origin.x, G.drawinfo.origin.y):add(G.worldOffsetVector, true)
    return offset:add(isoMatrix:apply(V, true), true)
end

function Util.World.toNormalPos(V)
    local isoMatrix = Matrix({ Macros.baseTileSize * Util.UI.getScalingFactor(), 0 }, { 0, Macros.baseTileSize * Util.UI.getScalingFactor() })
    local offset = Vector(G.drawinfo.origin.x, G.drawinfo.origin.y):add(G.worldOffsetVector, true)
    return offset:add(isoMatrix:apply(V, true), true)
end

WorldMoveable = Moveable:extend()
function WorldMoveable:new(args)
    Moveable.new(self, args)
    self.objectType = "WORLDMOVEABLE"
    self.properties.type = args.type or "door"
end

function WorldMoveable:draw(args)
    local lookup = {
        door = {
            color = Macros.colors.orange,
            radius = 5
        },
        player = {
            color = Macros.colors.blue,
            radius = 5
        },
    }
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(lookup[self.properties.type].color)
    local vector = Util.World.toIsoPos(Vector(self.TMod.x.base + 0.2, self.TMod.y.base + 0.2))
    love.graphics.circle("fill", vector.contents[1], vector.contents[2], lookup[self.properties.type].radius)
    love.graphics.setColor(r,g,b,a)
end
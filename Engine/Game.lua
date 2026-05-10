---@class Game: Object
Game = Object:extend()

function Game:new()
    self.timer = 0
    G = self
    return self
end
function Game:update(dt)
    self.timer = self.timer + dt
    
end
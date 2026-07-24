WorldMoveable = Moveable:extend()
function WorldMoveable:new(args)
    Moveable.new(self, args)
    self.objectType = "WORLDMOVEABLE"
    self.properties.type = args.type or "door"
    self.properties.mult = 1
    return self
end
function WorldMoveable:juice(r)
    r = r or 2
    Util.Event.addEvent(
        Event({
            duration = 0.3,
            easeFunc = function (t, s)
                self.properties.mult = Util.EaseSplines.createEase(r, 1, nil, {preset = "eoc"})(t)
            end,
            endFunc = function(s)
                self.properties.mult = 1
            end
        }),"juice"
    )
end
function WorldMoveable:draw()
    Moveable.draw(self)
    local lookup = {
        door = {
            color = Macros.colors.orange,
            radius = 5 * self.properties.mult
        },
        player = {
            color = Macros.colors.red,
            radius = 5 * self.properties.mult
        },
    }
    local r, g, b, a = love.graphics.getColor()
    local vector = Util.World.toIsoPos(Vector(self.TMod.x.base + 0.2, self.TMod.y.base + 0.2))
    love.graphics.setColor(Macros.colors.night)
    love.graphics.circle("fill", vector.contents[1], vector.contents[2], (lookup[self.properties.type].radius+2)*Util.UI.getScalingFactor())
    love.graphics.setColor(lookup[self.properties.type].color)
    love.graphics.circle("fill", vector.contents[1], vector.contents[2], lookup[self.properties.type].radius*Util.UI.getScalingFactor())
    if self.properties.type == "door" then
        AdvancedText("|c:orange|"..tostring(self.extra.index)):draw(vector.contents[1], vector.contents[2] + 6)
    end
    love.graphics.setColor(r,g,b,a)
end

function WorldMoveable:switchRoom()
    if self.properties.type == "door" then
        Util.Event.transition(2, function()
            G.flags.saveData.curRoomIndex = self.extra.index
            G.flags.saveData.curRoom = G.flags.saveData.rooms[self.extra.index]
            Macros.MDef.isometricGrid(G.flags.saveData.curRoom.size.w, G.flags.saveData.curRoom.size.h, Util.World.getArea(self.extra.index))
            getObjectByNid("isoGrid"):remove()
            getObjectByNid("isoGridWeb"):remove()
            local list = {}
            for k, v in ipairs(G.I.MOVEABLES) do
                if v.objectType == "WORLDMOVEABLE" then
                    table.insert(list, v)
                end
            end
            PLAYER = WorldMoveable({
                x = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra.side)).x,
                y = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra.side)).y,
                type = "player",
                drawOrder = 14,
                updateOrder = 1
            })
            for k, v in ipairs(list) do
                v:remove()
            end
            for k, v in ipairs(G.flags.saveData.curRoom.doors) do
                WorldMoveable({
                    x = v.x,
                    y = v.y,
                    type = v.type,
                    extra = {
                        index = v.index,
                        side = v.side
                    },
                    updateOrder = 2
                })
            end
        end, "delay2")
    end
end
WorldMoveable = Moveable:extend()
function WorldMoveable:new(args)
    Moveable.new(self, args)
    self.objectType = "WORLDMOVEABLE"
    self.properties.type = args.type or "door"
    self.properties.mult = 1
end
function WorldMoveable:juice(r)
    r = r or 2
    Util.Event.addEvent(
        Event({
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
    love.graphics.setColor(lookup[self.properties.type].color)
    local vector = Util.World.toIsoPos(Vector(self.TMod.x.base + 0.2, self.TMod.y.base + 0.2))
    love.graphics.circle("fill", vector.contents[1], vector.contents[2], lookup[self.properties.type].radius*Util.UI.getScalingFactor())
    if self.properties.type == "door" then
        AdvancedText("|c:orange|"..tostring(self.extra.index)):draw(vector.contents[1], vector.contents[2] + 6)
    end
    love.graphics.setColor(r,g,b,a)
end

function WorldMoveable:update(dt)
    if self.properties.type == "door" then
        local vector = Util.World.toIsoPos(Vector(self.TMod.x.base + 0.2, self.TMod.y.base + 0.2))
        local mousePos = Vector(love.mouse.getX(), love.mouse.getY())
        local r = vector:sub(mousePos, true):abs()
        if G.mouseController[1].pressed and r < 5 then
            local function switchRoom()
                Util.Event.transition(2, function()
                    G.flags.saveData.curRoomIndex = self.extra.index
                    G.flags.saveData.curRoom = G.flags.saveData.rooms[self.extra.index]
                    PLAYER:remove()
                    PLAYER = WorldMoveable({
                        x = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra.side)).x,
                        y = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra.side)).y,
                        type = "player",
                        drawOrder = 11,
                        updateOrder = 1
                    })
                    Macros.MDef.isometricGrid(G.flags.saveData.curRoom.size.w, G.flags.saveData.curRoom.size.h)
                    getObjectByNid("isoGrid"):remove()
                    getObjectByNid("isoGridWeb"):remove()
                    local list = {}
                    for k, v in ipairs(G.I.MOVEABLES) do
                        if v.objectType == "WORLDMOVEABLE" then
                            table.insert(list, v)
                        end
                    end
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
            switchRoom()
        end
    end
end

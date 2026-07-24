WorldMoveable = Moveable:extend()
function WorldMoveable:new(args)
    Moveable.new(self, args)
    self.objectType = "WORLDMOVEABLE"
    self.properties.type = args.type or "door"
end

function WorldMoveable:draw()
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
    if self.properties.type == "door" then
        AdvancedText("|c:orange|"..tostring(self.extra.index)):draw(vector.contents[1], vector.contents[2] + 6)
    end
    love.graphics.setColor(r,g,b,a)
end

function WorldMoveable:update(dt)
    if self.properties.type == "player" then
        -- wip movement code
        if G.controller.left.pressed then
            self.TMod.x.base = math.max(self.TMod.x.base - 1, 0)
        end
        if G.controller.right.pressed then
            self.TMod.x.base = math.min(self.TMod.x.base + 1, G.flags.saveData.curRoom.size.w - 1)
        end
        if G.controller.up.pressed then
            self.TMod.y.base = math.max(self.TMod.y.base - 1, 0)
        end
        if G.controller.down.pressed then
            self.TMod.y.base = math.min(self.TMod.y.base + 1, G.flags.saveData.curRoom.size.h - 1)
        end
    end
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
                    PLAYER = WorldMoveable({
                        x = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra.side)).x,
                        y = Util.World.getDoorAdjacentPos(Util.World.getOppositeSideDoor(self.extra.side)).y,
                        type = "player",
                        drawOrder = 11,
                        updateOrder = 1
                    })
                end, "delay2")
            end
            switchRoom()
        end
        -- wip movement code
        if G.controller.left.pressed then
            if PLAYER and PLAYER.TMod.y.base == self.TMod.y.base and PLAYER.TMod.x.base == 0 then
                switchRoom()
            end
        end
        if G.controller.right.pressed then
            if PLAYER and PLAYER.TMod.y.base == self.TMod.y.base and PLAYER.TMod.x.base == G.flags.saveData.curRoom.size.w - 1 then
                switchRoom()

            end
        end
        if G.controller.up.pressed then
            if PLAYER and PLAYER.TMod.x.base == self.TMod.x.base and PLAYER.TMod.y.base == 0 then
                switchRoom()
            end
        end
        if G.controller.down.pressed then
            if PLAYER and PLAYER.TMod.x.base == self.TMod.x.base and PLAYER.TMod.y.base == G.flags.saveData.curRoom.size.h - 1 then
                switchRoom()
            end
        end
    end
end

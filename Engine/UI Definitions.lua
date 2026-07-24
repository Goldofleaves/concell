Macros.UIDef = {}
function Macros.UIDef.title()
    local phi1, phi2, chi, a1, a2 = math.betterrandom(0.5, 1.1), math.betterrandom(0.5, 1.1),
        math.betterrandom(0, math.tau), math.betterrandom(1, 2), math.betterrandom(1, 2)
    local phi3, phi4, chi2, a3, a4 = math.betterrandom(0.5, 1.1), math.betterrandom(0.5, 1.1),
        math.betterrandom(0, math.tau), math.betterrandom(1, 2), math.betterrandom(1, 2)
    Sprite({
        nid = "tbg",
        drawOrder = 1,
        x = Macros.grandOffsetVector.contents[1],
        y = Macros.grandOffsetVector.contents[2],
        atlasKey = "titlescreenBg",
        scaleX = 2,
        scaleY = 2
    })
    Sprite({
        nid = "tfg",
        drawOrder = 2,
        x = Macros.grandOffsetVector.contents[1],
        y = Macros.grandOffsetVector.contents[2],
        atlasKey = "titlescreenFg",
        scaleX = 2,
        scaleY = 2,
        updateFunc = function (s)
            s.T.x = Macros.grandOffsetVector.contents[1] + (a1 / 40 * math.sin(phi1 * G.timer))
            s.T.y = Macros.grandOffsetVector.contents[2] +a2/40 + (a2 / 40 * math.sin(phi2 * (G.timer + chi)))
        end
    })
    Sprite({
        nid = "td",
        drawOrder = 2,
        x = Macros.grandOffsetVector.contents[1],
        y = Macros.grandOffsetVector.contents[2],
        atlasKey = "titlescreenDawn",
        scaleX = 2,
        scaleY = 2,
        updateFunc = function(s)
            s.T.x = Macros.grandOffsetVector.contents[1] + (a3 / 40 * math.sin(phi3 * G.timer))
            s.T.y = Macros.grandOffsetVector.contents[2] + a4 / 40 + (a4 / 40 * math.sin(phi4 * (G.timer + chi2)))
        end
    })
    SimpleDrawableButton({
        nid = "titlebutton1",
        x = 13.5,
        y = 9.5,
        w = 5,
        h = 1,
        outlineWidth = 3,
        drawOrder = 10,
        outlineColor = Macros.colors.white,
        inlineColor = Macros.colors.lightBlack,
        extra = {
            text = AdvancedText("|s:2,2|New run")
        },
        updateFunc = function(self)
            if not self:isHovered() then
                self.TMod.x.base = Util.Math.lerpDt(self.TMod.x.base, 13.5, 0.05)
                self.TMod.y.base = Util.Math.lerpDt(self.TMod.y.base, 9.5, 0.05)
            else
                self.TMod.x.base = Util.Math.lerpDt(self.TMod.x.base, 11.5, 0.05)
                self.TMod.y.base = Util.Math.lerpDt(self.TMod.y.base, 9.25, 0.05)
            end
            local delta = 9.5 - self.TMod.y.base
            self.TMod.h.base = 1 + 2 * delta
            self.TMod.w.base = 1.25 * 13.5 + 5 - 1.25 * self.TMod.x.base
        end,
        drawFunc = function(self)
            local h = self.extra.text:getHeight()
            local delta = (1 - (self.TMod.y.base - 9.25) / 0.25) * 0.2
            local dh = delta * h / 40
            self.extra.text:recalculate({}, "|s:" .. (2 * (1 + 1.5 * delta)) ..
            "," .. (2 * (1 + 1.5 * delta)) .. "|New run")
            self.extra.text:draw(self.T.x + 0.25 + 2 * dh, 9.5 + 0.29 - dh, true)
        end,
        onClick = function(s)
            Util.Event.easeOutMusic(2, "titleID")
            Util.Event.transition(4, function()
                Macros.UIDef.overlay()
                Util.Event.easeInMusic(2, "overworld", "overworldID", "normal", nil, 2)
                local list_of_nids = {
                    "titlebutton1",
                    "titlebutton2",
                    "titlebutton3",
                    "tbg",
                    "tfg",
                    "td",
                }
                for k, v in pairs(list_of_nids) do
                    local o = getObjectByNid(v)
                    if o then o:remove() end
                end
                G.flags.saveData.rooms = Util.World.generateDungeon()
                G.flags.saveData.curRoomIndex = 1
                G.flags.saveData.curRoom = G.flags.saveData.rooms[1]
                PLAYER = WorldMoveable({
                    x = math.floor(G.flags.saveData.curRoom.size.w / 2),
                    y = math.floor(G.flags.saveData.curRoom.size.h / 2),
                    type = "player",
                    updateOrder = 1,
                    drawOrder = 11
                })
                Macros.MDef.isometricGrid(G.flags.saveData.curRoom.size.w, G.flags.saveData.curRoom.size.h, Util.World.getArea(1))
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
            end, "delay1")
        end,
        onHover = function()
            Util.Audio.playSfx("blip_hover", 2)
        end,
        onLeftHover = function()
            Util.Audio.playSfx("blip_unhover", 2)
        end
    })
    SimpleDrawableButton({
        nid = "titlebutton2",
        x = 13.5,
        y = 11,
        w = 5,
        h = 1,
        extra = {
            text = AdvancedText("|s:2,2|Resume run")
        },
        outlineWidth = 3,
        drawOrder = 10,
        outlineColor = Macros.colors.white,
        inlineColor = Macros.colors.lightBlack,
        updateFunc = function(self)
            if not self:isHovered() then
                self.TMod.x.base = Util.Math.lerpDt(self.TMod.x.base, 13.5, 0.05)
                self.TMod.y.base = Util.Math.lerpDt(self.TMod.y.base, 11, 0.05)
            else
                self.TMod.x.base = Util.Math.lerpDt(self.TMod.x.base, 11.5, 0.05)
                self.TMod.y.base = Util.Math.lerpDt(self.TMod.y.base, 10.75, 0.05)
            end
            local delta = 11 - self.TMod.y.base
            self.TMod.h.base = 1 + 2 * delta
            self.TMod.w.base = 1.25 * 13.5 + 5 - 1.25 * self.TMod.x.base
        end,
        drawFunc = function(self)
            local h = self.extra.text:getHeight()
            local delta = (1 - (self.TMod.y.base - 10.75) / 0.25) * 0.2
            local dh = delta * h / 40
            self.extra.text:recalculate({}, "|s:" .. (2 * (1 + 1.5 * delta)) ..
                "," .. (2 * (1 + 1.5 * delta)) .. "|Resume run")
            self.extra.text:draw(self.T.x + 0.25 + 2 * dh, 11 + 0.29 - dh, true)
        end,
        onHover = function()
            Util.Audio.playSfx("blip_hover", 2)
        end,
        onLeftHover = function()
            Util.Audio.playSfx("blip_unhover", 2)
        end
    })
    SimpleDrawableButton({
        nid = "titlebutton3",
        x = 13.5,
        y = 12.5,
        w = 5,
        h = 1,
        outlineWidth = 3,
        drawOrder = 10,
        outlineColor = Macros.colors.white,
        inlineColor = Macros.colors.lightBlack,
        extra = {
            text = AdvancedText("|s:2,2|Settings")
        },
        updateFunc = function(self)
            if not self:isHovered() then
                self.TMod.x.base = Util.Math.lerpDt(self.TMod.x.base, 13.5, 0.05)
                self.TMod.y.base = Util.Math.lerpDt(self.TMod.y.base, 12.5, 0.05)
            else
                self.TMod.x.base = Util.Math.lerpDt(self.TMod.x.base, 11.5, 0.05)
                self.TMod.y.base = Util.Math.lerpDt(self.TMod.y.base, 12.25, 0.05)
            end
            local delta = 12.5 - self.TMod.y.base
            self.TMod.h.base = 1 + 2 * delta
            self.TMod.w.base = 1.25 * 13.5 + 5 - 1.25 * self.TMod.x.base
        end,
        drawFunc = function(self)
            local h = self.extra.text:getHeight()
            local delta = (1 - (self.TMod.y.base - 12.25) / 0.25) * 0.2
            local dh = delta * h / 40
            self.extra.text:recalculate({}, "|s:" .. (2 * (1 + 1.5 * delta)) ..
                "," .. (2 * (1 + 1.5 * delta)) .. "|Settings")
            self.extra.text:draw(self.T.x + 0.25 + 2 * dh, 12.5 + 0.29 - dh, true)
        end,
        onHover = function()
            Util.Audio.playSfx("blip_hover", 2)
        end,
        onLeftHover = function()
            Util.Audio.playSfx("blip_unhover", 2)
        end
    })
end

function Macros.UIDef.overlay()
    Sprite({
        nid = "UIMove",
        drawOrder = 100,
        x = Macros.grandOffsetVector.contents[1],
        y = Macros.grandOffsetVector.contents[2],
        atlasKey = "UIMove",
        scaleX = 2,
        scaleY = 2,
        updateFunc = function (s, dt)
            local g = getObjectByNid("isoGridWeb")
            if g and #g.extra.path > 1 then
                s.atlasInfo.key = "UIMove"
            else
                s.atlasInfo.key = "UIMoveInactive"
            end
        end
    })
    SimpleDrawableButton({
        nid = "MoveButton",
        x = -5,
        y = -2.5,
        w = 10,
        h = 4.5,
        outlineWidth = 3,
        drawOrder = 10,
        outlineColor = Macros.colors.transparent,
        inlineColor = Macros.colors.transparent,
        onClick = function(self)
            local function getDoor(coords)
                for k, v in pairs(G.I.MOVEABLES) do
                    if v.objectType == "WORLDMOVEABLE" then
                        if v.properties.type == "door" and Util.Math.precisionCheck(coords[1] - 0.2, v.TMod.x.base, 0.1) and Util.Math.precisionCheck(coords[2] - 0.2, v.TMod.y.base, 0.1) then
                            return v
                        end
                    end
                end
            end
            local s = getObjectByNid("isoGridWeb")
            if s and # s.extra.path > 1 then
                local function Eventify()
                    Util.Event.delayFunc(0.3, function()
                        if # s.extra.path > 1 then
                            table.remove(s.extra.path, 1)
                            PLAYER.TMod.x.base = Util.Math.round(s.extra.path[1].coords[1] - 0.2)
                            PLAYER.TMod.y.base = Util.Math.round(s.extra.path[1].coords[2] - 0.2)
                            PLAYER:juice()
                            Eventify()
                        else
                            Util.World.modTime(1)
                            if getDoor(s.extra.path[#s.extra.path].coords) then
                                getDoor(s.extra.path[#s.extra.path].coords):switchRoom()
                            end
                        end
                    end)
                end
                table.remove(s.extra.path, 1)
                PLAYER.TMod.x.base = Util.Math.round(s.extra.path[1].coords[1] - 0.2)
                PLAYER.TMod.y.base = Util.Math.round(s.extra.path[1].coords[2] - 0.2)
                PLAYER:juice()
                Eventify()
            end
        end,
    })
    SimpleDrawableButton({
        nid = "CancelButton",
        x = -5,
        y = 2,
        w = 9,
        h = 2,
        outlineWidth = 3,
        drawOrder = 10,
        outlineColor = Macros.colors.transparent,
        inlineColor = Macros.colors.transparent,
        onClick = function(self)
            local s = getObjectByNid("isoGridWeb")
            if s then
                s.extra.path = {
                    { point = Vector(PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2), coords = { PLAYER.TMod.x.base + 0.2, PLAYER.TMod.y.base + 0.2 } }
                }
            end
        end,
    })
    Sprite({
        nid = "UICancel",
        drawOrder = 99,
        x = Macros.grandOffsetVector.contents[1],
        y = Macros.grandOffsetVector.contents[2],
        atlasKey = "UICancel",
        scaleX = 2,
        scaleY = 2,
        updateFunc = function(s, dt)
            local g = getObjectByNid("isoGridWeb")
            if g and #g.extra.path > 1 then
                s.T.y = Util.Math.lerpDt(s.T.y, Macros.grandOffsetVector.contents[2], 0.01)
            else
                s.T.y = Util.Math.lerpDt(s.T.y, Macros.grandOffsetVector.contents[2] - 59 * 2 * Util.UI.getScalingFactor(), 0.01)
            end
        end
    })
    Sprite({
        nid = "UIHP",
        drawOrder = 100,
        x = Macros.grandOffsetVector.contents[1],
        y = Macros.grandOffsetVector.contents[2],
        atlasKey = "UIHP",
        scaleX = 2,
        scaleY = 2,
        preDraw = function (s)
            love.graphics.setColor(Macros.colors.night)
            love.graphics.rectangle("fill", G.drawinfo.origin.x + G.drawinfo.gridSize.x / 400 * 81,
                G.drawinfo.origin.y + G.drawinfo.gridSize.y / 300 * 266, 27 * 2 * Util.UI.getScalingFactor(),
                23 * 2 * Util.UI.getScalingFactor())
            love.graphics.setColor(Macros.colors.red)
            local percentage = G.flags.saveData.hp / Macros.maxhp
            love.graphics.rectangle("fill", G.drawinfo.origin.x + G.drawinfo.gridSize.x / 400 * 81,
                G.drawinfo.origin.y + G.drawinfo.gridSize.y / 300 * 266, 27 * 2 * Util.UI.getScalingFactor() * percentage,
                23 * 2 * Util.UI.getScalingFactor())
            love.graphics.setColor(Macros.colors.white)
        end,
        drawFunc = function(s)
            local txt = G.flags.saveData.hp .. "/" .. Macros.maxhp
            local str = ""
            local counter = 1
            for i = 1, 2 * #txt - 1 do
                local oddity = i % 2 == 1
                if oddity then
                    str = str..txt:sub(counter, counter)
                    counter = counter + 1
                else
                    str = str .. " "
                end
            end
            AdvancedText("|s:2,2||c:red||f:timer|" .. str):draw(
                G.drawinfo.origin.x + G.drawinfo.gridSize.x / 400 * 128,
                G.drawinfo.origin.y + G.drawinfo.gridSize.y / 300 * 266)
        end
    })
    Sprite({
        nid = "UIItemRibbon",
        drawOrder = 100,
        x = Macros.grandOffsetVector.contents[1],
        y = Macros.grandOffsetVector.contents[2],
        atlasKey = "UIItemRibbon",
        scaleX = 2,
        scaleY = 2
    })
    Sprite({
        nid = "UITimer",
        drawOrder = 100,
        x = Macros.grandOffsetVector.contents[1],
        y = Macros.grandOffsetVector.contents[2],
        atlasKey = "UITimer",
        scaleX = 2,
        scaleY = 2,
        drawFunc = function (s)
            local hours = Util.Math.div(G.flags.saveData.timer, 60) + 3
            local minutes = G.flags.saveData.timer % 60
            hours = tostring(hours)
            if #hours == 1 then
                hours = "0 "..hours
            else
                hours = hours:sub(1,1).." "..hours:sub(2,2)
            end
            minutes = tostring(minutes)
            if #minutes == 1 then
                minutes = "0 " .. minutes
            else
                minutes = minutes:sub(1, 1) .. " " .. minutes:sub(2, 2)
            end
            AdvancedText("|s:2,2||c:night||f:timer|" .. hours):draw(
            G.drawinfo.origin.x + G.drawinfo.gridSize.x / 400 * 317,
            G.drawinfo.origin.y + G.drawinfo.gridSize.y / 300 * 13)
            AdvancedText("|s:2,2||c:night||f:timer|" .. minutes):draw(
            G.drawinfo.origin.x + G.drawinfo.gridSize.x / 400 * 358,
            G.drawinfo.origin.y + G.drawinfo.gridSize.y / 300 * 13)
            AdvancedText("|s:2,2||o:night||c:red|" .. (Macros.maxtime - G.flags.saveData.timer) .. "|o:00000000||c:night| mins til sunrise"):draw(
            G.drawinfo.origin.x + G.drawinfo.gridSize.x / 400 * 319,
            G.drawinfo.origin.y + G.drawinfo.gridSize.y / 300 * 40)
        end
    })
    Moveable({
        nid = "UITimerIcon",
        drawOrder = 99,
        x = Macros.grandOffsetVector.contents[1],
        y = Macros.grandOffsetVector.contents[2],
        exrta = {delta = 0},
        drawFunc = function (self)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setScissor(G.drawinfo.origin.x + G.drawinfo.gridSize.x / 400 * 285,
                G.drawinfo.origin.y + G.drawinfo.gridSize.y / 300 * 12, 50 * Util.UI.getScalingFactor(),
                50 * Util.UI.getScalingFactor())
            love.graphics.draw(
                Atlases.UITimerIcon.image,
                Atlases.UITimerIcon.splicedImages[0][0],
                G.drawinfo.origin.x + G.drawinfo.gridSize.x / 400 * 285,
                G.drawinfo.origin.y + G.drawinfo.gridSize.y / 300 * 12 - self.extra.delta,
                0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
            )
            love.graphics.setScissor()
        end,
        updateFunc = function (s, dt)
            s.extra.delta = 2 * 24 * Util.UI.getScalingFactor() * G.flags.saveData.timer/Macros.maxtime
        end
    })
end

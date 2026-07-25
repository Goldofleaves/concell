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
                Util.Event.easeInMusic(2, "interrogation", "interrogationID", "interrogationGRP", nil, 2)
                Macros.CDefs.Opening()
            end, "delay1")
            Util.Audio.playSfx("start_jingle", 2)
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
            text = AdvancedText(("|c:"..(love.filesystem.exists("runInfo.con") and "white|" or "grey|")) .."|s:2,2|Resume run")
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
        onClick = function(s)
            if love.filesystem.exists("runInfo.con") then
                Util.Event.easeOutMusic(2, "titleID")
                Util.World.loadGame()
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
                    PLAYER = WorldMoveable({
                        x = G.flags.saveData.playerPos.x,
                        y = G.flags.saveData.playerPos.y,
                        type = "player",
                        updateOrder = 1,
                        drawOrder = 31,
						extra = {facing = G.flags.saveData.playerFacing}
                    })
                    Macros.MDef.isometricGrid(G.flags.saveData.curRoom.size.w, G.flags.saveData.curRoom.size.h, Util.World.getArea(G.flags.saveData.curRoomIndex))
                    for k, v in ipairs(G.flags.saveData.curRoom.enemies) do
                        local j = WorldMoveable({
                            x = v.pos[1],
                            y = v.pos[2],
                            type = "enemy",
                            extra = {
                                index = v.index,
                                side = v.side
                            },
                            updateOrder = 2,
                            drawOrder = 10
                        })
                        j:decideMove()
                    end
                    for k, v in ipairs(G.flags.saveData.curRoom.doors) do
                        WorldMoveable({
                            x = v.x,
                            y = v.y,
                            type = "door",
                            extra = {
                                index = v.index,
                                side = v.side
                            },
                            updateOrder = 2,
                            drawOrder = 30
                        })
                    end
                end, "delay1")
            end
        end,
        drawFunc = function(self)
            local h = self.extra.text:getHeight()
            local delta = (1 - (self.TMod.y.base - 10.75) / 0.25) * 0.2
            local dh = delta * h / 40
            self.extra.text:recalculate({},
            ("|c:" .. (love.filesystem.exists("runInfo.con") and "white|" or "grey|")) ..
                "|s:" .. (2 * (1 + 1.5 * delta)) ..
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
end

function Macros.UIDef.overlay()
    local function registerItemButton(i)
        local offsets = {
            { (243+10) / 20, (245+10) / 20},
            { (277+10) / 20, (242+10) / 20},
            { (312+10) / 20, (239+10) / 20},
            { (347+10) / 20, (236+10) / 20},
        }
        SimpleDrawableButton({
            nid = "itemButton"..i,
            x = offsets[i][1],
            y = offsets[i][2],
            w = 29/20,
            h = 27/20,
            outlineWidth = 3,
            drawOrder = 10,
            outlineColor = Macros.colors.transparent,
            inlineColor = Macros.colors.transparent,
            onRightClick = function(self)
                if G.flags.saveData.items[i] and not getEventByNid("itemDiscard" .. i) and not G.flags.saveData.items[i].isBeingUsed then
                    CALCULATECONTEXT({ itemDiscarded = true, discardedItem = { slot = i, key = G.flags.saveData.items[i].key } })
                    discardItem(i)
                end
                if G.flags.saveData.items[i] and not getEventByNid("itemDiscard" .. i) and G.flags.saveData.items[i].isBeingUsed then
                    G.flags.saveData.items[i].isBeingUsed = false
                    TARGETED_ENEMIES = nil
                end
            end,
            onClick = function(self)
                if G.flags.saveData.items[i] and Centers[G.flags.saveData.items[i].key].canUse(G.flags.saveData.items[i]) == "noState" then
                    Centers[G.flags.saveData.items[i].key].onUse(G.flags.saveData.items[i])
                    CALCULATECONTEXT({ itemUsed = true, usedItem = { slot = i, key = G.flags.saveData.items[i].key }, hasState = false })
                end
                if G.flags.saveData.items[i] and Centers[G.flags.saveData.items[i].key].canUse(G.flags.saveData.items[i]) == "hasState" then
                    Centers[G.flags.saveData.items[i].key].onUse(G.flags.saveData.items[i])
                    G.flags.saveData.items[i].isBeingUsed = true
                    CALCULATECONTEXT({ itemUsed = true, usedItem = { slot = i, key = G.flags.saveData.items[i].key }, hasState = false })
                end
            end,
        })
    end
    registerItemButton(1)
    registerItemButton(2)
    registerItemButton(3)
    registerItemButton(4)
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
            TARGETED_ENEMIES = nil
            for _, item in ipairs(G.flags.saveData.items) do
                if item then item.isBeingUsed = false end
            end
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
                G.flags.isMoving = true
                local function Eventify()
                    Util.Event.delayFunc(0.3, function()
                        if # s.extra.path > 1 then
                            local t = Util.World.getDir(s.extra.path)
                            if t then
                                PLAYER.extra.facing = t
                            end
                            Util.World.modTime(1)
                            Util.Audio.playSfx("blip_hover", 2)
                            table.remove(s.extra.path, 1)
                            PLAYER.TMod.x.base = Util.Math.round(s.extra.path[1].coords[1] - 0.2)
                            PLAYER.TMod.y.base = Util.Math.round(s.extra.path[1].coords[2] - 0.2)
                            PLAYER:juice()
                            CALCULATECONTEXT({ player_move = true, pos = { PLAYER.TMod.x.base, PLAYER.TMod.y.base } })
                            Eventify()
                        else
                            G.flags.isMoving = nil
                            CALCULATECONTEXT({ player_move = true, pos = { PLAYER.TMod.x.base, PLAYER.TMod.y.base } })
                            CALCULATECONTEXT({ moveEnd = true })
                            move_all_enemies()
                            if getDoor(s.extra.path[#s.extra.path].coords) then
                                getDoor(s.extra.path[#s.extra.path].coords):switchRoom()
                            end
                        end
                    end)
                end
                local t = Util.World.getDir(s.extra.path)
                if t then
                    PLAYER.extra.facing = t
                end
                Util.World.modTime(1)
                table.remove(s.extra.path, 1)
                Util.Audio.playSfx("blip_hover", 2)
                PLAYER.TMod.x.base = Util.Math.round(s.extra.path[1].coords[1] - 0.2)
                PLAYER.TMod.y.base = Util.Math.round(s.extra.path[1].coords[2] - 0.2)
                PLAYER:juice()
                Eventify()
            else
                Util.Audio.playSfx("blip_stopped", 2)
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
        scaleY = 2,
        extra = {
             deltas = {0,0,0,0}
        },
        drawFunc = function (s)
            local offsets = {
                { 243 * 2 * Util.UI.getScalingFactor(), 245 * 2 * Util.UI.getScalingFactor() },
                { 277 * 2 * Util.UI.getScalingFactor(), 242 * 2 * Util.UI.getScalingFactor() },
                { 312 * 2 * Util.UI.getScalingFactor(), 239 * 2 * Util.UI.getScalingFactor() },
                { 347 * 2 * Util.UI.getScalingFactor(), 236 * 2 * Util.UI.getScalingFactor() },
            }
            love.graphics.setColor(1, 1, 1, 1)
            local deltas = s.extra.deltas
            for k, v in ipairs(G.flags.saveData.items) do
                deltas[k] = Util.Math.lerpDt(deltas[k], v.isBeingUsed and - 40 * Util.UI.getScalingFactor() or 0, 0.005)
                local col = {1, 1, 1, 1}
                if not Centers[v.key].canUse(v) and not v.isBeingUsed then
                    col = {0.3, 0.3, 0.3, 1}
                end
				local r, g, b, a = love.graphics.getColor()
                love.graphics.setColor(col)
                love.graphics.draw(
                    Atlases[Centers[v.key].sprite].image,
                    Atlases[Centers[v.key].sprite].splicedImages[0][0],
                    G.drawinfo.origin.x + offsets[k][1],
                    G.drawinfo.origin.y + offsets[k][2]+deltas[k],
                    0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
                )
                love.graphics.setColor(r, g, b, a)
            end
        end,
        -- icl theres definitely a better spot for this but whatever :p
        updateFunc = function(s, dt)
            if TARGETED_ENEMIES then
                local pt = getClosestPointAndDistance()
                for _, enemy in ipairs(TARGETED_ENEMIES) do
                    if Util.Math.precisionCheck(enemy.TMod.x.base, pt.contents[1] - 0.2, 0.1) and Util.Math.precisionCheck(enemy.TMod.y.base, pt.contents[2] - 0.2, 0.1) then
                        -- use our item
                        if G.mouseController[1].pressed then
	                        for i, v in ipairs(G.flags.saveData.items) do
                                if v.isBeingUsed then
                                    Centers[v.key].onUse(v, enemy)
                                    move_all_enemies()
                                    v.isBeingUsed = false
                                    CALCULATECONTEXT({ itemUsed = true, usedItem = { slot = i, key = v.key }, hasState = true })
                                end
                            end
                            TARGETED_ENEMIES = nil
                            break
                        end
                    end
                end
            end
        end
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
            local hours = Util.Math.div(G.flags.saveData.timer, 60)
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
            AdvancedText("|s:2,2||o:night||c:red|" .. (Macros.maxtime + G.flags.saveData.timemod - G.flags.saveData.timer) .. "|o:00000000||c:night| mins til dawn"):draw(
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

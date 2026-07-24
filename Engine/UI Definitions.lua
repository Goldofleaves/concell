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
                Macros.MDef.isometricGrid(G.flags.saveData.curRoom.size.w, G.flags.saveData.curRoom.size.h)
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
        end
    })
end

function Macros.UIDef.overlay()
end

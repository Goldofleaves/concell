love.graphics.setDefaultFilter("nearest", "nearest", 1)
love.graphics.setLineStyle("rough")
Util = {}
require "Engine.Util.Other"
require "Engine.Util.Splines and Easing"
require "Engine.Util.UI"
require "Engine.Util.Math"
require "Engine.Util.Drawing"
require "Engine.Macros"
require "Engine.Util.File"
require "Engine.Util.Color"
require "Engine.Function Overrides and Misc"
require "Engine.Object"
require "Engine.Text"
require "Engine.Vector"
require "Engine.Game"
require "Engine.Event"
require "Engine.Cutscenes"
require "Engine.Sprites"
require "Engine.Moveable"
require "Engine.UI Definitions"
require "Engine.Moveable Definitions"
require "Engine.Util.Audio"
require "Engine.Util.World"
require "Engine.Moveable Subclasses.Button"
local function wrapper(key, px, py)
    registerAtlasSimple(key, "Assets/Sprites/"..key..".png", px, py)
end
wrapper("grassBase", 40, 21)
wrapper("grassFoley", 40, 21)
wrapper("grassEdge1", 40, 21)
wrapper("grassEdge2", 40, 21)
wrapper("grassEdge3", 40, 21)
wrapper("grassEdge4", 40, 21)
wrapper("titlescreenBg", 600, 400)
wrapper("titlescreenFg", 600, 400)
function love.load()
    --Macros.MDef.isometricGrid(5, 8)
    Macros.UIDef.title()
    SimpleDrawableButton({
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
            self.TMod.h.base = 1 + 2*delta
            self.TMod.w.base = 1.25*13.5 + 5 - 1.25*self.TMod.x.base
        end,
        drawFunc = function (self)
            local h = self.extra.text:getHeight()
            local delta = (1-(self.TMod.y.base - 9.25)/0.25) * 0.2
            local dh = delta * h/40
            self.extra.text:recalculate({}, "|s:" .. (2 * (1 + 1.5*delta)) .. "," .. (2 * (1 + 1.5*delta)) .. "|New run")
            self.extra.text:draw(self.T.x + 0.25+2*dh, 9.5 + 0.29 - dh , true)
        end
    })
    SimpleDrawableButton({
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
function love.update(dt)
    DELTATIME = dt
    G:update(dt)
    PREVIOUS_DELTATIME = dt
end

function love.draw()
    G:draw()
end

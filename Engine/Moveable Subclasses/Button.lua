---@class Button: Moveable
Button = Moveable:extend()

function Button:new(args)
    Moveable.new(self, args)
    self.hover = args.hover or function(s, dt) end
    self.onHover = args.onHover or function(s) end
    self.onLeftHover = args.onLeftHover or function(s) end
    self.onClick = args.onClick or function(s) end
    self.hold = args.hold or function(s, dt) end
    self.onRelease = args.onRelease or function(s) end
end
function Button:wasHovered()
    return (self.T.x < G.mousepos.oldx and G.mousepos.oldx < self.T.x + self.T.w) and (self.T.y < G.mousepos.oldy and G.mousepos.oldy < self.T.y + self.T.h)
end
function Button:isHovered()
    return (self.T.x < G.mousepos.x and G.mousepos.x < self.T.x + self.T.w) and (self.T.y < G.mousepos.y and G.mousepos.y < self.T.y + self.T.h)
end
function Button:update(dt)
    Moveable.update(self, dt)
    if self:wasHovered() and not self:isHovered() then
        self:onLeftHover()
    elseif self:isHovered() and not self:wasHovered() then
        self:onHover()
    end
    if self:isHovered() then
        self:hover(dt)
        if G.mouseController[1].pressed then
            self:onClick()
        end
        if G.mouseController[1].held then
            self:hold(dt)
        end
        if G.mouseController[1].released then
            self:onRelease()
        end
    end
end
---@class Button: Moveable
SimpleDrawableButton = Button:extend()
function SimpleDrawableButton:new(args)
    Button.new(self, args)
    self.outlineWidth = args.outlineWidth or 1
    self.outlineColor = args.outlineColor or Macros.colors.black
    self.inlineColor = args.inlineColor or Macros.colors.white
end

function SimpleDrawableButton:draw()
    local r, g, b, a = love.graphics.getColor()
    local x, y = Util.UI.convertPosToUIPos(self.T.x, self.T.y)
    love.graphics.setColor(self.inlineColor)
    love.graphics.rectangle("fill", x, y, self.T.w * G.drawinfo.gridUnit,
    self.T.h * G.drawinfo.gridUnit)
    love.graphics.setColor(self.outlineColor)
    love.graphics.rectangle("fill", x, y, self.outlineWidth * Util.UI.getScalingFactor(),
        self.T.h * G.drawinfo.gridUnit)
    love.graphics.rectangle("fill",
        x + self.T.w * G.drawinfo.gridUnit - self.outlineWidth * Util.UI.getScalingFactor(), y,
        self.outlineWidth * Util.UI.getScalingFactor(), self.T.h * G.drawinfo.gridUnit
    )
    love.graphics.rectangle("fill", x, y, self.T.w * G.drawinfo.gridUnit, self.outlineWidth * Util.UI.getScalingFactor())
    love.graphics.rectangle("fill", x, y + self.T.h * G.drawinfo.gridUnit - self.outlineWidth, self.T.w * G.drawinfo.gridUnit,
        self.outlineWidth * Util.UI.getScalingFactor())
    Moveable.draw(self)
    love.graphics.setColor(r,g,b,a)
end
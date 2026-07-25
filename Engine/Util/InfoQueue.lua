InfoQueue = Object:extend()
local padding = 6
local width = 2
function InfoQueue:new(text, vars)
    local configs = {}
    for i = 1, #text do
        table.insert(configs, vars)
    end
    self.text = createTableOfAdvancedText(text, configs)
end

function InfoQueue:getWidth()
    local longest = 0
    for k, v in ipairs(self.text) do
        local len = v:getTotalWidth()
        if len > longest then
            longest = len
        end
    end
    return longest + padding * 2 * Util.UI.getScalingFactor()
end

function InfoQueue:getHeight()
    local total = 0
    for k, v in ipairs(self.text) do
        total = total + v:getHeight()
    end
    return total + padding * 2 * Util.UI.getScalingFactor()
end
function InfoQueue:draw(x, y)
    love.graphics.setColor(Macros.colors.night)
    love.graphics.rectangle("fill", x, y, self:getWidth(), self:getHeight())
    love.graphics.setColor(Macros.colors.white)
    love.graphics.rectangle("fill", x, y, width * Util.UI.getScalingFactor(), self:getHeight())
    love.graphics.rectangle("fill", x + self:getWidth() - width * Util.UI.getScalingFactor(), y, width * Util.UI.getScalingFactor(), self:getHeight())
    love.graphics.rectangle("fill", x, y, self:getWidth(), width * Util.UI.getScalingFactor())
    love.graphics.rectangle("fill", x, y + self:getHeight() - width * Util.UI.getScalingFactor(), self:getWidth(), width * Util.UI.getScalingFactor())
    local actualWidth = self:getWidth() - padding * 2 * Util.UI.getScalingFactor()
    local function getDeviation(txtwidth)
        return padding * Util.UI.getScalingFactor() + actualWidth/2 - txtwidth/2
    end
    local yy = y + padding * Util.UI.getScalingFactor()
    for k, v in ipairs(self.text) do
        v:draw(x + getDeviation(v:getTotalWidth()), yy)
        yy = yy + v:getHeight()
    end
end
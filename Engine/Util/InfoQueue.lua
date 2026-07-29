InfoQueue = Object:extend()
local padding = 10
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

local TUTORIAL_QUEUE_NID = "tutorialInfoQueue"
local RANGED_TUTORIAL_ENEMIES = {
    officer = true,
    hunter = true,
    elite = true,
    abraham = true,
}
local function createTutorialQueue()
    return Moveable({
        nid = TUTORIAL_QUEUE_NID,
        drawOrder = 1000,
        updateOrder = -1000,
        extra = {
            queue = {},
        },
        updateFunc = function(self, dt)
            local current = self.extra.queue[1]
            if not current or getEventByNid("transition") then
                return
            end
        end,
        drawFunc = function(self)
            local current = self.extra.queue[1]
            if not current or getEventByNid("transition") then
                return
            end
            local info = current.info
            local x = G.drawinfo.origin.x
                + (G.drawinfo.gridSize.x - info:getWidth()) / 2
            local y = G.drawinfo.origin.y
                + 70 * Util.UI.getScalingFactor()
            info:draw(x, y)
        end,
    })
end
local ref = CALCULATECONTEXT
function CALCULATECONTEXT(context)
    ref(context)
    if context.player_move then
        local queueMoveable = getObjectByNid(TUTORIAL_QUEUE_NID)
        if queueMoveable and #queueMoveable.extra.queue > 0 then
            table.remove(queueMoveable.extra.queue, 1)
            if #queueMoveable.extra.queue == 0 then
                queueMoveable:remove()
            end
        end
    end
end
function InfoQueue.showTutorial(identifier, text, duration)
    if not G or not G.flags or not G.flags.saveData then
        return false
    end
    local saveData = G.flags.saveData
    saveData.tutorialsSeen = saveData.tutorialsSeen or {}
    if saveData.tutorialsSeen[identifier] then
        return false
    end
    saveData.tutorialsSeen[identifier] = true

    local queueMoveable = getObjectByNid(TUTORIAL_QUEUE_NID)
    if not queueMoveable then
        queueMoveable = createTutorialQueue()
    end
    queueMoveable.extra.queue[#queueMoveable.extra.queue + 1] = {
        info = InfoQueue(text)
    }
    return true
end

function InfoQueue.checkRoomTutorials()
    if not G or not G.flags.saveData.curRoom then
        return
    end
    local saveData = G.flags.saveData
    local room = saveData.curRoom

    if saveData.curRoomIndex == 1 then
        InfoQueue.showTutorial("movement", {
            "|s:2,2||c:yellow|MOVEMENT",
            "|s:2,2|Click floor tiles or use arrows to plan a route.",
            "|s:2,2|Press Enter to move. Press Space to bide time.",
            "|s:2,2|Remember, your time is finite...",
            "|s:2,2|You must escape before the sun rises.",
            "|s:2,2||c:night| M",
            "|s:2,2||c:yellow|TUTORIALS",
            "|s:2,2|These display boxes are tutorials, they provide information.",
            "|s:2,2|Tutorials only dissappear when you move.",
        })
    end
    if #(room.keys or {}) > 0 then
        InfoQueue.showTutorial("keys", {
            "|s:2,2||c:yellow|KEYS",
            "|s:2,2|Sometimes, you might encounter a locked door.",
            "|s:2,2|Perhaps, there is a key somewhere around here...",
        })
    end
    if room.transition and room.transition.toArea == "grass" then
        InfoQueue.showTutorial("turrets", {
            "|s:2,2||c:yellow|TURRETS",
            "|s:2,2|Archers can only hit their mark if they have a clear line.",
            "|s:2,2|You may find flora, or even other enemies,",
            "|s:2,2|can make for good cover.",
        })
    end
    if room.transition and room.transition.toArea == "ruins" then
        InfoQueue.showTutorial("skeletons", {
            "|s:2,2||c:yellow|SKELETONS",
            "|s:2,2|Skeletons are weak, but hardy.",
            "|s:2,2|Even after death, they may rise again.",
            "|s:2,2|They cannot rise if something weighs them down.",
            "|s:2,2|Maybe with something heavy, you can make that permanent.",
        })
    end
    if #(room.statues or {}) > 0 then
        InfoQueue.showTutorial("statues", {
            "|s:2,2||c:yellow|STATUES",
            "|s:2,2|It seems the exit here is locked. A button shines nearby.",
            "|s:2,2|Perhaps you can use something heavy to weigh it down?",
        })
    end
    for _, enemy in ipairs(room.enemies or {}) do
        if RANGED_TUTORIAL_ENEMIES[enemy.name] then
            InfoQueue.showTutorial("ranged_enemies", {
                "|s:2,2||c:yellow|GUNNERS",
                "|s:2,2|Some enemies prefer to fight at a distance.",
                "|s:2,2|Their shots need a clear sight and cannot hit you up close.",
                "|s:2,2|They only move while reloading- and they try to keep their distance.",
                "|s:2,2|Other enemies caught in their sights may take the hit instead.",
            })
            break
        end
    end
end

function InfoQueue.updateTutorials()
    if not G
        or not G.flags.saveData.curRoom
        or G.flags.saveData.curRoomIndex ~= 1
        or not PLAYER
        or (
            G.flags.saveData.tutorialsSeen
            and G.flags.saveData.tutorialsSeen.attacking
        )
    then
        return
    end
    for _, enemy in ipairs(
        Util.World.getAllWorldMoveablesWithType("enemy")
    ) do
        if enemy.extra.name == "guard"
            and enemy.extra.hp > 0
            and math.abs(enemy.TMod.x.base - PLAYER.TMod.x.base)
                + math.abs(enemy.TMod.y.base - PLAYER.TMod.y.base) == 1
        then
            InfoQueue.showTutorial("attacking", {
                "|s:2,2||c:yellow|ITEMS & ATTACKING",
                "|s:2,2|Click an item or press 1-4 to select it.",
                "|s:2,2|Click a lit target or press its arrow direction to use the item.",
                "|s:2,2|Hover an item to see more information.",
            })
            return
        end
    end
end

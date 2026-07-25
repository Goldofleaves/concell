Centers = {}
Pools = {
    common = { rate = 3, keys = {} },
    uncommon = { rate = 2, keys = {} },
    rare = { rate = 1, keys = {} }
}
function registerItem(args)
    args.key = args.key or "ERROR"
    local t = {
        onGet = args.onGet or function (self) end,
        defaultConfig = args.config or {},
        onDiscard = args.onDiscard or function(self) end,
        calculate = args.calculate or function (context, self) end,
        pool = args.pool or "common",
        inPool = args.inPool or function () return true end,
        sprite = args.sprite or "ERROR",
        update = args.update or function (self) end,
        canUse = args.canUse or function() return "noState" end,
        IBUupdate = args.IBUupdate or function(self) end,
        onUse = args.onUse or function(self) end,
        text = args.text or {"|s:2,2|ERROR"}
    }
    table.insert(Pools[args.pool or "common"].keys, args.key)
    Centers[args.key] = t
end
---@param key string
---@return boolean success
function addItem(key)
    if #G.flags.saveData.items < Macros.itesmslots then
        local t = {
            key = key,
            config = Util.Other.copyTable(Centers[key].defaultConfig),
            isBeingUsed = false
        }
        table.insert(G.flags.saveData.items, t)
        Centers[key].onGet(t)
        return true
    end
    return false
end
---@param slot? number
---@param key? string
---@return boolean success
function discardItem(slot, key)
    if not key then
        local i = slot
        key = G.flags.saveData.items[i].key
        local spr = Centers[key].sprite
        Util.Event.addEvent(Event(
            {
                duration = 0.75,
                drawOrder = 102,
                drawFunc = function(time)
                    local offsets = {
                        { 243 * 2 * Util.UI.getScalingFactor(), 245 * 2 * Util.UI.getScalingFactor() },
                        { 277 * 2 * Util.UI.getScalingFactor(), 242 * 2 * Util.UI.getScalingFactor() },
                        { 312 * 2 * Util.UI.getScalingFactor(), 239 * 2 * Util.UI.getScalingFactor() },
                        { 347 * 2 * Util.UI.getScalingFactor(), 236 * 2 * Util.UI.getScalingFactor() },
                    }
                    local col = { 1, 1, 1, 1 }
                    local r, g, b, a = love.graphics.getColor()
                    love.graphics.setColor(Util.Color.SetOpacity(col, 1 - time))
                    love.graphics.draw(
                        Atlases[spr].image,
                        Atlases[spr].splicedImages[0][0],
                        G.drawinfo.origin.x + offsets[i][1],
                        G.drawinfo.origin.y + offsets[i][2] - (1 - (time - 1) ^ 2) * 40 * Util.UI.getScalingFactor(),
                        0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
                    )
                    love.graphics.setColor(r, g, b, a)
                end
            }
        ), "itemDiscard" .. i)
        Centers[key].onDiscard(G.flags.saveData.items[i])
        table.remove(G.flags.saveData.items, slot)
        return true
    end
    for k, v in ipairs(G.flags.saveData.items) do
        if v.key == key then
            Centers[v.key].onDiscard(v)
            local i = k
            key = v.key
            local spr = Centers[key].sprite
            Util.Event.addEvent(Event(
                {
                    duration = 0.75,
                    drawOrder = 102,
                    drawFunc = function(time)
                        local offsets = {
                            { 243 * 2 * Util.UI.getScalingFactor(), 245 * 2 * Util.UI.getScalingFactor() },
                            { 277 * 2 * Util.UI.getScalingFactor(), 242 * 2 * Util.UI.getScalingFactor() },
                            { 312 * 2 * Util.UI.getScalingFactor(), 239 * 2 * Util.UI.getScalingFactor() },
                            { 347 * 2 * Util.UI.getScalingFactor(), 236 * 2 * Util.UI.getScalingFactor() },
                        }
                        local col = { 1, 1, 1, 1 }
                        local r, g, b, a = love.graphics.getColor()
                        love.graphics.setColor(Util.Color.SetOpacity(col, 1 - time))
                        love.graphics.draw(
                            Atlases[spr].image,
                            Atlases[spr].splicedImages[0][0],
                            G.drawinfo.origin.x + offsets[i][1],
                            G.drawinfo.origin.y + offsets[i][2] - (1 - (time - 1) ^ 2) * 40 * Util.UI.getScalingFactor(),
                            0, 2 * Util.UI.getScalingFactor(), 2 * Util.UI.getScalingFactor()
                        )
                        love.graphics.setColor(r, g, b, a)
                    end
                }
            ), "itemDiscard" .. i)
            table.remove(G.flags.saveData.items, k)
            return true
        end
    end
    return false
end
---@param key string
---@return boolean result
function hasItem(key)
    for k, v in ipairs(G.flags.saveData.items) do
        if v.key == key then
            return true
        end
    end
    return false
end

---@param pool? string
---@return string key
function poolItem(pool)
    if pool then
        local t = {}
        for k, v in ipairs(Pools[pool].keys) do
            if Centers[v].inPool() and not hasItem(v) then
                table.insert(t, v)
            end
        end
        return Util.Math.randomElement(t).v
    end
    local chances = {}
    for k, v in ipairs(Pools) do
        table.insert(chances, {val = k, weight = v.rate})
    end
    local p = Util.Math.weightedChance(chances)
    return poolItem(p)
end
function CALCULATECONTEXT(context)
    for k, v in ipairs(G.flags.saveData.items) do
        Centers[v.key].calculate(context, v)
    end
    -- do this for enemies too? might be a mistake :p
    for k, v in ipairs(Util.World.getAllWorldMoveablesWithType("enemy")) do
        if Macros.calculates[v.extra.name] then
            Macros.calculates[v.extra.name](context, v)
        end
    end
end

local get_orthogonal_dist = function(a, b)
    return math.abs(a.TMod.x.base - b.TMod.x.base) + math.abs(a.TMod.y.base - b.TMod.y.base)
end

registerItem({
    key = "musket",
    sprite = "ItemMusket",
    config = {
        damage = -10,
        timeCost = 6
    },
    canUse = function(self)
        local enemies = Util.World.getAllWorldMoveablesWithType("enemy")

        if not self.isBeingUsed then
            self.targets = {}
            for _, e in ipairs(enemies) do
                if e.TMod.x.base == PLAYER.TMod.x.base and e.TMod.y.base == PLAYER.TMod.y.base then
                    self.targets[#self.targets + 1] = e
                end
            end
            if #self.targets > 0 then return "hasState" end
        end
        return false
    end,
    onUse = function(self, enemy)
        if not self.isBeingUsed then
            TARGETED_ENEMIES = self.targets
        else
            enemy:modHP(self.config.damage)
            Util.World.modTime(self.config.timeCost)
        end
    end
})

registerItem({
    key = "whip",
    sprite = "ItemWhip",
    config = {
        damage = -4,
        timeCost = 3
    },
    canUse = function(self)
        local enemies = Util.World.getAllWorldMoveablesWithType("enemy")

        if not self.isBeingUsed then
            self.targets = {}
            for _, e in ipairs(enemies) do
                local dist = get_orthogonal_dist(e, PLAYER)
                if e.TMod.x.base ~= PLAYER.TMod.x.base and e.TMod.y.base ~= PLAYER.TMod.y.base and dist <= 3 then
                    self.targets[#self.targets + 1] = e
                end
            end
            if #self.targets > 0 then return "hasState" end
        end
        return false
    end,
    onUse = function(self, enemy)
        if not self.isBeingUsed then
            TARGETED_ENEMIES = self.targets
        else
            enemy:modHP(self.config.damage)
            Util.World.modTime(self.config.timeCost)
        end
    end
})

registerItem({
    key = "knife",
    sprite = "ItemKnife",
    config = {
        damage = -2,
        timeCost = 2
    },
    canUse = function(self)
        local enemies = Util.World.getAllWorldMoveablesWithType("enemy")

        local vertices = getAllValidVertices(G.flags.saveData.curRoom.size.w, G.flags.saveData.curRoom.size.h, {"wall"})
        local adjacents = getAllAdjacentVertices(vertices, { PLAYER.TMod.x.base, PLAYER.TMod.y.base })

        if not self.isBeingUsed then
            self.targets = {}
            for _, e in ipairs(enemies) do
                for _, v in ipairs(adjacents) do
                    if e.TMod.x.base == v[1] and e.TMod.y.base == v[2] then
                        self.targets[#self.targets + 1] = e
                    end
                end
            end
            if #self.targets > 0 then return "hasState" end
        end
        return false
    end,
    onUse = function(self, enemy)
        if not self.isBeingUsed then
            TARGETED_ENEMIES = self.targets
        else
            enemy:modHP(self.config.damage)
            Util.World.modTime(self.config.timeCost)
        end
    end
})

registerItem({
    key = "greatsword",
    sprite = "ItemGreatsword",
    config = {
        damage = -5,
        timeCost = 3
    },
    canUse = function(self)
        local enemies = Util.World.getAllWorldMoveablesWithType("enemy")

        if not self.isBeingUsed then
            self.targets = {}
            for _, e in ipairs(enemies) do
                if get_orthogonal_dist(e, PLAYER) <= 2 then
                    self.targets[#self.targets + 1] = e
                end
            end
            return #self.targets >= 1 and "noState" or nil
        end
    end,
    onUse = function(self, enemy)
        if #self.targets >= 1 then
            for _, enemy in ipairs(self.targets) do
                enemy:modHP(self.config.damage)
            end
            Util.World.modTime(self.config.timeCost)
        end
    end
})
registerItem({
    key = "sunscreen",
    sprite = "ItemSunscreen",
    config = {
        timeMod = 3
    },
    calculate = function (context, self)
        if context.death and context.method == "timer" then
            G.flags.saveData.timemod = G.flags.saveData.timemod + 30
            discardItem(nil, self.key)
        end
    end
})


registerItem({
    key = "rapier",
    sprite = "ItemRapier",
    config = {
        damage = -4,
        timeCost = 1
    },
    canUse = function(self)
        local enemies = Util.World.getAllWorldMoveablesWithType("enemy")

        local vertices = getAllValidVertices(G.flags.saveData.curRoom.size.w, G.flags.saveData.curRoom.size.h, {"wall"})
        local adjacents = getAllAdjacentVertices(vertices, { PLAYER.TMod.x.base, PLAYER.TMod.y.base })

        if not self.isBeingUsed then
            local temp_targets = {}
            for _, e in ipairs(enemies) do
                local dist = get_orthogonal_dist(e, PLAYER)
                if (e.TMod.x.base == PLAYER.TMod.x.base or e.TMod.y.base == PLAYER.TMod.y.base) and dist == 2 then
                    temp_targets[#temp_targets + 1] = e
                end
            end
            self.targets = {}
            for _, e in ipairs(temp_targets) do
                local okay = true
                for _, v in ipairs(adjacents) do
                    if e.TMod.x.base == v[1] and e.TMod.y.base == v[2] then
                        okay = false
                        break
                    end
                end
                if okay then
                    self.targets[#self.targets + 1] = e
                end
            end
            
            if #self.targets > 0 then return "hasState" end
        end
        return false
    end,
    onUse = function(self, enemy)
        if not self.isBeingUsed then
            TARGETED_ENEMIES = self.targets
        else
            enemy:modHP(self.config.damage)
            Util.World.modTime(self.config.timeCost)
            -- move to the midpoint
            local mx = (enemy.TMod.x.base + PLAYER.TMod.x.base)/2
            local my = (enemy.TMod.y.base + PLAYER.TMod.y.base)/2
            PLAYER.TMod.x.base = mx
            PLAYER.TMod.y.base = my
        end
    end
})

registerItem({
    key = "aura",
    sprite = "ItemEminence",
    config = {
        damage = -1,
    },
    calculate = function (context, self)
        if context.itemUsed and context.hasState then
            for _, enemy in ipairs(Util.World.getAllWorldMoveablesWithType("enemy")) do
                enemy:modHP(self.config.damage, true)
            end
        end
    end,
})
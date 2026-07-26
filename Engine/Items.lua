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
        isKey = args.isKey == true,
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
        local shouldDrop = Centers[key].isKey
            and PLAYER
            and G.flags.saveData.curRoom
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
        if shouldDrop then
            Util.World.spawnGroundItemPickup(
                key,
                PLAYER.TMod.x.base,
                PLAYER.TMod.y.base,
                true
            )
        end
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
---@param excluded? table<string, boolean>
---@return string? key
function poolItem(pool, excluded)
    excluded = excluded or {}
    if pool then
        local t = {}
        for k, v in ipairs(Pools[pool].keys) do
            if not excluded[v]
                and Centers[v].inPool()
                and not hasItem(v)
            then
                table.insert(t, v)
            end
        end
        if #t == 0 then
            return nil
        end
        return Util.Math.randomElement(t).v
    end
    local chances = {}
    for key, itemPool in pairs(Pools) do
        local hasEligibleItem = false
        for _, itemKey in ipairs(itemPool.keys) do
            if not excluded[itemKey]
                and Centers[itemKey].inPool()
                and not hasItem(itemKey)
            then
                hasEligibleItem = true
                break
            end
        end
        if hasEligibleItem then
            table.insert(chances, {val = key, weight = itemPool.rate})
        end
    end
    if #chances == 0 then
        return nil
    end
    local p = Util.Math.weightedChance(chances)
    return poolItem(p, excluded)
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

function cancelActiveItemUse()
    TARGETED_ENEMIES = nil
    for _, item in ipairs(G.flags.saveData.items) do
        item.isBeingUsed = false
    end
end

function activateItemSlot(slot)
    local item = G.flags.saveData.items[slot]
    if not item then
        return false
    end
    if item.isBeingUsed then
        cancelActiveItemUse()
        return true
    end

    cancelActiveItemUse()
    local center = Centers[item.key]
    local state = center.canUse(item)
    local key = item.key
    if state == "noState" then
        center.onUse(item)
        CALCULATECONTEXT({
            itemUsed = true,
            usedItem = { slot = slot, key = key },
            hasState = false,
        })
        return true
    elseif state == "hasState" then
        center.onUse(item)
        item.isBeingUsed = true
        CALCULATECONTEXT({
            itemUsed = true,
            usedItem = { slot = slot, key = key },
            hasState = false,
        })
        return true
    end
    return false
end

function useActiveItemOnTarget(target)
    for slot, item in ipairs(G.flags.saveData.items) do
        if item.isBeingUsed then
            local key = item.key
            Centers[key].onUse(item, target)
            move_all_enemies()
            item.isBeingUsed = false
            TARGETED_ENEMIES = nil
            CALCULATECONTEXT({
                itemUsed = true,
                usedItem = { slot = slot, key = key },
                hasState = true,
            })
            return true
        end
    end
    TARGETED_ENEMIES = nil
    return false
end

local get_orthogonal_dist = function(a, b)
    return math.abs(a.TMod.x.base - b.TMod.x.base) + math.abs(a.TMod.y.base - b.TMod.y.base)
end

registerItem({
    key = "musket",
    sprite = "ItemMusket",
    config = {
        damage = -10,
        timeCost = 6,
        vars = {
            10,
            6
        }
    },
    text = {
        "|s:2,2|Musket",
        "|s:2,2|Type: Weapon",
        "|s:2,2|Cost: {2} Mins",
        "|s:2,2|Damage: {1}",
        "|s:2,2|This weapon can attack",
        "|s:2,2|all units orthogonal",
        "|s:2,2|to it, like a rook.",
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
        timeCost = 3,
        vars = {
            4,
            3
        },
    },
    text = {
        "|s:2,2|Whip",
        "|s:2,2|Type: Weapon",
        "|s:2,2|Cost: {2} Mins",
        "|s:2,2|Damage: {1}",
        "|s:2,2|This weapon can attack",
        "|s:2,2|all units a knight's distance",
        "|s:2,2|or a single bishop move to it.",
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
        timeCost = 2,
        vars = {
            2,
            2
        },
    },
    text = {
        "|s:2,2|Knife",
        "|s:2,2|Type: Weapon",
        "|s:2,2|Cost: {2} Mins",
        "|s:2,2|Damage: {1}",
        "|s:2,2|This weapon can attack",
        "|s:2,2|all units adjacent to it.",
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
        timeCost = 3,
        vars = {
            5,
            3
        }
    },
    text = {
        "|s:2,2|Greatsword",
        "|s:2,2|Type: Weapon",
        "|s:2,2|Cost: {2} Mins",
        "|s:2,2|Damage: {1}",
        "|s:2,2|This weapon can attack",
        "|s:2,2|all units within an",
        "|s:2,2|taxi-cab distance of 2."
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
        timeMod = 30,
        vars = {
            30,
        }
    },
    text = {
        "|s:2,2|Sunscreen",
        "|s:2,2|Type: Static",
        "|s:2,2|This item gives you",
        "|s:2,2|{1} more minutes",
        "|s:2,2|to live when you die."
    },
    canUse = function ()
        return false
    end,
    calculate = function (context, self)
        if context.death and context.method == "timer" then
            G.flags.saveData.timemod = G.flags.saveData.timemod + self.config.timeMod
            discardItem(nil, self.key)
        end
    end
})


registerItem({
    key = "rapier",
    sprite = "ItemRapier",
    config = {
        damage = -4,
        timeCost = 1,
        vars = {
            4,
            1
        }
    },
    text = {
        "|s:2,2|Rapier",
        "|s:2,2|Type: Weapon",
        "|s:2,2|Cost: {2} Mins",
        "|s:2,2|Damage: {1}",
        "|s:2,2|This weapon can attack",
        "|s:2,2|all units 2 spaces away,",
        "|s:2,2|and lunges toward it",
        "|s:2,2|by 1 unit."
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
            PLAYER:moveToGrid(mx, my)
        end
    end
})

registerItem({
    key = "aura",
    sprite = "ItemEminence",
    config = {
        damage = -1,
        vars = {
            1,
        }
    },
    text = {
        "|s:2,2|Eminence",
        "|s:2,2|Type: Static",
        "|s:2,2|This item deals {1}",
        "|s:2,2|damage to all units",
        "|s:2,2|when an item is used.",
    },
    calculate = function (context, self)
        if context.itemUsed and context.hasState then
            for _, enemy in ipairs(Util.World.getAllWorldMoveablesWithType("enemy")) do
                enemy:modHP(self.config.damage, true)
            end
        end
    end,
})

registerItem({
    key = "prison_key",
    sprite = "ItemPrisonKey",
    isKey = true,
    inPool = function()
        return false
    end,
    text = {
        "|s:2,2|Prison Key",
        "|s:2,2|Type: Key",
        "|s:2,2|You may find that",
        "|s:2,2|this key opens many",
        "|s:2,2|new doors for you.",
        "|s:2,2|Consumed when used.",
    },
    canUse = function(self)
        if not self.isBeingUsed then
            self.targets = {}
            for _, gate in ipairs(Util.World.getAllWorldMoveablesWithType("gate")) do
                if gate.extra.locked and get_orthogonal_dist(gate, PLAYER) == 1 then
                    self.targets[#self.targets + 1] = gate
                end
            end
            if #self.targets > 0 then
                return "hasState"
            end
        end
        return false
    end,
    onUse = function(self, gate)
        if not self.isBeingUsed then
            TARGETED_ENEMIES = self.targets
        elseif gate and gate:unlock() then
            discardItem(nil, self.key)
        end
    end,
})

registerItem({
    key = "sacrificial_dagger",
    sprite = "ItemDagger",
    config = {
        enemy_damage = -1,
        self_healing = 2,
        time_cost = 1,
        vars = {
            1,
            2,
            1
        }
    },
    text = {
        "|s:2,2|Sacrificial Dagger",
        "|s:2,2|Type: Weapon",
        "|s:2,2|Cost: {3} Mins",
        "|s:2,2|Damage: {1}",
        "|s:2,2|This weapon can attack",
        "|s:2,2|all units adjacent to it.",
        "|s:2,2|Has a lifesteal of {2} HP."
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

            if #self.targets > 0 then
                return "hasState"
            end
        end
    end,
    onUse = function(self, enemy)
        if not self.isBeingUsed then
            TARGETED_ENEMIES = self.targets
        else
            enemy:modHP(self.config.enemy_damage)

            local heal_amount = math.max(0, math.min(self.config.self_healing, Macros.maxhp - G.flags.saveData.hp))
            Util.World.modHP(heal_amount)
            
            Util.World.modTime(self.config.time_cost)
        end
    end
})

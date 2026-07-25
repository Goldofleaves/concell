Centers = {}
Pools = {
    common = { rate = 3, keys = {} },
    uncommon = { rate = 2, keys = {} },
    rare = { rate = 1, keys = {} }
}
function registerItem(args)
    args.key = args.key or "ERROR"
    local t = {
        onGet = args.onGet or function (config) end,
        defaultConfig = args.config or {},
        onDiscard = args.onDiscard or function(config) end,
        calculate = args.calculate or function (context, config)
            
        end,
        pool = args.pool or "common",
        inPool = args.inPool or function () return true end,
        sprite = args.sprite or "ERROR",
        update = args.update or function (config) end,
        canUse = args.canUse or function() return "noState" end,
        IBUupdate = args.IBUupdate or function (config) end,
        onUse = args.onUse or function(config) end,
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
        Centers[key].onGet(t.config)
        return true
    end
    return false
end
---@param slot number
---@param key? string
---@return boolean success
function discardItem(slot, key)
    if not key then
        local t = table.remove(G.flags.saveData.items, slot)
        Centers[t.key].onDiscard(t.config)
        return true
    end
    for k, v in ipairs(G.flags.saveData.items) do
        if v.key == key then
            Centers[v.key].onDiscard(v.config)
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
        Centers[v.key].calculate(context, v.config)
    end
end

registerItem({
    key = "musket",
    sprite = "ItemMusket"
})

registerItem({
    key = "whip",
    sprite = "ItemWhip"
})

registerItem({
    key = "knife",
    sprite = "ItemKnife",
    config = {
        damage = 3,
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

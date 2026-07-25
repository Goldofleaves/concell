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
        inPool = args.inPool or function () end
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
            config = Util.Other.copyTable(Centers[key].config)
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
        return Util.Math.randomElement(Pools[pool].keys).v
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
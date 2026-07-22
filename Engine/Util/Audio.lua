local audioLib = {}
Macros.sounds = {}
local registerSource = function(name, path, extra)
    extra = extra or {}
    local s_path = ''
    for _, v in ipairs(path) do
        s_path = s_path .. '/' .. v
    end
    s_path = s_path:sub(2, s_path:len())
    local source = love.audio.newSource(s_path .. ".ogg", "static")
    source:setVolume(extra.volume or 1)
    source:setPitch(extra.pitch or 1)
    source:setLooping(extra.looping or false)
    return source
end

---Registers a new sound.
---@param name string The internal ID of the sound file.
---@param path string[] The path to the sound.
---@param extra? {overwrite?:boolean, volume?:integer, pitch?:integer}
function audioLib.registerSfx(name, path, extra)
    extra = extra or {}
    extra.overwrite = extra.overwrite or false
    extra.volume = extra.volume or 1
    extra.pitch = extra.pitch or 1

    for k, v in pairs(Macros.sounds) do
        if k == name then
            if extra.overwrite then
                print(
                    string.format('[AUDIO WARNING/REGISTER SOUND] \'%s\' is already registered. Overwritting.', name)
                )
            else
                print(
                    string.format('[AUDIO WARNING/REGISTER SOUND] \'%s\' is already registered. Not registering.', name)
                )
                return false
            end
        end
    end

    Macros.sounds[name] = {
        source = registerSource(name, table.merge({ "assets", "sounds", "sfx" }, path), extra),
        type = 'sfx'
    }
    print(
        string.format('[AUDIO INFO/REGISTER SOUND] \'%s\' has been registered.', name)
    )
    return true
end

---Registers a new music
---@param name string The internal ID of the sound file.
---@param path string[] The path to the sound.
---@param extra? {overwrite?:boolean, volume?:number, pitch?:integer}
function audioLib.registerMusic(name, path, extra)
    extra = extra or {}
    extra.overwrite = extra.overwrite or false
    extra.volume = extra.volume or 1
    extra.pitch = extra.pitch or 1

    for k, v in pairs(Macros.sounds) do
        if k == name then
            if extra.overwrite then
                print(
                    string.format('[AUDIO WARNING/REGISTER MUSIC] \'%s\' is already registered. Overwritting.', name)
                )
            else
                print(
                    string.format('[AUDIO WARNING/REGISTER MUSIC] \'%s\' is already registered. Not registering.', name)
                )
                return false
            end
        end
    end

    Macros.sounds[name] = {
        source = registerSource(name, table.merge({ "assets", "sounds", "music" }, path), extra),
        type = 'bgm',
        group = '',
    }
    print(
        string.format('[AUDIO INFO/REGISTER MUSIC] \'%s\' has been registered.', name)
    )
    return true
end

---Plays a sound effect
---@param sfx_name string The ID of the sound
---@param volume? number The volume of the sound effect, ranging between 0 and 1.
---@param pitch? number The pitch of the sound effect.
---@param id? string An ID to the sound effect
---@param noDelete? boolean If the sound effect should be deleted when stopped
---@return unknown
function audioLib.playSfx(sfx_name, volume, pitch, id, noDelete)
    volume = volume or 1
    pitch = pitch or 1
    if not Macros.sounds[sfx_name] then
        print(
            string.format('[AUDIO ERROR/PLAY_SFX] Audio with ID \'%s\' Is not registered!', sfx_name)
        )
        return false
    end
    local sfx = Macros.sounds[sfx_name].source:clone()
    sfx:setVolume(sfx:getVolume() * volume * G.settings.sound.sfx / 100 * G.settings.sound.master / 100)
    sfx:setPitch(sfx:getPitch() * pitch)
    G.audio.sfx[#G.audio.sfx + 1] = {
        source = sfx,
        id = id,
        noDelete = noDelete or false
    }
    love.audio.play(sfx)
    return sfx
end

---Adds a track to the music stack.
---@param id string The name of the source.
---@param playId? string The id to use when playing. Important to be able to later remove this source from the stack.
---@param group? string The group this music belongs to. Used for syncing different tracks.
---@param vol? number The volume of the track.
---@param pitch? number The pitch of the track.
---@param extra? {looping:boolean, endFunc?:function, force:boolean}
function audioLib.musicPush(id, playId, group, vol, pitch, extra, priority)
    if not id then
        print(string.format('[AUDIO ERROR/MUSIC PUSH] ID not provided'))
        return false
    elseif not Macros.sounds[id] then
        print(string.format('[AUDIO ERROR/MUSIC PUSH] \'%s\' is not registered!', id))
        return false
    elseif Macros.sounds[id].type ~= 'bgm' then
        print(string.format('[AUDIO ERROR/MUSIC PUSH] \'%s\' is not a valid entry as BGM!', id))
        return false
    end
    if not playId then
        print(string.format('[AUDIO WARNING/MUSIC PUSH] \'%s\' has no playing ID!', id))
    end
    for _, v in ipairs(G.audio.music) do
        if v.id == playId then
            print(string.format('[AUDIO WARNING/MUSIC PUSH] \'%s\' already exists!', playId))
            if not extra or not extra.force then return false end
            print(string.format('[AUDIO WARNING/MUSIC PUSH] \'%s\' has been forcefully added!', id))
        end
    end

    vol = vol or 1
    pitch = pitch or 1
    extra = extra or {}
    extra.looping = extra.looping or true
    local source = Macros.sounds[id].source:clone()
    source:setLooping(extra.looping)
    source:setPitch(source:getPitch() * pitch)
    table.insert(G.audio.music, {
        source = source,
        id = id,
        playId = playId,
        group = group,
        volume = source:getVolume(),
        priority = priority,
        endFunc = extra.endFunc
    })
    source:play()
    return source
end

function audioLib.getHighestPriorityMusic()
    local max = 0
    for k, v in pairs(G.audio.music) do
        max = math.max(max, v.priority)
    end
    for k, v in pairs(G.audio.music) do
        if v.priority == max then
            return v
        end
    end
end

---Removes a track from the music stack.
---@param playId string The playId of the track.
---@return boolean success Wether a track was removed.
function audioLib.musicPop(playId)
    for i, v in ipairs(G.audio.music) do
        if v.playId == playId then
            v.source:stop()
            v.source:release()
            table.remove(G.audio.music, i)
            return true
        end
    end
    return false
end

function audioLib.getSfxById(id)
    for _, v in ipairs(G.audio.sfx) do
        if v.id == id then return v end
    end
end

Util.Audio = audioLib

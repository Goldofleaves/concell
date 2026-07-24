---@class Event: Object
--- `easeFunc` - Runs every frame for the duration of the event\
--- `func` - Runs at the start of the event\
--- `endFunc` - Runs at the end of the event\
--- `duration` - In seconds, the duration of the event\
--- `skippable` - Whether this function can be skipped or not.\
--- `nid` - The unique-identifier to events.\
--- `extra` - Other data not included above, used primarely for very specific use-cases.
Event = Object:extend()
function Event:new(args)
	args = args or {}
	self.id = G.currentID
	G.currentID = G.currentID + 1
	self.nid = args.nid or "_"
	self.ease = args.ease == nil and true or args.ease
	self.curTime = 0
	self.easeFunc = args.easeFunc or function() end
	self.endFunc = args.endFunc or function () end
	self.completed = false
	self.duration = args.duration or 1
	self.extra = args.extra
	self.drawFunc = args.drawFunc or function () end
	self.drawOrder = args.drawOrder or 0
	self.type = "event"
	self.paused = false
	return self
end
Util.Event = {}

function getEventByNid(nid)
	if not nid then return false end
	for _, queue in pairs(G.events) do
		for _, v in pairs(queue) do
			if v.nid == nid then
				return v
			end
		end
	end
	return false
end
function Event:pause()
	self.paused = true
end

function Event:unpause()
	self.paused = false
end
function Util.Event.addEvent(e, queue, front)
	G.events[queue or "main"] = G.events[queue or "main"] or {}
	local q = G.events[queue or "main"]
	if front then
		table.insert(q, 1, e)
	else
		table.insert(q, e)
	end
end

function Util.Event.delayFunc(t, f, q)
	Util.Event.addEvent(Event(
		{
			duration = t,
			endFunc = f,
		}
	),q)
end

function Util.Event.transition(t, f, q, c, endFunc)
	if not getEventByNid("transition") then
		f = f or function() end
		Util.Event.delayFunc(t / 2, f, q)
		endFunc = endFunc or function() end
		c = c or Macros.colors.lightBlack
		Util.Event.addEvent(Event(
			{
				drawOrder = 1e30,
				duration = t,
				nid = "transition",
				easeFunc = function(time, s)
					s.extra.y = Util.EaseSplines.createEase(G.drawinfo.supergridSize.y + 1,
					-G.drawinfo.supergridSize.y - 1,
							function(x)
								return x
							end, { preset = "eioc", param = 1.75 })(time)
				end,
				extra = {
					y = G.drawinfo.supergridSize.y + 1
				},
				drawFunc = function(time, s)
					local df = function()
						local r, g, b, a = love.graphics.getColor()
						love.graphics.setColor(c)
						love.graphics.rectangle("fill", G.drawinfo.superorigin.x, G.drawinfo.superorigin.y + s.extra.y,
							G.drawinfo.supergridSize.x, G.drawinfo.supergridSize.y)
						love.graphics.setColor(Macros.colors.white)
						love.graphics.rectangle("fill", G.drawinfo.superorigin.x,
						G.drawinfo.superorigin.y + s.extra.y - 1,
							G.drawinfo.supergridSize.x, 1)
						love.graphics.rectangle("fill", G.drawinfo.superorigin.x,
							G.drawinfo.superorigin.y + s.extra.y + G.drawinfo.supergridSize.y,
							G.drawinfo.supergridSize.x, 1)
						love.graphics.setColor(r, b, g, a)
					end
					df()
				end,
				endFunc = function(s)
					endFunc()
				end
			}
		))
	end
end

function Util.Event.easeOutMusic(t, m)
	Util.Event.addEvent(Event(
		{
			duration = t,
			easeFunc = function(time, s)
				local targetBgm = Util.Audio.getHighestPriorityMusic()
				if targetBgm and targetBgm.source then
					targetBgm.source:setVolume((1 - time) * targetBgm.volume * G.settings.sound.music / 100 *
						G.settings.sound.master /
						100)
				end
			end,
			endFunc = function()
				Util.Audio.musicPop(m)
			end
		}
	), "musicEase")
end

function Util.Event.easeInMusic(t, id, pid, grp, extra, prior)
	extra = extra or { looping = true }
	prior = prior or 6
	Util.Audio.musicPush(id, pid, grp, prior, 1, 1, extra)
	Util.Event.addEvent(Event(
		{
			duration = t,
			easeFunc = function(time, s)
				local targetBgm = Util.Audio.getHighestPriorityMusic()
				if targetBgm and targetBgm.source then
					targetBgm.source:setVolume(time * targetBgm.volume * G.settings.sound.music / 100 *
						G.settings.sound.master /
						100)
				end
			end
		}
	), "musicEase")
end

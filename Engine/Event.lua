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
	for k, v in pairs(G.events) do
		if v.nid == nid then
			return v
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

function Util.Event.delayFunc(t, f)
	Util.Event.addEvent(Event(
		{
			duration = t,
			endFunc = f
		}
	))
end
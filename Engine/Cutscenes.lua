Macros.CDefs = {}
Macros.CDefs.Opening = function()
	local list_of_nids = {
		"titlebutton1",
		"titlebutton2",
		"titlebutton3",
		"tbg",
		"tfg",
		"td",
	}
	for k, v in pairs(list_of_nids) do
		local o = getObjectByNid(v)
		if o then o:remove() end
	end
	Sprite({
		nid = "openingcutscene",
		drawOrder = 100,
		x = Macros.grandOffsetVector.contents[1],
		y = Macros.grandOffsetVector.contents[2],
		atlasKey = "cutscene",
		scaleX = 2,
		scaleY = 2,
		extra = {
			progressed = false,
			timer1 = 0,
			text = {
				[false] = {
					"|f:times||o:white||c:night|This is it, Count Dawn.",
					"|f:times||o:white||c:night|You're not getting away this time.",
				},
				[true] = "|f:times||o:white||c:night|Have fun rotting in prison."
			}
		},
		updateFunc = function(s, dt)
			s.extra.timer1 = s.extra.timer1 + dt
			s.T.y = Util.Math.lerpDt(s.T.y, Macros.grandOffsetVector.contents[2] - (s.extra.progressed and 5 or 0), 0.02)
			if s.extra.timer1 > 2 and G.mouseController[1].pressed and not s.extra.progressed then
				s.extra.timer1 = 0
				s.extra.progressed = true
			end
			if s.extra.timer1 > 1 and G.mouseController[1].pressed and s.extra.progressed == true then
				Util.Event.easeOutMusic(2, "interrogationID")
				Util.Event.transition(4, function()
					s:remove()
					addItem("knife")
					Macros.UIDef.overlay()
					-- Util.Audio.musicPush("battle", "battleID", "normal", 1, 1, 1)
					-- if Util.Audio.getMusicByID("battleID") and Util.Audio.getMusicByID("battleID").source then
					-- 	Util.Audio.getMusicByID("battleID").source:setVolume(0)
					-- end
					Util.Event.easeInMusic(2, "overworld", "overworldID", "normal", nil, 2)
					G.flags.saveData.rooms = Util.World.generateDungeon()
					G.flags.saveData.curRoomIndex = 1
					G.flags.saveData.curRoom = G.flags.saveData.rooms[1]
					PLAYER = WorldMoveable({
						x = 0,
						y = math.floor(G.flags.saveData.curRoom.size.h / 2),
						type = "player",
						updateOrder = 1,
						drawOrder = 31,
						extra = {facing = "3"}
					})
					Macros.MDef.isometricGrid(G.flags.saveData.curRoom.size.w, G.flags.saveData.curRoom.size.h,
						Util.World.getArea(1))
					WorldMoveable:initRoomStuff()
				end, "delay1")
				s.extra.progressed = 1
			end
		end,
		drawFunc = function (s)
			if s.extra.progressed then
				AdvancedText(s.extra.text[true]):draw(1, 1, true)
			else
				AdvancedText(s.extra.text[s.extra.progressed][1]):draw(1, 1, true)
				AdvancedText(s.extra.text[s.extra.progressed][2]):draw(1, 2.5, true)
			end
		end
	})
end
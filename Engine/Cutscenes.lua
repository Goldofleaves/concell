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
					G.flags.saveData.igt = 0
					s:remove()
					addItem("knife")
					addItem("excalibur")
					Macros.UIDef.overlay()
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
Macros.CDefs.Death = function()
	Sprite({
		nid = "gameOver",
		drawOrder = 100,
		x = Macros.grandOffsetVector.contents[1],
		y = Macros.grandOffsetVector.contents[2],
		atlasKey = "gameOver",
		scaleX = 2,
		scaleY = 2,
		updateFunc = function(s, dt)
			if G.mouseController[1].pressed then
				Util.Event.transition(4, function()
					s:remove()
					love.load()
				end, "delay1")
			end
		end,
		drawFunc = function(s)
		end
	})
end
Macros.CDefs.Win = function(ss, data)
	G = Game()
	Sprite({
		nid = "gameWin",
		drawOrder = 100,
		x = Macros.grandOffsetVector.contents[1],
		y = Macros.grandOffsetVector.contents[2],
		atlasKey = "gameWin",
		scaleX = 2,
		scaleY = 2,
		extra = {
			text = createTableOfAdvancedText({
				"|c:dawn||s:2.5,2.5|Your time was " .. math.floor(data.igt).." seconds.",
				"|c:dawn||s:2.5,2.5|You dealt " .. data.totalDamage .. " damage in total.",
				"|c:dawn||s:2.5,2.5|You slain " .. data.enemiesSlain .. " enemies in total.",
				"|c:dawn||s:2.5,2.5|You did well.",
			})
		},
		updateFunc = function(s, dt)
			if G.mouseController[1].pressed and not getEventByNid("end") then
				Util.Event.transition(4, function()
					ss:stop()
					ss:release()
					G.audio = {
						sfx = {},
						music = {},
						musicHandler = {}
					}
					s:remove()
					love.load()
				end, "gameWin")
			end
		end,
		drawFunc = function(s)
			local x = G.drawinfo.origin.x + G.drawinfo.gridSize.x / 400 * 243
			local y = G.drawinfo.origin.y + G.drawinfo.gridSize.y / 300 * 15
			for k, v in ipairs(s.extra.text) do
				v:draw(x, y)
				y = y + v:getHeight()
			end
		end
	})
end

Macros.CDefs = {}
Macros.CDefs.Opening = function ()
	local easeFunc = Util.EaseSplines.createEase(0, 1, nil, { preset = "eob", param = 1 })
	local easeFuncNoRebound = Util.EaseSplines.createEase(0, 1, nil, { preset = "eoc", param = 2 })
	local easeFunc1 = Util.EaseSplines.createEase(0, 1.1, nil, { preset = "eoc", param = 2 })
	local easeFunc2 = Util.EaseSplines.createEase(1.1, 1, nil, { preset = "eioc", param = 1.75 })
	local easeGeneral = function (t)
		local durA = 0.65
		if t < durA then
			return easeFunc1(t/durA)
		else
			return easeFunc2((t-durA)/(1-durA))
		end
	end
	local centerX = Macros.posCenter.x
	local centerY = Macros.posCenter.y
	local function generateBlob(mass, radiusFromCenter, initialVelocity)
		local radiusToSqrtMassConstant = 1
		local accelerationConstant --[[i give up naming this one]] = 0.1
		local angle = math.betterrandom(0, math.tau)
		local dx, dy = math.cos(angle) * radiusFromCenter, math.sin(angle) * radiusFromCenter
		local angleV = math.betterrandom(0, math.tau)
		Moveable {
			drawOrder = 1,
			extra = {
				V = Vector(math.cos(angleV) * initialVelocity, math.sin(angleV) * initialVelocity),
				A = Vector(0, 0),
			},
			x = centerX + dx,
			y = centerY + dy,
			drawFunc = function(s)
				local r, g, b, a = love.graphics.getColor()
				love.graphics.setColor(Macros.colors.black)
				local uix, uiy = Util.UI.convertPosToUIPos(s.T.x, s.T.y)
				love.graphics.circle("fill", uix, uiy, radiusToSqrtMassConstant * mass ^ (1/2) * G.drawinfo.gridUnit)
				love.graphics.setColor(r, g, b, a)
			end,
			updateFunc = function(s, dt)
				local center = Vector(centerX, centerY)
				local distanceTowardsCenter = Util.Math.pythagorean(s.T, {x = centerX, y = centerY})
				local aAbs = accelerationConstant * mass / distanceTowardsCenter
				local positionVector = Vector(s.T.x, s.T.y)
				local force = center:sub(positionVector, true)
				s.extra.A = force:scale(aAbs * dt * 45, true)
				s.extra.V:add(s.extra.A)
				s.TMod.x.base = s.TMod.x.base + s.extra.V.contents[1] * dt
				s.TMod.y.base = s.TMod.y.base + s.extra.V.contents[2] * dt
			end
		}
	end
	for i = 1, 20 do
		local m = math.betterrandom(0.05, 1.75)
		generateBlob(m, math.betterrandom(0.75, 1.25), math.betterrandom(0.7, 1.25) * (2 - m) * 0.8)
	end
	Util.Event.addEvent(Event{
		extra = {
			heart = Moveable {
				drawOrder = 2,
				extra = {size = 0},
				drawFunc = function(s)
					local r, g, b, a = love.graphics.getColor()
					love.graphics.setColor(Macros.colors.white)
					local sina = math.sin(G.timer * 1.5) / 8
					local sinb = math.cos(G.timer * 1.75) / 12
					local radius = 0.35 * s.extra.size / 1.05
					local dx = radius
					local uix, uiy = Util.UI.convertPosToUIPos(centerX + dx + sina, centerY - radius + sinb)
					love.graphics.circle("fill", uix, uiy, G.drawinfo.gridUnit * radius * 1.05)
					uix, uiy = Util.UI.convertPosToUIPos(centerX - dx + sina, centerY - radius + sinb)
					love.graphics.circle("fill", uix, uiy, G.drawinfo.gridUnit * radius * 1.05)
					uix, uiy = Util.UI.convertPosToUIPos(centerX + sina, centerY + sinb - 0.02)
					Util.Draw.drawRotatedRectangle(uix, uiy, G.drawinfo.gridUnit * 2 * radius * 1.07,
						G.drawinfo.gridUnit * 2 * radius * 1.07, math.pi / 4)
					love.graphics.setColor(Macros.colors.red)
					love.graphics.setColor(r, g, b, a)
				end,
			}
		},
		duration = 2,
		easeFunc = function (t, s) -- pmo
			love.window.updateMode(easeGeneral(t) * 800, easeFunc(t) * 600, { resizable = false, centered = true })
			s.extra.heart.extra.size = easeFuncNoRebound(t)
		end,
		endFunc = function()
			love.window.updateMode(800, 600, { resizable = true, centered = false })
			print("ended")
		end
	})
end
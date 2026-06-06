-- we draw
local drawLib = {}
-- uhh what the fuck do i do now


--- Draw an slanted rectangle.
--- @param x number
--- @param y number
--- @param w number
--- @param h number
--- @param angle number
--- @param centered boolean|nil
function drawLib.drawRotatedRectangle(x, y, w, h, angle, centered)
	angle = angle % math.tau
	centered = centered == nil and true or centered
	local cosa, sina = math.cos(angle), math.sin(angle)

	local dx1, dy1 = w * cosa, w * sina
	local dx2, dy2 = -h * sina, h * cosa

	local px1, py1 = x, y
	local px2, py2 = x + dx1, y + dy1
	local px3, py3 = x + dx1 + dx2, y + dy1 + dy2
	local px4, py4 = x + dx2, y + dy2

	if centered then
		local centerx, centery = (x + x + dx1 + dx2) / 2, (py1 + py3) / 2
		local dx, dy = centerx - px1, centery - py1
		px1 = px1 - dx
		px2 = px2 - dx
		px3 = px3 - dx
		px4 = px4 - dx
		py1 = py1 - dy
		py2 = py2 - dy
		py3 = py3 - dy
		py4 = py4 - dy
	end
	love.graphics.polygon("fill", px1, py1, px2, py2, px3, py3, px4, py4)
end

Util.Draw = drawLib
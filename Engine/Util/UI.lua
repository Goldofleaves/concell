Util.UI = {}
function Util.UI.convertPosToUIPos(x, y)
	return x * G.drawinfo.gridUnit + G.drawinfo.origin.x, y * G.drawinfo.gridUnit + G.drawinfo.origin.y
end
function Util.UI.convertUIPosToPos(x, y)
	return (x - G.drawinfo.origin.x) / G.drawinfo.gridUnit, (y - G.drawinfo.origin.y) / G.drawinfo.gridUnit
end

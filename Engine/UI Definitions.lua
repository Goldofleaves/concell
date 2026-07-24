Macros.UIDef = {}
function Macros.UIDef.title()
    local phi1, phi2, chi, a1, a2 = math.betterrandom(0.5, 1.1), math.betterrandom(0.5, 1.1),
        math.betterrandom(0, math.tau), math.betterrandom(1, 2), math.betterrandom(1, 2)
    Sprite({
        nid = "tbg",
        drawOrder = 1,
        x = Macros.grandOffsetVector.contents[1],
        y = Macros.grandOffsetVector.contents[2],
        atlasKey = "titlescreenBg",
        scaleX = 2,
        scaleY = 2
    })
    Sprite({
        nid = "tfg",
        drawOrder = 2,
        x = Macros.grandOffsetVector.contents[1],
        y = Macros.grandOffsetVector.contents[2],
        atlasKey = "titlescreenFg",
        scaleX = 2,
        scaleY = 2,
        updateFunc = function (s)
            s.T.x = Macros.grandOffsetVector.contents[1] + (a1 / 40 * math.sin(phi1 * G.timer))
            s.T.y = Macros.grandOffsetVector.contents[2] +a2/40 + (a2 / 40 * math.sin(phi2 * (G.timer + chi)))
        end
    })
end
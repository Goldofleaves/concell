Util.Color = {}
Util.Color.SetOpacity = function (a, o)
    return {a[1], a[2], a[3], a[4] * o}
end
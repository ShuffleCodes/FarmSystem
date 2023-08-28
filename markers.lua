

local light = dxCreateTexture("img/light.png", "argb")
local arrow = dxCreateTexture("img/arrow.png", "argb")
local anim_type = "foward"
local distance = 50
local animTime = 0

addEventHandler("onClientPreRender", root,
    function()
        for i, v in ipairs(getElementsByType("marker")) do
            if getElementData(v, "Farm:Data") and isElementStreamedIn(v) then
                local x, y, z = getElementPosition(v)
                local gz = getGroundPosition(x, y, z)
                z = gz
                local x2, y2, z2 = getElementPosition(localPlayer)
                local r, g, b, a = getMarkerColor(v)
                local cx, cy, cz = getCameraMatrix()

                local distanceBetweenPoints = getDistanceBetweenPoints3D(x, y, z, x2, y2, z2)
                if (distanceBetweenPoints < distance) then
                    local size = getMarkerSize(v)
                    if anim_type == "back" then
                        local progress = (getTickCount() - animTime) / 1500
                        position = math.floor(interpolateBetween(0, 0, 0, 200, 0, 0, progress, "InQuad"))
                        if (progress > 1) then
                            anim_type = "foward"
                            animTime = getTickCount()
                        end
                    else
                        local progress = (getTickCount() - animTime) / 1500
                        position = math.floor(interpolateBetween(200, 0, 0, 0, 0, 0, progress, "OutQuad"))
                        if (progress > 1) then
                            anim_type = "back"
                            animTime = getTickCount()
                        end
                    end

                    local arrowSizeWidth = 0.5
                    local arrowSizeHeight = 0.5
                    dxDrawMaterialLine3D(x, y, z + 2 + (position / 1000), x, y, z + 1 + (position / 1000) + arrowSizeHeight, arrow, arrowSizeWidth, tocolor(r, g, b, 200))

                    dxDrawMaterialLine3D(x + size, y + size, z + 0.04, x - size, y - size, z + 0.04, light, size * 3, tocolor(r, g, b, 155), x, y, z)
                end
            end
        end
    end
)






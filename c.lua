SW, SH = guiGetScreenSize()
local baseX = 3440
zoom = 1 
local minZoom = 2.2
if SW < baseX then
    zoom = math.min(minZoom, baseX/SW)
end

function isMouseInPosition ( x, y, width, height )
	if ( not isCursorShowing( ) ) then
		return false
	end
	local sx, sy = guiGetScreenSize ( )
	local cx, cy = getCursorPosition ( )
	local cx, cy = ( cx * sx ), ( cy * sy )
	
	return ( ( cx >= x and cx <= x + width ) and ( cy >= y and cy <= y + height ) )
end

elements = {
    font = dxCreateFont("font.otf", 22/zoom, false, "antialiased"),
    font2 = dxCreateFont("font.otf", 16/zoom, false, "antialiased"),
    font3 = dxCreateFont("font2.otf", 13/zoom, false, "antialiased"),
    font4 = dxCreateFont("font.otf", 18/zoom, false, "antialiased"),
    farms = {
        ["small"] = {-2.92251, -169.90071, 0, -5, -177, 1, 16, -166, 1, "Mała", "Mała (4 krowy)"},
        ["medium"] = {-388.06128, 721.77759, 26.53536, -430, 692, 23, -387, 724, 28, "Średnia", "Średnia (8 krów)"},
        ["large"] = {-1012.74829, -1057.85925, 129.21875, -1191, -1065, 131, -1004, -909, 131, "Duża", "Duża (25 krów)"},

    },
    scale = {},
    marker,
    interactionCallback,
    interactionCallbackOpen,
    exit,
    entry,
    active,
    cows = {},
    rnd_pos = {},
    blocked,
    milk,
    panel
}

elements.scale["bg"] = {SW/2 - (700/zoom)/2, SH/2 - (410/zoom)/2, 700/zoom, 410/zoom}
elements.scale["btn1"] = {elements.scale.bg[1] + 68/zoom, elements.scale.bg[2] + 196/zoom, 164/zoom, 164/zoom}
elements.scale["btn2"] = {elements.scale.btn1[1] + 36/zoom + elements.scale.btn1[3], elements.scale.btn1[2], 164/zoom, 164/zoom}
elements.scale["btn3"] = {elements.scale.btn2[1] + 36/zoom + elements.scale.btn2[3], elements.scale.btn2[2], 164/zoom, 164/zoom}

local maxDistance = 20
local minScale = 0.5
local maxScale = 1.0

function dxDrawRoundedRectangle(x, y, width, height, radius, color, postGUI, subPixelPositioning)
    dxDrawRectangle(x+radius, y+radius, width-(radius*2), height-(radius*2), color, postGUI, subPixelPositioning)
    dxDrawCircle(x+radius, y+radius, radius, 180, 270, color, color, 16, 1, postGUI)
    dxDrawCircle(x+radius, (y+height)-radius, radius, 90, 180, color, color, 16, 1, postGUI)
    dxDrawCircle((x+width)-radius, (y+height)-radius, radius, 0, 90, color, color, 16, 1, postGUI)
    dxDrawCircle((x+width)-radius, y+radius, radius, 270, 360, color, color, 16, 1, postGUI)
    dxDrawRectangle(x, y+radius, radius, height-(radius*2), color, postGUI, subPixelPositioning)
    dxDrawRectangle(x+radius, y+height-radius, width-(radius*2), radius, color, postGUI, subPixelPositioning)
    dxDrawRectangle(x+width-radius, y+radius, radius, height-(radius*2), color, postGUI, subPixelPositioning)
    dxDrawRectangle(x+radius, y, width-(radius*2), radius, color, postGUI, subPixelPositioning)
end

function drawInfo(text)
    if not isCursorShowing() then return end
    local width = dxGetTextWidth(text, 1, elements.font3, false)
	local textWidth, textHeight = dxGetTextSize(text, width, 1, elements.font3, false)
    local mouse = Vector2(getCursorPosition())
    local cursorX, cursorY = mouse.x * SW, mouse.y * SH
    dxDrawRoundedRectangle((cursorX + 17) - 10/zoom, (cursorY + 17) - 5/zoom, (width + 4) + 20/zoom, (5+textHeight) + 10/zoom, 10, tocolor(50, 50, 50, 255), true, false)
    --dxDrawRectangle(cursorX + 17, cursorY + 17, width + 4, 5+textHeight, tocolor(128, 128, 128, 150),true)
    dxDrawText(text, cursorX + 19.10, cursorY + 20.6, 0, 0, 0xFFE1E1E1, 1, elements.font3, "left", "top", false, false,true)
end

local function isValidPoint(points, newPoint, minDistance)
    for _, point in ipairs(points) do
        local distance = math.sqrt((newPoint.x - point.x)^2 + (newPoint.y - point.y)^2)
        if distance < minDistance then
            return false
        end
    end
    return true
end

local function generateRandomPositions(minX, maxX, minY, maxY, minDistance, maxAttempts)
    local points = {}
    local queue = {}

    local initialPoint = {
        x = math.random(minX, maxX),
        y = math.random(minY, maxY)
    }

    table.insert(points, initialPoint)
    table.insert(queue, initialPoint)

    while #queue > 0 and #points < maxAttempts do
        local currentPoint = table.remove(queue, math.random(#queue))
        for _ = 1, maxAttempts do
            local angle = math.random() * 2 * math.pi
            local distance = math.random() * minDistance + minDistance
            local newPoint = {
                x = currentPoint.x + distance * math.cos(angle),
                y = currentPoint.y + distance * math.sin(angle)
            }
            if newPoint.x >= minX and newPoint.x <= maxX and newPoint.y >= minY and newPoint.y <= maxY then
                local isValid = isValidPoint(points, newPoint, minDistance)
                if isValid then
                    table.insert(points, newPoint)
                    table.insert(queue, newPoint)
                    break
                end
            end
        end
    end

    return points
end


function renderPanel()
    dxDrawImage(elements.scale.bg[1], elements.scale.bg[2], elements.scale.bg[3], elements.scale.bg[4], "img/bg.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)

    if isMouseInPosition(elements.scale.btn1[1], elements.scale.btn1[2], elements.scale.btn1[3], elements.scale.btn1[4]) then
        dxDrawImage(elements.scale.btn1[1], elements.scale.btn1[2], elements.scale.btn1[3], elements.scale.btn1[4], "img/btn1_a.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
        drawInfo("W momencie rozpoczecia wywozu, całe mleko znajduje się w ciężarówce.\nWyjście z gry lub pojazdu oznacza utratę go.")
    else
        dxDrawImage(elements.scale.btn1[1], elements.scale.btn1[2], elements.scale.btn1[3], elements.scale.btn1[4], "img/btn1.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
    end


    if isMouseInPosition(elements.scale.btn2[1], elements.scale.btn2[2], elements.scale.btn2[3], elements.scale.btn2[4]) then
        dxDrawImage(elements.scale.btn2[1], elements.scale.btn2[2], elements.scale.btn2[3], elements.scale.btn2[4], "img/btn2_a.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
        drawInfo("Przez cały okres transportu wody nie możesz wysiąść z pojazdu.\nWyjście będzie oznaczało zakończenie transportu bez postępów.")
    else
        dxDrawImage(elements.scale.btn2[1], elements.scale.btn2[2], elements.scale.btn2[3], elements.scale.btn2[4], "img/btn2.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
    end

    if isMouseInPosition(elements.scale.btn3[1], elements.scale.btn3[2], elements.scale.btn3[3], elements.scale.btn3[4]) then
        dxDrawImage(elements.scale.btn3[1], elements.scale.btn3[2], elements.scale.btn3[3], elements.scale.btn3[4], "img/btn3_a.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
    else
        dxDrawImage(elements.scale.btn3[1], elements.scale.btn3[2], elements.scale.btn3[3], elements.scale.btn3[4], "img/btn3.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
    end
end

function click (button, state)
    if button == "left" and state == "down" then
        if isMouseInPosition(elements.scale.btn3[1], elements.scale.btn3[2], elements.scale.btn3[3], elements.scale.btn3[4]) then
            removeEventHandler("onClientRender", root, renderPanel)
            showCursor(false)
            removeEventHandler("onClientClick", root, click)
            elements.panel = null
        elseif isMouseInPosition(elements.scale.btn1[1], elements.scale.btn1[2], elements.scale.btn1[3], elements.scale.btn1[4]) then
            local data = elements.marker
            if data.milk <= 0 then
                outputChatBox("Twój zbiornik mleka jest pusty!", 255, 255, 255)
                return
            end
            if is_full_zbiornik then
                if data.milk < 100 then
                    outputChatBox("Zbiornik mleka musi być w 100% pełny, żebyś mógł wywieźć zawartość!", 255, 255, 255)
                    return
                end
            end
            
            for _,v in ipairs(getElementsByType("marker"))do
                if getElementData(v,"Farm:Data") then
                    local farm = getElementData(v,"Farm:Data")
                    if farm["id"] == elements.marker.id then
                        farm["milk"] = 0
                        setElementData(v,"Farm:Data", farm)
                    end
                end
            end

            setElementData(localPlayer,"Target:Data:Milk", elements.marker)
            triggerServerEvent("transMilk:Farm", resourceRoot, data.spawn, data.id)
            removeEventHandler("onClientRender", root, renderPanel)
            showCursor(false)
            removeEventHandler("onClientClick", root, click)
            elements.panel = null
            elements.milk = elements.marker.milk
            elements.marker = nil
            if elements.interactionCallback then
                unbindKey("q", "down", elements.interactionCallback)
            end
            if elements.interactionCallbackOpen then
                unbindKey("e", "down", elements.interactionCallbackOpen)
            end
            milk_target = createMarker(pos_milk_target[1], pos_milk_target[2], pos_milk_target[3], "cylinder", 3, 255, 255, 255, 50)
            blip_milk = createBlipAttachedTo(milk_target, 41, 2)
            addEventHandler("onClientMarkerHit", milk_target, function(el)
                if el ~= localPlayer then return end
                if el and getElementType(el) == "player" then
                    triggerServerEvent("destroyCar:Milk", resourceRoot, elements.milk)
                    if isElement(milk_target) then
                        destroyElement(milk_target)
                    end
                    if isElement(blip_milk) then
                        destroyElement(blip_milk)
                    end
                    elements.milk = null
                end
            end)
        elseif isMouseInPosition(elements.scale.btn2[1], elements.scale.btn2[2], elements.scale.btn2[3], elements.scale.btn2[4]) then
            if elements.marker.water >= 100 then
                outputChatBox("Zbiornik wody na farmie jest pełny w 100%!", 255, 255, 255)
                return
            end
            triggerServerEvent("transWater:Farm", resourceRoot, elements.marker.exit, elements.marker.spawn, elements.marker.id)
            target_water = createMarker(pos_water_target[1],pos_water_target[2],pos_water_target[3], "cylinder", 3, 255, 255, 255, 50)
            blip_water = createBlipAttachedTo(target_water, 41, 2)
            setElementData(localPlayer,"Target:Data:Water", elements.marker)
            removeEventHandler("onClientRender", root, renderPanel)
            showCursor(false)
            removeEventHandler("onClientClick", root, click)
            elements.panel = null
            elements.marker = nil
            if elements.interactionCallback then
                unbindKey("q", "down", elements.interactionCallback)
            end
            if elements.interactionCallbackOpen then
                unbindKey("e", "down", elements.interactionCallbackOpen)
            end
            addEventHandler("onClientMarkerHit", target_water, function(el)
                if el ~= localPlayer then return end
                if el and getElementType(el) == "player" then
                    if isElement(target_water) then
                        destroyElement(target_water)
                    end
                    if isElement(blip_water) then
                        destroyElement(blip_water)
                    end
                    local water_data = getElementData(el, "Target:Data:Water")
                    local pos = water_data.spawn
                    outputChatBox("Trwa uzupełnianie cysterny z wodą...", 255, 255, 255)
                    setElementFrozen(getPedOccupiedVehicle(el), true)
                    timer_water = setTimer(function(pos, el, water_data)
                        target_water = createMarker(pos[1],pos[2],pos[3], "cylinder", 3, 255, 255, 255, 50)
                        blip_water = createBlipAttachedTo(target_water, 41, 2)
                        setElementFrozen(getPedOccupiedVehicle(el), false)
                        outputChatBox("Woda pobrana, udaj się spowrotem na farmę, aby uzupełnić zbiorniki.", 255, 255, 255)
                        addEventHandler("onClientMarkerHit", target_water, function(el)
                            if el ~= localPlayer then return end
                            if el and getElementType(el) == "player" then
                                if isElement(target_water) then
                                    destroyElement(target_water)
                                end
                                if isElement(blip_water) then
                                    destroyElement(blip_water)
                                end
                                local water_data = getElementData(el, "Target:Data:Water")
                                outputChatBox("Woda uzupełniona!", 255, 255, 255)
                                for _,v in ipairs(getElementsByType("marker")) do
                                    if getElementData(v ,"Farm:Data") then
                                        if getElementData(v ,"Farm:Data")["id"] == water_data.id then
                                            local data_marker = getElementData(v ,"Farm:Data")
                                            data_marker["water"] = 100
                                            setElementData(v,"Farm:Data", data_marker)
                                        end
                                    end
                                end
                                triggerServerEvent("destroyCar:Water", resourceRoot)
                            end
                        end)
                    end, seconds_timer_water*1000, 1,pos, el, water_data)
                end
            end)
        end
    end
end

addEvent("removeTarget:Milk", true)
addEventHandler("removeTarget:Milk", resourceRoot, function()
    if isElement(milk_target) then
        destroyElement(milk_target)
    end
    if isElement(blip_milk) then
        destroyElement(blip_milk)
    end
end)

addEvent("removeTarget:Water", true)
addEventHandler("removeTarget:Water", resourceRoot, function()
    if isElement(target_water) then
        destroyElement(target_water)
    end
    if isElement(blip_water) then
        destroyElement(blip_water)
    end
    if isTimer(timer_water) then
        killTimer(timer_water)
    end
end)


addEventHandler("onClientRender", root, function()
    local x2, y2, z2 = getElementPosition(localPlayer)
    local cx, cy, cz = getCameraMatrix()
    local dim = getElementDimension(localPlayer)

    for _, v in ipairs(getElementsByType("marker")) do
        if getElementData(v, "Farm:Data") and getElementDimension(v) == dim then
            local x, y, z = getElementPosition(v)
            z = getGroundPosition(x, y, z) + 0.5
            local distance = getDistanceBetweenPoints3D(x2, y2, z2, x, y, z)
            
            if distance < 20 then
                if isLineOfSightClear(x, y, z, cx, cy, cz, false, true, false) then
                    local sx, sy = getScreenFromWorldPosition(x, y, z + 0.4)
                    
                    if sx and sy then
                        local data = getElementData(v, "Farm:Data")
                        local text = ""
                        
                        if isElementWithinMarker(localPlayer, v) then
                            if data["owned"] then
                                text = "Naciśnij Q, aby wejść\nNaciśnij E, aby wejść do Panelu Obsługi\n"
                            else
                                text = "Naciśnij Q, aby kupić\n"
                            end
                        end

                        local all = "#" .. data["id"] .. " " .. data["name"] .. "\n#999999" .. (data["owned"] and "\nFarma : #ffffff" .. data["count"] .. "#999999/" .. data["slots"] .. " krów [" .. (elements.farms[data["type"]][10]) .. "]\nZbiornik wody: " .. data["water"] .. "%\nZbiornik mleka: " .. data["milk"] .. "%\n\n#ffffff" or "\n[" .. (elements.farms[data["type"]][11]) .. "]\nDo zakupienia:  " .. data["price"] .. "$\n\n#ffffff") .. text

                        local _, lineCount = string.gsub(all, "\n", "\n")
                        local lineHeight = dxGetFontHeight(0.5, elements.font)
                        local textWidth, textHeight = dxGetTextWidth(all, 0.5, elements.font), lineHeight * (lineCount + 1)
                        
                        
                        local scale = (1 - (distance / maxDistance)) * (maxScale - minScale) + minScale

                        local imageWidth, imageHeight = textWidth * scale + 20, textHeight * scale + 20
                        imageWidth = math.max(300, imageWidth)

                        dxDrawImage(sx - imageWidth / 2, (sy - 15) - imageHeight / 2, imageWidth, imageHeight, "img/bg_draw.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
                        dxDrawText(all, sx, sy, sx, sy, tocolor(255, 255, 255, 255), 0.5 * scale, elements.font, "center", "center", false, false, false, true, false)
                    end
                end
            end
        end
    end
    for _,v in ipairs(getElementsByType("object")) do
		if getElementData(v,"Cow:Data") and getElementDimension(v) == dim then
			local x,y,z = getElementPosition(v)
			if getDistanceBetweenPoints3D(x2,y2,z2,x,y,z)<20 then
				if isLineOfSightClear(x,y,z,cx,cy,cz,false,true,false, false) then
					local sx,sy = getScreenFromWorldPosition(x,y,z+0.4)
					if sx and sy then
                        local text = ""
                        data = getElementData(v,"Cow:Data")
						dxDrawText("Krowa #-"..data["id"].."\n\nMleko: "..data["milk"].."%\nNaciśnij lewym przyciskiem myszy, aby wydoić.", sx, sy, sx, sy, tocolor(255, 255, 255, 255), 0.5, elements.font2, "center", "center", false, false, false, true, false)
					end
				end
			end
		end
	end
end)

addEvent("updateCow:Farm", true)
addEventHandler("updateCow:Farm", resourceRoot, function(milk, id)
    for _,v in ipairs(getElementsByType("object"))do
        if getElementData(v, "Cow:Data") then
            local data = getElementData(v, "Cow:Data")
            if data.id == id then
                data.milk = milk
                setElementData(v, "Cow:Data", data)
            end
        end
    end
end)

addEvent("import:Data:Farm", true)
addEventHandler("import:Data:Farm", resourceRoot, function(pos, data)
    local x, y, z = pos:match("([-0-9.]+),%s*([-0-9.]+),%s*([-0-9.]+)")
    local marker
    if data["owned"] then
        marker = createMarker(x,y,z, "cylinder", 1, 255, 255, 255, 0)
    else
        marker = createMarker(x,y,z, "cylinder", 1, 255, 0, 0, 0)
    end
    setElementData(marker,"Farm:Data", data)
end)

function buyNewFarm(el, id)
    if getPlayerMoney(localPlayer) >= elements.marker.price then
        triggerServerEvent("buyNew:Farm", resourceRoot, id, elements.marker.price)
        for _,v in ipairs(getElementsByType("marker"))do
            if getElementData(v,"Farm:Data") then
                local data = getElementData(v,"Farm:Data")
                if data.id == id then
                    data["owned"] = true
                    data["water"] = 0
                    data["milk"] = 0
                    setMarkerColor(v, 255, 255, 255, 0)
                    setElementData(v, "Farm:Data", data)
                    elements.marker = data
                end
            end
        end
    else
        outputChatBox("Nie posiadasz "..elements.marker.price.."$ na zakup tej farmy!", 255, 255, 255)
    end
end

function destroyCows()
    if #elements.cows > 0 then
        for _,v in ipairs(elements.cows) do
            destroyElement(v)
        end
        elements.cows = {}
    end
end




function enterFarm(el, id, count, typefarm)
    if el == localPlayer then
        fadeCamera(false)
        setElementFrozen(el, true)
        local x,y,z = elements.farms[elements.marker.type][1], elements.farms[elements.marker.type][2],elements.farms[elements.marker.type][3]
        if typefarm == "small" then
            elements.rnd_pos = generateRandomPositions(elements.farms[elements.marker.type][4], elements.farms[elements.marker.type][7], elements.farms[elements.marker.type][5], elements.farms[elements.marker.type][8], 3, 200)
        elseif typefarm == "medium" then
            elements.rnd_pos = generateRandomPositions(elements.farms[elements.marker.type][4], elements.farms[elements.marker.type][7], elements.farms[elements.marker.type][5], elements.farms[elements.marker.type][8], 10, 200)
        elseif typefarm == "large" then
            elements.rnd_pos = generateRandomPositions(elements.farms[elements.marker.type][4], elements.farms[elements.marker.type][7], elements.farms[elements.marker.type][5], elements.farms[elements.marker.type][8], 30, 200)
        end
        local rnd = math.random(3000,9999)
        local marker = createMarker(x,y,z, "cylinder", 1, 255, 255, 255, 50)
        setElementDimension(marker, rnd)
        addEventHandler("onClientMarkerHit", marker, function(el)
            if el == localPlayer then
                destroyCows()
                setElementFrozen(el, true)
                fadeCamera(false)
                tx, ty, tz = elements.entry[1], elements.entry[2], elements.entry[3]
                setTimer(function(el, tx, ty, tz)
                    triggerServerEvent("tpTo:Out", resourceRoot, tx, ty, tz)
                    setElementFrozen(el, false)
                end, 1000, 1, el, tx, ty, tz)
                setTimer(fadeCamera, 1500, 1, true)
                elements.active = null
            end
        end)
        setTimer(function(x,y,z, el, id, typefarm)
            triggerServerEvent("tpTo:Farm", resourceRoot, id, x, y, z, rnd, typefarm)
        end, 1000, 1, x, y+2, z, el, id, typefarm)
        
    end
end

addEvent("tpTo:Farm", true)
addEventHandler("tpTo:Farm", resourceRoot, function(cows_data, id, typefarm)
    if #cows_data > 0 then
        for num, position in ipairs(elements.rnd_pos) do
            if num <= #cows_data then
                if typefarm == "small" then
                    z = getGroundPosition(position.x, position.y, 3) + 0.9
                elseif typefarm == "medium" then
                    z = getGroundPosition(position.x, position.y, 29) + 0.8
                elseif typefarm == "large" then
                    z = getGroundPosition(position.x, position.y, 131) + 0.9
                end
                local rot = math.random(0,360)
                local obj = createObject(11470, position.x, position.y, z, 0, 0, rot)
                setElementCollisionsEnabled(obj, false)
                local temp = createObject(944, position.x, position.y, z, 0, 0, rot + 90)
                setElementAlpha(temp, 0)
                setObjectScale(obj, 0.3)
                setElementDimension(obj, getElementDimension(localPlayer))
                setElementDimension(temp, getElementDimension(localPlayer))
                table.insert(elements.cows, obj)
                table.insert(elements.cows, temp)
                setElementData(temp, "Cow:Data", {id = cows_data[num]["ID"], milk = cows_data[num]["Milk"], farm = id})
                z = null
            else
                break
            end
        end
    end
    elements.rnd_pos = {}
    elements.active = true
    setElementFrozen(localPlayer, false)
    setTimer(fadeCamera, 800, 1, true)
    elements.blocked = null
end)

function interactionFarm(el)
    if el == localPlayer then
        if elements.marker and not elements.blocked then
            if elements.marker.owned then
                enterFarm(el, elements.marker.id, elements.marker.count, elements.marker.type)
                elements.entry = elements.marker.exit
                elements.blocked = true
            else
                if not block then
                    block = true
                    buyNewFarm(el, elements.marker.id)
                    setTimer(function()
                        block = null
                    end, 1000, 1)
                end
            end
        end
    end
end

function openPanel(el)
    if el == localPlayer then
        if not elements.panel then
            if elements.marker.owned then
                showCursor(true)
                addEventHandler("onClientRender", root, renderPanel)
                addEventHandler("onClientClick", root, click)
                elements.panel = true
            end
        end
    end
end

addEventHandler("onClientMarkerHit", root, function(el)
    if el and getElementType(el) == "player" then
        if not getPedOccupiedVehicle(el) then
            local markerData = getElementData(source, "Farm:Data")
            if markerData then
                elements.marker = markerData
                elements.interactionCallback = function()
                    interactionFarm(el)
                end
                elements.interactionCallbackOpen = function()
                    openPanel(el)
                end
                bindKey("q", "down", elements.interactionCallback)
                bindKey("e", "down", elements.interactionCallbackOpen)
            end
        end
    end
end)

addEventHandler("onClientMarkerLeave", root, function(el)
    if el and getElementType(el) == "player" then
        if not getPedOccupiedVehicle(el) then
            local markerData = getElementData(source, "Farm:Data")
            if markerData then
                elements.marker = nil
                if elements.interactionCallback then
                    unbindKey("q", "down", elements.interactionCallback)
                end
                if elements.interactionCallbackOpen then
                    unbindKey("e", "down", elements.interactionCallbackOpen)
                end
            end
        end
    end
end)



function getPositionFromElementOffset(element,offX,offY,offZ) 
    local m = getElementMatrix ( element )
    local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]
    local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2] 
    local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3] 
    return x, y, z
end 

function findRotation(x1, y1, x2, y2)
    local t = -math.deg(math.atan2(x2 - x1, y2 - y1))
    return t < 0 and t + 360 or t
end

addEventHandler("onClientClick", root, function(b, s, _,_,_,_,_, element)
    if b == "left" and s == "down" then
        if elements.active and element and not elements.blocked then
            if getElementData(element,"Cow:Data") then
                local minus_milk = 0
                local plus_farm = 0
                local x,y,z = getElementPosition(element)
                local x2,y2,z2 = getElementPosition(localPlayer)
                if getDistanceBetweenPoints3D(x,y,z, x2, y2, z2) < 5 then
                    local data = getElementData(element,"Cow:Data")
                    if data.milk == 0 then
                        outputChatBox("Krowa #"..(data.id).." nie ma mleka!", 255, 255, 255)
                        return
                    end
                    local tx, ty, tz = getPositionFromElementOffset(element, 0, 2, 0)
                    local r = findRotation(tx, ty, x, y)
                    setElementFrozen(localPlayer, true)
                    setElementPosition(localPlayer, tx, ty, tz)
                    setElementRotation(localPlayer, 0, 0, r)
                    setPedAnimation(localPlayer, "BOMBER", "BOM_Plant")
                    outputChatBox("Dojenie krowy...", 255, 255, 255)
                    elements.blocked = true
                    setTimer(function(element, farm)
                        setElementPosition(localPlayer, x2,y2,z2)
                        setPedAnimation(localPlayer, false)
                        setElementFrozen(localPlayer, false)
                        elements.blocked = null
                        data = getElementData(element,"Cow:Data")
                        for _,v in ipairs(getElementsByType("marker"))do
                            if getElementData(v,"Farm:Data") then
                                if getElementData(v,"Farm:Data")["id"] == data["farm"] then
                                    local farm = getElementData(v,"Farm:Data")
                                    if farm["milk"] >= 100 then
                                        outputChatBox("Krowa nie została wydojona - w zbiorniku farmy brakuje miejsca!", 255, 255, 255)
                                    else
                                        if (farm["milk"] + (data["milk"]/4)) > 100 then
                                            local can = 100 - farm["milk"]
                                            farm["milk"] = farm["milk"] + can
                                            data["milk"] = (data["milk"]/4) - can
                                            setElementData(v, "Farm:Data", farm)
                                            setElementData(element,"Cow:Data", data)
                                            minus_milk = can
                                            plus_farm = can
                                            outputChatBox("Krowa nie została wydojona do końca - brakuje miejsca w zbiorniku farmy!", 255, 255, 255)
                                        else
                                            minus_milk = data["milk"]
                                            plus_farm = data["milk"]
                                            farm["milk"] = farm["milk"] + (data["milk"]/4)
                                            data["milk"] = 0
                                            setElementData(v, "Farm:Data", farm)
                                            outputChatBox("Krowa została wydojona, mleko trafiło do zbiornika farmy.", 255, 255, 255)
                                            setElementData(element,"Cow:Data", data)
                                        end     
                                    end
                                end
                            end
                        end
                        triggerServerEvent("dojenie:Farm", resourceRoot, data, minus_milk, plus_farm)
                        
                    end, 3500, 1, element, farm)
                else
                    outputChatBox("Podejdź bliżej krowy, jeśli chcesz ją wydoić!", 255, 255, 255)
                end
            end
        end
    end
end)


addEvent("updateFarm:GenerateMilk", true)
addEventHandler("updateFarm:GenerateMilk", resourceRoot, function(id, how_much_water, serial)
    for _,v in ipairs(getElementsByType("marker"))do
        if getElementData(v,"Farm:Data") then
            local data = getElementData(v,"Farm:Data")
            if data.id == id then
                data.water = data.water - how_much_water
                setElementData(v,"Farm:Data", data)
            end
        end
    end
end)

bindKey("f3", "down", function()
    showCursor(not isCursorShowing())
end)


















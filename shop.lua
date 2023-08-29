shop = {
    scale = {},
    elements = {},
    selected,
    offset = 0
}

shop.scale["bg"] = {SW/2 - (700/zoom)/2, SH/2 - (410/zoom)/2, 700/zoom, 410/zoom};
shop.scale["list"] = {shop.scale["bg"][1] + 71/zoom, shop.scale["bg"][2] + shop.scale["bg"][4] - 177/zoom, 351/zoom, 122/zoom};
shop.scale["buy"] = {shop.scale["bg"][1] + shop.scale["bg"][3] - 228/zoom, shop.scale["bg"][2] + shop.scale["bg"][4] - 204/zoom, 164/zoom, 164/zoom};
shop.scale["element"] = {shop.scale["list"][1] + 4/zoom, shop.scale["list"][2] + 4/zoom, 346/zoom, 29/zoom};
shop.scale["txt"] = {shop.scale["element"][1] + 7/zoom, shop.scale["element"][2] + 2/zoom, 332/zoom, 25/zoom};

function shopRender()
    if not shop.elements then return end
    dxDrawImage(shop.scale.bg[1], shop.scale.bg[2], shop.scale.bg[3], shop.scale.bg[4], "img/bg2.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
    dxDrawImage(shop.scale.list[1], shop.scale.list[2], shop.scale.list[3], shop.scale.list[4], "img/list.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
    if isMouseInPosition(shop.scale.buy[1], shop.scale.buy[2], shop.scale.buy[3], shop.scale.buy[4]) then
        dxDrawImage(shop.scale.buy[1], shop.scale.buy[2], shop.scale.buy[3], shop.scale.buy[4], "img/buy_a.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
        drawInfo("Kupując krowę zostaniesz przeniesiony do ciężarówki.\nJeśli wyjdziesz z gry podczas przewozu, krowa przepadnie bez zwrotu środków!")
    else
        dxDrawImage(shop.scale.buy[1], shop.scale.buy[2], shop.scale.buy[3], shop.scale.buy[4], "img/buy.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
    end
    local offset = 0
    for i = 1, #shop.elements do
        if i <= 4 then
            i = i + shop.offset
            if isMouseInPosition(shop.scale.element[1], shop.scale.element[2] + offset, shop.scale.element[3], shop.scale.element[4]) or shop.selected == i then
                dxDrawImage(shop.scale.element[1], shop.scale.element[2] + offset, shop.scale.element[3], shop.scale.element[4], "img/listelement_a.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
            else
                dxDrawImage(shop.scale.element[1], shop.scale.element[2] + offset, shop.scale.element[3], shop.scale.element[4], "img/listelement.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
            end
            dxDrawText("Farma : #"..shop["elements"][i]["ID"].." | Cena krowy : "..(shop["elements"][i]["Cow_Price"]).." $", shop.scale.txt[1], shop.scale.txt[2] + offset, shop.scale.txt[3] + shop.scale.txt[1], shop.scale.txt[4] + shop.scale.txt[2] + offset, tocolor(255, 255, 255, 255), 0.5, elements.font4, "center", "center", false, false, false, false, false)
            offset = offset + 35/zoom
        end
    end
end


function clickShop(button, state)
    if button == "left" and state == "down" then
        local offset = 0
        for i = 1, #shop.elements do
            i = i + shop.offset
            if isMouseInPosition(shop.scale.element[1], shop.scale.element[2] + offset, shop.scale.element[3], shop.scale.element[4]) then
                shop.selected = i
                break
            end
            offset = offset + 35/zoom
        end
        if isMouseInPosition(shop.scale.buy[1], shop.scale.buy[2], shop.scale.buy[3], shop.scale.buy[4]) then
            if not shop.selected then
                outputChatBox("Wybierz najpierw docelową farmę, do której chcesz dostarczyć krowę!", 255, 255, 255)
                return
            end
            local i = shop.selected + shop.offset
            triggerServerEvent("buyCow:Farm", localPlayer, shop.elements[i])
        end
    end
end 

addEvent("closeShop:Farm", true)
addEventHandler("closeShop:Farm", root, function(positions, id)
    if source == localPlayer then
        local x,y,z = positions:match("([-0-9.]+),%s*([-0-9.]+),%s*([-0-9.]+)")
        toggleControl("fire", true)
        showCursor(false)
        removeEventHandler("onClientRender", root, shopRender)
        removeEventHandler("onClientClick", root, clickShop)
        removeEventHandler("onClientKey", root, keyShop)
        toggleControl("fire", true)
        shop.elements = {}
        shop.offset = 0
        shop.selected = null
        target_cow = createMarker(x,y,z, "cylinder", 3, 255, 255, 255, 50)
        cow_blip = createBlipAttachedTo(target_cow, 41, 2)
        addEventHandler("onClientMarkerHit", target_cow, function(el)
            if el == localPlayer then
                if getElementType(el) == "player" then
                    if isElement(target_cow) then
                        destroyElement(target_cow)
                    end
                    if isElement(cow_blip) then
                        destroyElement(cow_blip)
                    end
                    triggerServerEvent("destroyCar:Cow", el, id)
                    for _,v in ipairs(getElementsByType("marker"))do
                        if getElementData(v,"Farm:Data") then
                            local data = getElementData(v,"Farm:Data")
                            if data.id == id then
                                data["count"] = data["count"] + 1
                                setElementData(v,"Farm:Data", data)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

addEvent("removeTarget:Cow", true)
addEventHandler("removeTarget:Cow", root, function()
    if source == localPlayer then
        if isElement(target_cow) then
            destroyElement(target_cow)
        end
        if isElement(cow_blip) then
            destroyElement(cow_blip)
        end
    end
end)

function keyShop(b, s)
    if b == "mouse_wheel_down" and s then
        if #shop.elements > 4 then
            if shop.offset < #shop.elements - 4 then
                shop.offset = shop.offset + 1
            end
        end
    elseif b == "mouse_wheel_up" and s then
        if shop.offset > 0 then
            shop.offset = shop.offset - 1
        end
    end
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    shop_marker = createMarker(shop_pos[1], shop_pos[2],shop_pos[3], "cylinder", 2, 255, 255, 255, 50)
    createBlipAttachedTo(shop_marker, 52, 2)
end)



addEventHandler("onClientMarkerHit", root, function(el)
    if source == shop_marker then
        if el and el == localPlayer then
            if getElementType(el) == "player" then
                if not getPedOccupiedVehicle(el) then
                    triggerServerEvent("openShop:Farm", el)
                end
            end
        end
    end
end)

addEvent("openShop:Farm", true)
addEventHandler("openShop:Farm", root, function(db)
    if source == localPlayer then
        shop.elements = db
        showCursor(true, false)
        addEventHandler("onClientRender", root, shopRender)
        addEventHandler("onClientClick", root, clickShop)
        addEventHandler("onClientKey", root, keyShop)
        toggleControl("fire", false)
    end
end)

addEventHandler("onClientMarkerLeave", root, function(el)
    if el and el == localPlayer then
        if getElementType(el) == "player" then
            if not getPedOccupiedVehicle(el) then
                showCursor(false)
                removeEventHandler("onClientRender", root, shopRender)
                removeEventHandler("onClientClick", root, clickShop)
                removeEventHandler("onClientKey", root, keyShop)
                toggleControl("fire", true)
                shop.elements = {}
                shop.offset = 0
                shop.selected = null
            end
        end
    end
end)
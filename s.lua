local db = dbConnect("sqlite", "db.db")

local vehs = {}
local trailers = {}
local obj = {}
local type_trans = {}


function init(element)
    if db then
        local q = dbQuery(db, "SELECT * FROM Farms")
        local w = dbPoll(q, -1)
        if #w > 0 then
            for _, v in ipairs(w) do
                local pos = v["Exit"]
                local spawn = v["Spawn"]
                local x, y, z = pos:match("([-0-9.]+),%s*([-0-9.]+),%s*([-0-9.]+)")
                local sx, sy, sz = spawn:match("([-0-9.]+),%s*([-0-9.]+),%s*([-0-9.]+)")
                local q2 = dbQuery(db, "SELECT * FROM Owners WHERE Serial = ? AND ID = ?", getPlayerSerial(element), v["ID"])
                local w2 = dbPoll(q2, -1)
                if #w2 == 0 then
                    data = {name = v["Name"], id = v["ID"], owned = false, price = v["Cena"], count = 0, slots = v["Slots"], type = v["Type"], exit = {x,y,z}, water = 0, milk = 0, spawn = {sx,sy,sz}}
                else
                    data = {name = v["Name"], id = v["ID"], owned = true, price = v["Cena"], count = w2[1]["Count"], slots = v["Slots"], type = v["Type"], exit = {x,y,z}, water = w2[1]["Water"], milk = w2[1]["Milk"], spawn = {sx,sy,sz}}
                end
                
                triggerClientEvent(element, "import:Data:Farm", resourceRoot, v["Pos"], data)
            end
        end
    end
end

addCommandHandler("init", function(plr)
    init(plr)
end)


addEvent("tpTo:Farm", true)
addEventHandler("tpTo:Farm", resourceRoot, function(id, x, y, z, dim, typefarm)
    if not isElement(client) then return end
    setElementPosition(client, x, y + 1, z+1)
    setElementDimension(client, tonumber(dim))
    
    local q = dbQuery(db, "SELECT * FROM Cows WHERE Farm = ? AND Serial = ?", id, getPlayerSerial(client))
    local w = dbPoll(q, -1)
    setTimer(function(client, w, id, typefarm)
        triggerClientEvent(client, "tpTo:Farm", resourceRoot, w, id, typefarm)
    end,600, 1,client, w, id, typefarm)
end)

addEvent("tpTo:Out", true)
addEventHandler("tpTo:Out", resourceRoot, function(x,y,z)
    if not isElement(client) then return end
    setElementPosition(client, x,y,z)
    setElementDimension(client, 0)
end)


addCommandHandler("tp", function(plr)
    setElementPosition(plr, -2412.71924, -608.77301, 132.59628)
    setElementDimension(plr, 0)
end)


addEvent("buyNew:Farm", true)
addEventHandler("buyNew:Farm", resourceRoot, function(id, price, cowprice)
    if not isElement(client) then return end
    takePlayerMoney(client, tonumber(price))
    local q = dbQuery(db, "SELECT * FROM Farms WHERE ID = ?", id)
    local w = dbPoll(q, -1)
    if #w > 0 then
        cowprice = w[1].Cash_Per_Cow
    else
        cowprice = cash_per_cow
    end
    dbExec(db,"INSERT INTO Owners (Serial, ID, Count, Water, Milk, Cow_Price) VALUES (?,?,0, 0, 0, ?)", getPlayerSerial(client), id, cowprice)
    outputChatBox("Zakup farmy #"..id.." przebiegł pomyślnie! Zacznij od uzupełnienia wody w zbiorniku.", client, 255, 255, 255)
end)


addEvent("dojenie:Farm", true)
addEventHandler("dojenie:Farm", resourceRoot, function(data, minus_milk, plus_farm)
    if not isElement(client) then return end
    if data then
        dbExec(db,"UPDATE Owners SET Milk = Milk + ? WHERE Serial = ? AND ID = ?", (plus_farm/4), getPlayerSerial(client), data.farm)
        dbExec(db,"UPDATE Cows SET Milk = Milk - ? WHERE ID = ?", minus_milk, data.id)
    end
end)

addEvent("transMilk:Farm", true)
addEventHandler("transMilk:Farm", resourceRoot, function(pos, id)
    if not isElement(client) then return end
    vehs[client] = createVehicle(515, pos[1], pos[2], pos[3] + 0.5)
    trailers[client] = createVehicle(584, 0, 0, 1)
    attachTrailerToVehicle(vehs[client], trailers[client])
    warpPedIntoVehicle(client, vehs[client])
    dbExec(db,"UPDATE Owners SET Milk = 0 WHERE ID = ? AND Serial = ?", id, getPlayerSerial(client))
    type_trans[client] = "milk"
end)

addEvent("transWater:Farm", true)
addEventHandler("transWater:Farm", resourceRoot, function(target, pos, id)
    if not isElement(client) then return end
    vehs[client] = createVehicle(515, pos[1], pos[2], pos[3] + 0.5)
    trailers[client] = createVehicle(584, 0, 0, 1)
    attachTrailerToVehicle(vehs[client], trailers[client])
    warpPedIntoVehicle(client, vehs[client])
    type_trans[client] = "water"
end)

addEventHandler("onVehicleStartExit", root, function(plr, seat)
    if vehs[plr] and vehs[plr] == source then
        if type_trans[plr] and type_trans[plr] == "milk" then
            if not getElementData(plr,"exit:Milk") then
                outputChatBox("Wyjście z ciężarówki zakończy wywóz, a Twoje mleko przepadnie! Czy na pewno chcesz wysiąść?", plr, 255, 255, 255)
                setElementData(plr,"exit:Milk", true)
                setTimer(setElementData, 2500, 1, plr, "exit:Milk", false)
                cancelEvent()
                return
            else
                if isElement(vehs[plr]) then
                    destroyElement(vehs[plr])
                end
                if isElement(trailers[plr]) then
                    destroyElement(trailers[plr])
                end
                removeElementData(plr,"exit:Milk")
                triggerClientEvent("removeTarget:Milk", plr)
                if tp_after_fail_milk then
                    local pos = getElementData(plr,"Target:Data:Milk").exit
                    if pos then
                        setTimer(function(pos, plr)
                            setElementPosition(plr, pos[1], pos[2], pos[3])
                        end, 700, 1, pos, plr)
                    end
                end
                removeElementData(plr,"Target:Data:Milk")
            end
        elseif type_trans[plr] and type_trans[plr] == "water" then
            if not getElementData(plr,"exit:Water") then
                outputChatBox("Wyjście z ciężarówki w trakcie transportu wody porzuci wszystkie postępy! Czy na pewno chcesz wysiąść?", plr, 255, 255, 255)
                setElementData(plr,"exit:Water", true)
                setTimer(setElementData, 2500, 1, plr, "exit:Water", false)
                cancelEvent()
                return
            else
                if isElement(vehs[plr]) then
                    destroyElement(vehs[plr])
                end
                if isElement(trailers[plr]) then
                    destroyElement(trailers[plr])
                end
                removeElementData(plr,"exit:Water")
                triggerClientEvent("removeTarget:Water", plr)
                if tp_after_fail_water then
                    local pos = getElementData(plr,"Target:Data:Water").exit
                    if pos then
                        setTimer(function(pos, plr)
                            setElementPosition(plr, pos[1], pos[2], pos[3])
                        end, 700, 1, pos, plr)
                    end
                end
                removeElementData(plr,"Target:Data:Water")
            end
        elseif type_trans[plr] and type_trans[plr] == "cow" then
            if not getElementData(plr,"exit:Cow") then
                outputChatBox("Wyjście z ciężarówki w trakcie transportu krowy porzuci wszystkie postępy! Czy na pewno chcesz wysiąść?", plr, 255, 255, 255)
                setElementData(plr,"exit:Cow", true)
                setTimer(setElementData, 2500, 1, plr, "exit:Cow", false)
                cancelEvent()
                return
            else
                if isElement(vehs[plr]) then
                    destroyElement(vehs[plr])
                end
                if isElement(obj[plr]) then
                    destroyElement(obj[plr])
                end
                removeElementData(plr,"exit:Cow")
                triggerClientEvent("removeTarget:Cow", plr)
                if tp_after_fail_cow then
                    local pos = shop_car_pos
                    if pos then
                        setTimer(function(pos, plr)
                            setElementPosition(plr, pos[1], pos[2], pos[3])
                        end, 700, 1, pos, plr)
                    end
                end
                removeElementData(plr,"Target:Data:Cow")
            end
        end
    end
end)

addEvent("destroyCar:Milk", true)
addEventHandler("destroyCar:Milk", resourceRoot, function(milk)
    if not isElement(client) then return end
    if isElement(vehs[client]) then
        destroyElement(vehs[client])
    end
    if isElement(trailers[client]) then
        destroyElement(trailers[client])
    end
    givePlayerMoney(client, tonumber(milk) * tonumber(cash_per_liter))
    outputChatBox("Wywóz mleka zakończony! Za "..milk.."/100% zbiornika otrzymujesz "..(tonumber(milk) * tonumber(cash_per_liter)).."$!", client, 255, 255, 255)
    if tp_after_milk then
        local pos = getElementData(client,"Target:Data:Milk").exit
        setTimer(function(client, pos)
            if pos then
                setElementPosition(client, pos[1], pos[2], pos[3])
            end
        end, 700, 1, client, pos)
    end
    removeElementData(client,"Target:Data:Milk")
end)

addEvent("destroyCar:Water", true)
addEventHandler("destroyCar:Water", resourceRoot, function()
    if not isElement(client) then return end
    if isElement(vehs[client]) then
        destroyElement(vehs[client])
    end
    if isElement(trailers[client]) then
        destroyElement(trailers[client])
    end
    local water_data = getElementData(client, "Target:Data:Water")
    dbExec(db,"UPDATE Owners SET Water = 100 WHERE ID = ? AND Serial = ?", water_data.id, getPlayerSerial(client))
    removeElementData(client,"Target:Data:Milk")
end)


addEventHandler("onTrailerDetach", root, function(veh)
    attachTrailerToVehicle(veh, source)
end)




local function fillCowMilk()
    local raport = {}
    local q = dbQuery(db, "SELECT * FROM Cows")
    local w = dbPoll(q, -1)
    if #w > 0 then
        for _,v in ipairs(w) do
            local f = dbQuery(db, "SELECT * FROM Owners WHERE Serial = ? AND ID = ?", v["Serial"], v["Farm"])
            local x = dbPoll(f, -1)
            if x[1]["Water"] > 0 then
                if x[1]["Water"] >= how_much_water then
                    if ( v["Milk"] + how_much_milk ) > 100 then
                        milk_set = 100
                        water_set = 0
                    else
                        milk_set = v["Milk"] + how_much_milk
                        water_set = how_much_water
                    end
                    dbExec(db,"UPDATE Cows SET Milk = ?, Fail = 0 WHERE ID = ?", milk_set, v["ID"])
                    dbExec(db,"UPDATE Owners SET Water = Water - ? WHERE ID = ? AND Serial = ?", water_set, v["Farm"], v["Serial"])
                    for _,p in ipairs(getElementsByType("player"))do
                        if getPlayerSerial(p) == v["Serial"] then
                            triggerClientEvent(p, "updateFarm:GenerateMilk", resourceRoot, v["Farm"], water_set, v["Serial"])
                        end
                    end
                else
                    dbExec(db,"UPDATE Cows SET Fail = Fail + 1 WHERE ID = ?", v["ID"])
                end
            else
                dbExec(db,"UPDATE Cows SET Fail = Fail + 1 WHERE ID = ?", v["ID"])
            end
        end
    end
end
setTimer(fillCowMilk, time_generate_milk * 1000, 0)



addEvent("openShop:Farm", true)
addEventHandler("openShop:Farm", resourceRoot, function()
    if not isElement(client) then return end
    local q = dbQuery(db, "SELECT * FROM Owners WHERE Serial = ?", getPlayerSerial(client))
    local w = dbPoll(q, -1)
    triggerClientEvent(client, "openShop:Farm", resourceRoot, w)
end)

addEvent("buyCow:Farm", true)
addEventHandler("buyCow:Farm", resourceRoot, function(data)
    if not isElement(client) then return end
    local q = dbQuery(db, "SELECT * FROM Farms WHERE ID = ?", data.ID)
    local w = dbPoll(q, -1)
    if #w > 0 then
        local x = dbQuery(db,"SELECT * FROM Owners WHERE ID = ? AND Serial =?", data.ID, getPlayerSerial(client))
        local d = dbPoll(x, -1)
        if (d[1].Count < w[1].Slots) then
            if getPlayerMoney(client) < data.Cow_Price then
                outputChatBox("Nie posiadasz "..(data.Cow_Price).." $ gotówki na zakup tej krowy!", client, 255, 255, 255)
                return
            end
            takePlayerMoney(client, data.Cow_Price)
            vehs[client] = createVehicle(455, shop_car_pos[1], shop_car_pos[2], shop_car_pos[3])
            type_trans[client] = "cow"
            setVehicleVariant(vehs[client], 255, 255)
            warpPedIntoVehicle(client, vehs[client])
            obj[client] = createObject(11470, shop_car_pos[1], shop_car_pos[2], shop_car_pos[3])
            setObjectScale(obj[client], 0.3)
            setElementCollisionsEnabled(obj[client], false)
            setTimer(function(client)
                attachElements(obj[client], vehs[client], 0, -2, 1)
            end, 600, 1, client)
            triggerClientEvent(client, "closeShop:Farm", resourceRoot, w[1].Spawn, data.ID)
        else
            outputChatBox("Ta farma jest pełna! Wybierz inną docelową farmę, do której chcesz dokupić krowę!", client, 255, 255, 255)
        end
    else
        outputChatBox("Wystąpił nieznany błąd - kod błędu : 9004. Zgłoś to administratorowi!", client, 255, 255, 255)
    end
end)


addEvent("destroyCar:Cow", true)
addEventHandler("destroyCar:Cow", resourceRoot, function(id)
    if not isElement(client) then return end
    if isElement(vehs[client]) then
        destroyElement(vehs[client])
    end
    if isElement(obj[client]) then
        destroyElement(obj[client])
    end
    outputChatBox("Dowiozłeś krowę pomyślnie! Jeśli woda w zbiorniku jest uzupełniona, natychmiast zacznie generować mleko.", client, 255, 255, 255)
    dbExec(db,"UPDATE Owners SET Count = Count + 1 WHERE ID = ? AND Serial = ?", id, getPlayerSerial(client))
    dbExec(db,"INSERT INTO Cows (ID, Serial, Milk, Farm, Fail) VALUES (?,?,0,?,0)", math.random(100000,999999), getPlayerSerial(client), id)
end)


addEventHandler("onPlayerQuit", root, function()
    if isElement(vehs[source]) then
        destroyElement(vehs[source])
    end
    if isElement(obj[source]) then
        destroyElement(obj[source])
    end
    if isElement(trailers[source]) then
        destroyElement(trailers[source])
    end
end)
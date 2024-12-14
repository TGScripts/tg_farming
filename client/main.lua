ESX = nil
ESX = exports["es_extended"]:getSharedObject()

local spawnedProps = {}

local function isAreaClear(coords, radius)
    for _, prop in ipairs(spawnedProps) do
        if DoesEntityExist(prop) then
            local propCoords = GetEntityCoords(prop)
            if #(coords - propCoords) < radius then
                return false
            end
        end
        Citizen.Wait(0)
    end
    return true
end

local function isJobAllowed(jobRestricted, allowedJobs)
    if not jobRestricted then return true end

    local playerData = ESX.GetPlayerData()
    local playerJob = playerData.job and playerData.job.name or ""

    for _, job in ipairs(allowedJobs) do
        if playerJob == job then
            return true
        end
        Citizen.Wait(0)
    end
    return false
end

local function spawnProps(gatherer)
    while #spawnedProps < gatherer.maxProps do
        local xOffset = math.random(-gatherer.areaRadius, gatherer.areaRadius)
        local yOffset = math.random(-gatherer.areaRadius, gatherer.areaRadius)

        local spawnCoords = vector3(gatherer.coords.x + xOffset, gatherer.coords.y + yOffset, gatherer.coords.z + 50.0)

        local foundGround, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z, true)

        if foundGround then
            local finalCoords = vector3(spawnCoords.x, spawnCoords.y, groundZ)

            if isAreaClear(finalCoords, gatherer.boundingRadius or 2.0, gatherer.props) then
                local propName = gatherer.props[math.random(#gatherer.props)]
                local prop = CreateObject(GetHashKey(propName), finalCoords.x, finalCoords.y, finalCoords.z, false, false, true)

                PlaceObjectOnGroundProperly(prop)

                local currentCoords = GetEntityCoords(prop)
                SetEntityCoordsNoOffset(prop, currentCoords.x, currentCoords.y, currentCoords.z + (gatherer.adjustPropHeight or 0), false, false, false)

                FreezeEntityPosition(prop, true)
                table.insert(spawnedProps, prop)
            end
        end
        Citizen.Wait(0)
    end
end

local function clearSpawnedProps()
    for _, prop in ipairs(spawnedProps) do
        if DoesEntityExist(prop) then
            DeleteObject(prop)
        end
    end
    spawnedProps = {}
end

local function drawHitboxAroundProp(prop)
    if Config.Debug then
        local propCoords = GetEntityCoords(prop)
        local min, max = GetModelDimensions(GetEntityModel(prop))
        
        local width = max.x - min.x
        local length = max.y - min.y
        local height = max.z - min.z

        DrawMarker(1, propCoords.x, propCoords.y, propCoords.z - 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, width, length, height, 255, 255, 255, 50, false, true, 2, false, false, false, false)
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        clearSpawnedProps()
    end
end)

Citizen.CreateThread(function()
    for _, gatherer in pairs(Config.Gatherers) do
        if gatherer.blip.show then
            local blip = AddBlipForCoord(gatherer.coords)
            SetBlipSprite(blip, gatherer.blip.sprite)
            SetBlipColour(blip, gatherer.blip.color)
            SetBlipScale(blip, gatherer.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(gatherer.blip.name)
            EndTextCommandSetBlipName(blip)
        end

        if Config.Debug then
            local debugBlip = AddBlipForRadius(gatherer.coords, gatherer.areaRadius)
            SetBlipColour(debugBlip, gatherer.blip.color)
            SetBlipAlpha(debugBlip, 128)
        end

        spawnProps(gatherer)

        Citizen.CreateThread(function()
            while true do
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)

                for i, prop in ipairs(spawnedProps) do
                    if DoesEntityExist(prop) then
                        local propCoords = GetEntityCoords(prop)
                        local distance = #(playerCoords - propCoords)

                        drawHitboxAroundProp(prop)

                        if distance < 2.0 then
                            ESX.ShowHelpNotification(tg_translate('help_notify'))

                            if IsControlJustReleased(0, 38) then
                                if isJobAllowed(gatherer.jobRestricted, gatherer.allowedJobs) then
                                    TaskStartScenarioInPlace(playerPed, gatherer.animation, 0, true)
                                    Citizen.Wait(gatherer.gatherTime * 1000)
                                    ClearPedTasks(playerPed)

                                    local item = gatherer.items[1]
                                    local quantity = math.random(item.min, item.max)
                                    TriggerServerEvent('tg_farming:collectItem', item.name, quantity)

                                    DeleteObject(prop)
                                    table.remove(spawnedProps, i)
                                    spawnProps(gatherer)
                                else
                                    tg_shownotification(tg_translate("job_restricted_gather"))
                                end
                            end
                        end
                    end
                end

                Citizen.Wait(0)
            end
        end)
    end
end)

Citizen.CreateThread(function()
    for _, processor in pairs(Config.Processors) do
        if processor.blip.show then
            local blip = AddBlipForCoord(processor.coords)
            SetBlipSprite(blip, processor.blip.sprite)
            SetBlipColour(blip, processor.blip.color)
            SetBlipScale(blip, processor.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(processor.blip.name)
            EndTextCommandSetBlipName(blip)
        end

        if processor.spawnNPC then
            RequestModel(GetHashKey(processor.npc.pedType))
            
            while not HasModelLoaded(GetHashKey(processor.npc.pedType)) do
                Citizen.Wait(0)
            end

            local npc = CreatePed(4, GetHashKey(processor.npc.pedType), processor.npc.coords, processor.npc.heading, false, true)
            SetModelAsNoLongerNeeded(GetHashKey(processor.npc.pedType))

            FreezeEntityPosition(npc, true)
            SetEntityInvincible(npc, true)
            TaskSetBlockingOfNonTemporaryEvents(npc, true)
        end

        if not HasAnimDictLoaded(processor.animation.dict) then
            RequestAnimDict(processor.animation.dict)
            while not HasAnimDictLoaded(processor.animation.dict) do
                Citizen.Wait(0)
            end
        end

        Citizen.CreateThread(function()
            while true do
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(playerCoords - processor.coords)

                if distance < 2.0 then
                    ESX.ShowHelpNotification(tg_translate('help_notify'))

                    if IsControlJustReleased(0, 38) then
                        if isJobAllowed(processor.jobRestricted, processor.allowedJobs) then
                            if not HasAnimDictLoaded(processor.animation.dict) then
                                print("^0[^1ERROR^0] [^2PROCESSING^0] Animation dictionary could not be loaded!")
                            end
                            
                            TaskPlayAnim(playerPed, processor.animation.dict, processor.animation.anim, 8.0, -8.0, processor.processingTime * 1000, 1, 0, false, false, false)

                            Citizen.Wait(processor.processingTime * 1000)
                            ClearPedTasks(playerPed)

                            TriggerServerEvent('tg_farming:processItem', processor.processing.input, processor.processing.output, processor.processing.input_rate, processor.processing.output_rate)
                        else
                            tg_shownotification(tg_translate("job_restricted_process"))
                        end
                    end
                end

                Citizen.Wait(0)
            end
        end)
    end
end)

local function openSellMenu(seller)
    ESX.TriggerServerCallback('tg_farming:getSellableItems', function(items)
        if #items > 0 then
            local elements = {}

            for _, item in pairs(items) do
                table.insert(elements, {
                    label = tg_translate("seller_menu_label", item.label or "[Unknown Item]", item.price, item.count),
                    value = item.name,
                    price = item.price,
                    count = item.count
                })
            end

            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'sell_menu', {
                title = tg_translate("seller_menu_title"),
                align = 'top-left',
                elements = elements
            }, function(data, menu)
                local selectedItem = data.current

                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'sell_menu_quantity', {
                    title = tg_translate("seller_menu_dialog")
                }, function(data2, menu2)
                    local quantity = tonumber(data2.value)

                    if quantity and quantity > 0 and quantity <= selectedItem.count then
                        menu2.close()
                        menu.close()

                        TriggerServerEvent('tg_farming:sellItem', selectedItem.value, quantity, selectedItem.price)

                        if not HasAnimDictLoaded(seller.animation.dict) then
                            print("^0[^1ERROR^0] [^2SELLER^0] Animation dictionary could not be loaded!")
                        end

                        local playerPed = PlayerPedId()
                        
                        TaskPlayAnim(playerPed, seller.animation.dict, seller.animation.anim, 8.0, -8.0, 1000, 1, 0, false, false, false)
                    else
                        tg_shownotification(tg_translate("seller_invalid_quantity"))
                    end
                end, function(data2, menu2)
                    menu2.close()
                end)

            end, function(data, menu)
                menu.close()
            end)
        else
            tg_shownotification(tg_translate('seller_no_items'))
        end
    end, seller.sellableItems)
end

Citizen.CreateThread(function()
    for _, seller in pairs(Config.Sellers) do
        if seller.blip.show then
            local blip = AddBlipForCoord(seller.coords)
            SetBlipSprite(blip, seller.blip.sprite)
            SetBlipColour(blip, seller.blip.color)
            SetBlipScale(blip, seller.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(seller.blip.name)
            EndTextCommandSetBlipName(blip)
        end

        if seller.spawnNPC then
            RequestModel(GetHashKey(seller.npc.pedType))
            
            while not HasModelLoaded(GetHashKey(seller.npc.pedType)) do
                Citizen.Wait(0)
            end

            local npc = CreatePed(4, GetHashKey(seller.npc.pedType), seller.npc.coords, seller.npc.heading, false, true)
            SetModelAsNoLongerNeeded(GetHashKey(seller.npc.pedType))

            FreezeEntityPosition(npc, true)
            SetEntityInvincible(npc, true)
            TaskSetBlockingOfNonTemporaryEvents(npc, true)
        end

        if not HasAnimDictLoaded(seller.animation.dict) then
            RequestAnimDict(seller.animation.dict)
            while not HasAnimDictLoaded(seller.animation.dict) do
                Citizen.Wait(0)
            end
        end

        Citizen.CreateThread(function()
            while true do
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(playerCoords - seller.coords)

                if distance < 2.0 then
                    ESX.ShowHelpNotification(tg_translate('help_notify'))

                    if IsControlJustReleased(0, 38) then
                        if isJobAllowed(seller.jobRestricted, seller.allowedJobs) then
                            openSellMenu(seller)
                        else
                            tg_shownotification(tg_translate("job_restricted_seller"))
                        end
                    end
                end

                Citizen.Wait(0)
            end
        end)

        Citizen.Wait(0)
    end
end)

RegisterNetEvent('tg_farming:tg_shownotification')
AddEventHandler('tg_farming:tg_shownotification', function(message)
    tg_shownotification(message)
end)

function tg_shownotification(message)
    local textureDict = "TG_Textures"
    RequestStreamedTextureDict(textureDict, true)

    while not HasStreamedTextureDictLoaded(textureDict) do
        Wait(0)
    end

    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostMessagetext(textureDict, "TG_Logo", false, 0, "TG Farming Script", "")

    SetStreamedTextureDictAsNoLongerNeeded(textureDict)
end
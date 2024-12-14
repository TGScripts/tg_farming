ESX = nil
ESX = exports["es_extended"]:getSharedObject()

ESX.RegisterServerCallback('tg_farming:getSellableItems', function(source, cb, items)
    local xPlayer = ESX.GetPlayerFromId(source)
    local sellableItems = {}

    for _, item in pairs(items) do
        local itemCount = xPlayer.getInventoryItem(item.name).count

        if itemCount > 0 then
            local itemLabel = item.label or item.name

            if itemLabel == item.name then
                print("^0[^1ERROR^0] [^2SELLER^0] No Label was found for ^4"..item.name.."^0, using name instead. (Triggered by ID: "..source..")")
            end

            table.insert(sellableItems, {
                name = item.name,
                label = itemLabel,
                count = itemCount,
                price = item.price
            })
        end
    end

    cb(sellableItems)
end)

RegisterServerEvent('tg_farming:sellItem')
AddEventHandler('tg_farming:sellItem', function(itemName, quantity, price)
    local xPlayer = ESX.GetPlayerFromId(source)
    local item = xPlayer.getInventoryItem(itemName)

    if item and item.count >= quantity then
        xPlayer.removeInventoryItem(itemName, quantity)
        local payment = quantity * price
        xPlayer.addMoney(payment)

        TriggerClientEvent('tg_farming:tg_shownotification', source, tg_translate("items_sold", quantity, (item.label or item.name), payment))

        if Config.Debug then
            print("[^3DEBUG^0] [^2SELLER^0] ^4ID "..source.."^0 sold ^4"..quantity.."x "..(item.label or item.name).."^0 for ^2"..payment.."$^0.")
        end
    else
        TriggerClientEvent('tg_farming:tg_shownotification', source, tg_translate('nei_seller'))
    end
end)

RegisterServerEvent('tg_farming:collectItem')
AddEventHandler('tg_farming:collectItem', function(itemName, quantity)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.addInventoryItem(itemName, quantity)
end)

RegisterServerEvent('tg_farming:processItem')
AddEventHandler('tg_farming:processItem', function(inputItem, outputItem, inputRate, outputRate)
    local xPlayer = ESX.GetPlayerFromId(source)
    local inputCount = xPlayer.getInventoryItem(inputItem).count

    if inputCount >= inputRate then
        xPlayer.removeInventoryItem(inputItem, inputRate)
        xPlayer.addInventoryItem(outputItem, outputRate)

        if Config.Debug then
            print("[^3DEBUG^0] [^2PROCESSING^0] ^4ID "..source.."^0 processed ^4"..inputRate.."x "..inputItem.."^0 into ^4"..outputRate.."x "..outputItem.."^0.")
        end
    else
        TriggerClientEvent('tg_farming:tg_shownotification', source, tg_translate('nei_processer'))
    end
end)
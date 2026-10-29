local githubRepo = 'msaber07/nova-vehicleinteract'

CreateThread(function()
    local localFile = LoadResourceFile(GetCurrentResourceName(), 'version.json')
    if not localFile then return end

    local localData = json.decode(localFile)
    if not localData or not localData.version then return end
    local currentVersion = localData.version

    PerformHttpRequest('https://raw.githubusercontent.com/' .. githubRepo .. '/main/version.json', function(statusCode, responseText)
        if statusCode == 200 and responseText then
            local data = json.decode(responseText)
            if data and data.version and data.version ~= currentVersion then
                print(('^3An update is available for %s (current version: %s)^7'):format(GetCurrentResourceName(), currentVersion))
                print(('^5https://github.com/%s/releases/tag/v%s^7'):format(githubRepo, data.version))
            end
        end
    end, 'GET', '', '')
end)

local neonProviders = {}

local function plateKey(plate)
    return (plate or ''):gsub('%s+', ''):upper()
end

local function storedNeon(plate)
    local key = plateKey(plate)
    if key == '' then return nil end
    local value = GetResourceKvpString('neonkit:' .. key)
    if value == '1' then return true end
    return nil
end

local function vehicleForPlayer(src, netId)
    netId = tonumber(netId)
    if not netId then return nil end
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    if GetVehiclePedIsIn(GetPlayerPed(src), false) ~= vehicle then return nil end
    return vehicle
end

local function neonPurchased(src, plate)
    for i = 1, #neonProviders do
        local ok, result = pcall(neonProviders[i].fn, src, plate)
        if ok and result == true then return true end
    end
    return storedNeon(plate) == true
end

exports('RegisterNeonProvider', function(fn)
    if type(fn) ~= 'function' then return false end
    neonProviders[#neonProviders + 1] = { fn = fn }
    return true
end)

exports('SetNeonInstalled', function(plate, installed)
    local key = plateKey(plate)
    if key == '' then return false end
    if installed then
        SetResourceKvp('neonkit:' .. key, '1')
    else
        DeleteResourceKvp('neonkit:' .. key)
    end
    return true
end)

exports('IsNeonInstalled', function(plate)
    return storedNeon(plate) == true
end)

RegisterNetEvent('nova-vehicleinteract:server:neonAccess', function(netId, requestId)
    local src = source
    local vehicle = vehicleForPlayer(src, netId)
    local allowed = false
    if vehicle then
        allowed = neonPurchased(src, GetVehicleNumberPlateText(vehicle))
    end
    TriggerClientEvent('nova-vehicleinteract:client:neonAccess', src, requestId, allowed)
end)

RegisterNetEvent('nova-vehicleinteract:server:neonToggle', function(netId, shouldEnable)
    local src = source
    local vehicle = vehicleForPlayer(src, netId)
    local allowed = false
    if vehicle then
        allowed = neonPurchased(src, GetVehicleNumberPlateText(vehicle))
    end
    TriggerClientEvent('nova-vehicleinteract:client:neonToggleResult', src, allowed and shouldEnable ~= nil)
end)

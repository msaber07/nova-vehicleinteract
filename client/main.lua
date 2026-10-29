local QBCore, ESX = nil, nil
local Framework = nil

local function attachFramework()
    if GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
    else
        QBCore, ESX, Framework = nil, nil, nil
    end
end

local menuOpen = false
local windowOverride = {}
local lastSnapshot = nil


local HOOD_DOOR = 4
local TRUNK_DOOR = 5

local L = Config.Locales[Config.Locale] or Config.Locales['en']

local DOOR_BONES = {
    [0] = 'door_dside_f',
    [1] = 'door_pside_f',
    [2] = 'door_dside_r',
    [3] = 'door_pside_r',
}

local WINDOW_BONES = {
    [0] = 'window_lf',
    [1] = 'window_rf',
    [2] = 'window_lr',
    [3] = 'window_rr',
}

-- When the menu is open, the player can continue driving but the mouse only goes to the menu.
-- (camera/view locked) and avoid accidentally triggering pause/fire
local DISABLED_CONTROLS = {
    1, 2, 106, -- camera view (LR/UD) + vehicle mouse steering override
    200, 199,            -- pause
    24, 25, 257, 263,    -- attack / aim / melee (yaya)
    140, 141, 142,       -- melee combat
    69, 70, 92, 114, -- vehicle weapon attacks
}

local function notify(message, notifyType)
    attachFramework()
    if Config.UseNovaUI and GetResourceState('nova-ui') == 'started' then
        exports['nova-ui']:Notify(message, notifyType)
        return
    end
    if (Config.Notify == 'ox' or Config.Notify == 'auto') and GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({ description = message, type = notifyType == 'primary' and 'inform' or (notifyType or 'inform') })
        return
    end
    if Framework == 'esx' and ESX then
        ESX.ShowNotification(message, notifyType or 'info')
    elseif Framework == 'qb' and QBCore and Config.Notify ~= 'ox' then
        QBCore.Functions.Notify(message, notifyType or 'primary')
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, false)
    end
end

local function isWindowDown(vehicle, index)
    local bag = windowOverride[vehicle]
    local entry = bag and bag[index]
    if entry and GetGameTimer() < entry.untilAt then
        return entry.down
    end
    return not IsVehicleWindowIntact(vehicle, index)
end

local function setWindowState(vehicle, index, down)
    windowOverride[vehicle] = windowOverride[vehicle] or {}
    windowOverride[vehicle][index] = { down = down and true or false, untilAt = GetGameTimer() + 800 }
end

local function ensureControl(vehicle)
    if NetworkHasControlOfEntity(vehicle) then return end
    NetworkRequestControlOfEntity(vehicle)
end

local function hasVehicleKey(vehicle)
    if not Config.RequireKeys then return true end
    local plate = (GetVehicleNumberPlateText(vehicle) or ''):gsub('%s+$', '')
    local found = false

    local function ask(resource, fn)
        if GetResourceState(resource) ~= 'started' then return false end
        found = true
        local ok, result = pcall(fn)
        return ok and result == true
    end

    if ask('nova-vehiclekeys', function() return exports['nova-vehiclekeys']:HasKeys(plate) end) then return true end
    if ask('qb-vehiclekeys', function() return exports['qb-vehiclekeys']:HasKeys(plate) end) then return true end
    if ask('qs-vehiclekeys', function() return exports['qs-vehiclekeys']:GetKey(plate) end) then return true end
    if ask('wasabi_carlock', function() return exports['wasabi_carlock']:HasKey(plate) end) then return true end
    if ask('Renewed-Vehiclekeys', function() return exports['Renewed-Vehiclekeys']:hasKey(plate) end) then return true end
    return not found
end

local function vehicleHasBone(vehicle, bone)
    return bone and GetEntityBoneIndexByName(vehicle, bone) ~= -1
end

local function getCurrentSeat(vehicle, ped)
    for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if GetPedInVehicleSeat(vehicle, i) == ped then
            return i
        end
    end
    return nil
end

local function vehicleHasDoor(vehicle, doorIndex)
    if doorIndex == HOOD_DOOR then
        return GetEntityBoneIndexByName(vehicle, 'bonnet') ~= -1
    elseif doorIndex == TRUNK_DOOR then
        return GetEntityBoneIndexByName(vehicle, 'boot') ~= -1
    end
    return true
end

local function isDoorOpen(vehicle, doorIndex)
    return GetVehicleDoorAngleRatio(vehicle, doorIndex) > 0.05
end

local function vehicleLabel(vehicle)
    local display = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local label = GetLabelText(display)
    if not label or label == '' or label == 'NULL' then
        return display
    end
    return label
end

local function buildMenuData(vehicle, overrides)
    overrides = overrides or {}
    local ped = PlayerPedId()
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
    local maxPassengerIndex = maxPassengers - 1

    -- Seats
    local seats = {}
    if Config.Features.seats then
        for i = -1, maxPassengerIndex do
            local pedInSeat = GetPedInVehicleSeat(vehicle, i)
            seats[#seats + 1] = {
                index = i,
                label = L.seatLabels[i] or ('#' .. tostring(i)),
                occupied = pedInSeat ~= 0,
                isMe = pedInSeat == ped,
            }
        end
    end

    -- Doors
    local doors = {}
    if Config.Features.doors then
        for i = 0, 3 do
            if vehicleHasBone(vehicle, DOOR_BONES[i]) then
                doors[#doors + 1] = {
                    index = i,
                    label = L.doorLabels[i] or ('#' .. tostring(i)),
                    open = isDoorOpen(vehicle, i),
                }
            end
        end
    end

    -- Windows
    local windows = {}
    if Config.Features.windows then
        for i = 0, 3 do
            if vehicleHasBone(vehicle, WINDOW_BONES[i]) then
                windows[#windows + 1] = {
                    index = i,
                    label = L.windowLabels[i] or ('#' .. tostring(i)),
                    down = isWindowDown(vehicle, i),
                }
            end
        end
    end

    -- Hood / Trunk
    local hood, trunk
    if Config.Features.hood and vehicleHasDoor(vehicle, HOOD_DOOR) then
        hood = { open = isDoorOpen(vehicle, HOOD_DOOR), label = L.ui.hood }
    end
    if Config.Features.trunk and vehicleHasDoor(vehicle, TRUNK_DOOR) then
        trunk = { open = isDoorOpen(vehicle, TRUNK_DOOR), label = L.ui.trunk }
    end

    -- Engine (show optimistic if player choice, don't wait for native startup delay)
    local engine
    if Config.Features.engine then
        local on = GetIsVehicleEngineRunning(vehicle)
        if overrides.engineOn ~= nil then on = overrides.engineOn end
        engine = { on = on }
    end

    -- Neon lights
    local neon
    if Config.Features.neon then
        local class = GetVehicleClass(vehicle)
        local canHaveNeon = class ~= 8 and class ~= 13 and class ~= 14 and class ~= 15 and class ~= 16 and class ~= 21
        if canHaveNeon then
            local neonOn = false
            for i = 0, 3 do
                if IsVehicleNeonLightEnabled(vehicle, i) then
                    neonOn = true
                    break
                end
            end
            neon = { on = neonOn }
        end
    end

    return {
        plate = GetVehicleNumberPlateText(vehicle),
        vehicleName = vehicleLabel(vehicle),
        seats = seats,
        doors = doors,
        windows = windows,
        hood = hood,
        trunk = trunk,
        engine = engine,
        neon = neon,
        locked = GetVehicleDoorLockStatus(vehicle) >= 2,
    }
end

local function startControlBlocker()
    CreateThread(function()
        while menuOpen do
            for i = 1, #DISABLED_CONTROLS do
                DisableControlAction(0, DISABLED_CONTROLS[i], true)
            end
            Wait(0)
        end
    end)
end

local function flag(value)
    return value and '1' or '0'
end

local function menuSignature(data)
    local parts = {
        data.plate or '',
        data.engine and flag(data.engine.on) or '-',
        data.neon and flag(data.neon.on) or '-',
        data.hood and flag(data.hood.open) or '-',
        data.trunk and flag(data.trunk.open) or '-',
    }
    if data.doors then
        for i = 1, #data.doors do
            parts[#parts + 1] = flag(data.doors[i].open)
        end
    end
    if data.windows then
        for i = 1, #data.windows do
            parts[#parts + 1] = flag(data.windows[i].down)
        end
    end
    if data.seats then
        for i = 1, #data.seats do
            local seat = data.seats[i]
            parts[#parts + 1] = seat.isMe and 'm' or (seat.occupied and 't' or 'e')
        end
    end
    return table.concat(parts)
end

local closeMenu

-- While the menu is open, the vehicle status can be changed externally (e.g. with W the engine turns on automatically).
-- Only refresh the UI when it actually changes, no unnecessary re-render/flicker.
local function startLiveSync()
    CreateThread(function()
        while menuOpen do
            Wait(400)
            if not menuOpen then break end
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle == 0 then
                closeMenu()
                break
            end
            local data = buildMenuData(vehicle)
            local snap = menuSignature(data)
            if snap ~= lastSnapshot then
                lastSnapshot = snap
                SendNUIMessage({ action = 'refresh', data = data })
            end
        end
    end)
end

local function openMenu()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        notify(L.notInVehicle, 'error')
        return
    end

    menuOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    startControlBlocker()
    local data = buildMenuData(vehicle)
    lastSnapshot = menuSignature(data)
    SendNUIMessage({ action = 'open', data = data, locale = L.ui })
    startLiveSync()
end

function closeMenu()
    menuOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })
end

local function refreshMenu(overrides)
    if not menuOpen then return end
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        closeMenu()
        return
    end
    local data = buildMenuData(vehicle, overrides)
    lastSnapshot = menuSignature(data)
    SendNUIMessage({ action = 'refresh', data = data })
end

local commandName = Config.Command or 'vehiclemenu'

RegisterCommand(commandName, function()
    if not menuOpen then
        openMenu()
    else
        closeMenu()
    end
end, false)

RegisterKeyMapping(commandName, L.keybind or 'Vehicle interaction menu', 'keyboard', Config.MenuKey)

-- Client exports so that other resources can trigger the menu
exports('OpenMenu', function()
    if not menuOpen then openMenu() end
end)

exports('CloseMenu', function()
    if menuOpen then closeMenu() end
end)

exports('ToggleMenu', function()
    if menuOpen then closeMenu() else openMenu() end
end)

exports('IsOpen', function()
    return menuOpen
end)

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb({ ok = true })
end)

RegisterNUICallback('switchSeat', function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local seat = tonumber(data and data.seat)

    if not Config.Features.seats or vehicle == 0 or seat == nil then
        cb({ ok = false })
        return
    end

    local maxSeat = GetVehicleMaxNumberOfPassengers(vehicle) - 1
    if seat < -1 or seat > maxSeat then
        cb({ ok = false })
        return
    end

    if not IsVehicleSeatFree(vehicle, seat) then
        notify(L.seatTaken, 'error')
        cb({ ok = false })
        refreshMenu()
        return
    end

    ensureControl(vehicle)
    TaskWarpPedIntoVehicle(ped, vehicle, seat)
    notify(L.seatSwitched, 'success')
    refreshMenu()
    cb({ ok = true })
end)

RegisterNUICallback('toggleDoor', function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local door = tonumber(data and data.door)
    local shouldOpen = data and data.open

    if not Config.Features.doors then
        cb({ ok = false })
        return
    end

    if vehicle == 0 or door == nil or door < 0 or door > 3 or not vehicleHasBone(vehicle, DOOR_BONES[door]) then
        cb({ ok = false })
        return
    end

    ensureControl(vehicle)
    if shouldOpen then
        SetVehicleDoorOpen(vehicle, door, false, false)
        notify(L.doorOpened, 'primary')
    else
        SetVehicleDoorShut(vehicle, door, false)
        notify(L.doorClosed, 'primary')
    end

    refreshMenu()
    cb({ ok = true })
end)

RegisterNUICallback('toggleWindow', function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local window = tonumber(data and data.window)
    local shouldRollDown = data and data.down

    if not Config.Features.windows then
        cb({ ok = false })
        return
    end

    if vehicle == 0 or window == nil or window < 0 or window > 3 or not vehicleHasBone(vehicle, WINDOW_BONES[window]) then
        cb({ ok = false })
        return
    end

    ensureControl(vehicle)
    if shouldRollDown then
        RollDownWindow(vehicle, window)
        setWindowState(vehicle, window, true)
        notify(L.windowDown, 'primary')
    else
        RollUpWindow(vehicle, window)
        setWindowState(vehicle, window, false)
        notify(L.windowUp, 'primary')
    end

    refreshMenu()
    cb({ ok = true })
end)

RegisterNUICallback('toggleHoodTrunk', function(data, cb)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local which = data and data.which
    local shouldOpen = data and data.open

    if not Config.Features.hood and which == 'hood' then
        cb({ ok = false })
        return
    end
    if not Config.Features.trunk and which == 'trunk' then
        cb({ ok = false })
        return
    end

    if vehicle == 0 or (which ~= 'hood' and which ~= 'trunk') then
        cb({ ok = false })
        return
    end

    local doorIndex = which == 'hood' and HOOD_DOOR or TRUNK_DOOR
    if not vehicleHasDoor(vehicle, doorIndex) then
        cb({ ok = false })
        return
    end

    ensureControl(vehicle)
    if shouldOpen then
        SetVehicleDoorOpen(vehicle, doorIndex, false, false)
        notify(which == 'hood' and L.hoodOpened or L.trunkOpened, 'primary')
    else
        SetVehicleDoorShut(vehicle, doorIndex, false)
        notify(which == 'hood' and L.hoodClosed or L.trunkClosed, 'primary')
    end

    refreshMenu()
    cb({ ok = true })
end)

RegisterNUICallback('toggleEngine', function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local shouldStart = data and data.on and true or false

    if not Config.Features.engine or vehicle == 0 then
        cb({ ok = false })
        return
    end

    if Config.EngineDriverOnly and getCurrentSeat(vehicle, ped) ~= -1 then
        notify(L.notDriver, 'error')
        cb({ ok = false })
        refreshMenu()
        return
    end

    if shouldStart and not hasVehicleKey(vehicle) then
        notify(L.noKeys, 'error')
        cb({ ok = false })
        refreshMenu()
        return
    end

    ensureControl(vehicle)
    SetVehicleEngineOn(vehicle, shouldStart, true, true)
    notify(shouldStart and L.engineOn or L.engineOff, shouldStart and 'success' or 'primary')

    refreshMenu({ engineOn = shouldStart })
    cb({ ok = true })
end)

RegisterNUICallback('toggleNeon', function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local shouldEnable = data and data.on and true or false

    if not Config.Features.neon or vehicle == 0 then
        cb({ ok = false })
        return
    end

    local class = GetVehicleClass(vehicle)
    if class == 8 or class == 13 or class == 14 or class == 15 or class == 16 or class == 21 then
        cb({ ok = false })
        return
    end

    ensureControl(vehicle)
    for i = 0, 3 do
        SetVehicleNeonLightEnabled(vehicle, i, shouldEnable)
    end
    
    notify(shouldEnable and L.neonOn or L.neonOff, 'primary')
    refreshMenu()
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if menuOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end)

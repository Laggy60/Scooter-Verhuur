local rentals = {}
local lastId = 0

local function notify(src, msg)
    TriggerClientEvent('esx:showNotification', src, msg)
end

local function log(src, event, msg, ...)
    lib.logger(src, event, msg:format(...))
end

local function findFreeSpawn()
    local vehicles = GetAllVehicles()

    for _, spawn in ipairs(Config.Location.spawns) do
        local free = true

        for _, veh in ipairs(vehicles) do
            if #(GetEntityCoords(veh) - spawn.xyz) < 2.5 then
                free = false
                break
            end
        end

        if free then
            return spawn
        end
    end
end

local function spawnScooter(spawn)
    local veh = CreateVehicleServerSetter(joaat(Config.Model), 'bike', spawn.x, spawn.y, spawn.z, spawn.w)

    local timeout = GetGameTimer() + 3000
    while not DoesEntityExist(veh) do
        if GetGameTimer() > timeout then
            return nil
        end
        Wait(0)
    end

    SetVehicleNumberPlateText(veh, Config.Plate)
    Entity(veh).state.fuel = 100.0

    return veh
end

local function endRental(src, reason)
    local rental = rentals[src]
    if not rental then return end

    rentals[src] = nil

    if rental.veh and DoesEntityExist(rental.veh) then
        local ped = GetPlayerPed(src)

        if ped ~= 0 and GetVehiclePedIsIn(ped, false) == rental.veh then
            TaskLeaveVehicle(ped, rental.veh, 0)
            Wait(1500)
        end

        DeleteEntity(rental.veh)
    end

    if reason then
        TriggerClientEvent('scooterverhuur:client:ended', src, reason)
    end
end

ESX.RegisterServerCallback('scooterverhuur:server:rent', function(source, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then
        return cb(false)
    end

    local rental = rentals[src]
    if rental then
        if rental.veh and not DoesEntityExist(rental.veh) then
            rentals[src] = nil
        else
            return cb(false, 'already_rented')
        end
    end

    local dist = #(GetEntityCoords(GetPlayerPed(src)) - Config.Location.coords)
    if dist > 10.0 then
        log(src, 'scooter:te_ver', '%s probeerde te huren op %.1fm afstand', xPlayer.getName(), dist)
        return cb(false, 'too_far')
    end

    local spawn = findFreeSpawn()
    if not spawn then
        return cb(false, 'spawn_blocked')
    end

    local account = xPlayer.getAccount(Config.Account)
    if not account or account.money < Config.Price then
        return cb(false, 'no_money')
    end

    lastId = lastId + 1
    local id = lastId
    rentals[src] = { id = id }

    xPlayer.removeAccountMoney(Config.Account, Config.Price, 'Scooter verhuur')

    local veh = spawnScooter(spawn)
    if not veh then
        rentals[src] = nil
        xPlayer.addAccountMoney(Config.Account, Config.Price, 'Scooter verhuur terugbetaling')
        log(src, 'scooter:spawn_mislukt', 'scooter kon niet gespawned worden voor %s, geld terug', xPlayer.getName())
        return cb(false, 'spawn_blocked')
    end

    if not rentals[src] then
        DeleteEntity(veh)
        return
    end

    rentals[src].veh = veh
    TaskWarpPedIntoVehicle(GetPlayerPed(src), veh, -1)

    notify(src, _L('paid', Config.Price))
    log(src, 'scooter:gehuurd', '%s huurt een scooter voor €%s', xPlayer.getName(), Config.Price)

    local rentMs = Config.RentTime * 60 * 1000

    if Config.RentTime * 60 > Config.WarnAt then
        SetTimeout(rentMs - Config.WarnAt * 1000, function()
            if rentals[src] and rentals[src].id == id then
                notify(src, _L('time_warning', Config.WarnAt))
            end
        end)
    end

    SetTimeout(rentMs, function()
        if rentals[src] and rentals[src].id == id then
            endRental(src, 'time_up')
            log(src, 'scooter:tijd_om', 'huurtijd van %s is voorbij', GetPlayerName(src))
        end
    end)

    cb(true)
end)

RegisterNetEvent('scooterverhuur:server:return', function()
    local src = source
    local rental = rentals[src]

    if not rental or not rental.veh then return end

    if not DoesEntityExist(rental.veh) then
        return endRental(src, 'returned')
    end

    local pedCoords = GetEntityCoords(GetPlayerPed(src))
    local vehCoords = GetEntityCoords(rental.veh)

    if #(pedCoords - Config.Location.coords) > 10.0 then
        return notify(src, _L('too_far'))
    end

    if #(vehCoords - Config.Location.coords) > 10.0 then
        return notify(src, _L('bring_scooter'))
    end

    endRental(src, 'returned')
    log(src, 'scooter:ingeleverd', '%s heeft de scooter ingeleverd', GetPlayerName(src))
end)

AddEventHandler('playerDropped', function()
    local src = source
    local rental = rentals[src]

    if rental and rental.veh and DoesEntityExist(rental.veh) then
        DeleteEntity(rental.veh)
    end

    rentals[src] = nil
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end

    for _, rental in pairs(rentals) do
        if rental.veh and DoesEntityExist(rental.veh) then
            DeleteEntity(rental.veh)
        end
    end
end)

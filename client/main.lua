local rentedVeh = nil
local busy = false
local rentId = 0

local function removeScooter()
    if not rentedVeh or not DoesEntityExist(rentedVeh) then
        rentedVeh = nil
        return
    end

    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) == rentedVeh then
        TaskLeaveVehicle(ped, rentedVeh, 0)
        Wait(1500)
    end

    ESX.Game.DeleteVehicle(rentedVeh)
    rentedVeh = nil
end

local function startTimer()
    local secondsLeft = Config.RentTime * 60
    local warned = false
    local myId = rentId

    CreateThread(function()
        while secondsLeft > 0 and rentedVeh and rentId == myId do
            Wait(1000)
            secondsLeft = secondsLeft - 1

            if not warned and secondsLeft <= Config.WarnAt then
                warned = true
                Notify(_L('time_warning', secondsLeft))
            end

            if rentedVeh and not DoesEntityExist(rentedVeh) then
                rentedVeh = nil
            end
        end

        if rentId ~= myId then return end

        removeScooter()
        Notify(_L('time_up'))
        TriggerServerEvent('scooterverhuur:server:done')
    end)
end

local function returnScooter()
    if busy then return end

    if DoesEntityExist(rentedVeh) and #(GetEntityCoords(rentedVeh) - Config.Location.coords) > 10.0 then
        Notify(_L('bring_scooter'))
        return
    end

    busy = true
    rentId = rentId + 1

    removeScooter()
    Notify(_L('returned'))
    TriggerServerEvent('scooterverhuur:server:done')

    busy = false
end

local function spawnScooter()
    local spawn = Config.Location.spawn

    if not ESX.Game.IsSpawnPointClear(vector3(spawn.x, spawn.y, spawn.z), 2.5) then
        Notify(_L('spawn_blocked'))
        return false
    end

    local p = promise.new()

    ESX.Game.SpawnVehicle(Config.Model, vector3(spawn.x, spawn.y, spawn.z), spawn.w, function(veh)
        SetVehicleNumberPlateText(veh, Config.Plate)
        SetVehicleFuelLevel(veh, 100.0)
        SetVehicleEngineOn(veh, true, true, false)

        Entity(veh).state.fuel = 100.0

        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        p:resolve(veh)
    end)

    rentedVeh = Citizen.Await(p)
    return true
end

local function tryRent()
    if busy then return end
    busy = true

    if rentedVeh then
        Notify(_L('already_rented'))
        busy = false
        return
    end

    local s = Config.Location.spawn
    if not ESX.Game.IsSpawnPointClear(vector3(s.x, s.y, s.z), 2.5) then
        Notify(_L('spawn_blocked'))
        busy = false
        return
    end

    ESX.TriggerServerCallback('scooterverhuur:server:rent', function(ok, reason)
        if not ok then
            Notify(_L(reason or 'no_money'))
            busy = false
            return
        end

        if spawnScooter() then
            Notify(_L('rented', Config.RentTime))
            startTimer()
        else
            TriggerServerEvent('scooterverhuur:server:refund')
        end

        busy = false
    end)
end

CreateThread(function()
    CreateRentBlip()

    local c = Config.Location.coords

    while true do
        local sleep = 1000
        local dist = #(GetEntityCoords(PlayerPedId()) - c)

        if dist < 15.0 then
            sleep = 0
            DrawMarker(37, c.x, c.y, c.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.8, 0.8, 0.8, 255, 200, 0, 150, false, true, 2, false, nil, nil, false)

            if rentedVeh then
                if dist < Config.ReturnDistance then
                    HelpText(_L('press_return'))

                    if IsControlJustReleased(0, 38) then
                        returnScooter()
                    end
                end
            elseif dist < Config.Distance then
                HelpText(_L('press_rent', Config.Price, Config.RentTime))

                if IsControlJustReleased(0, 38) then
                    tryRent()
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if rentedVeh and DoesEntityExist(rentedVeh) then
        DeleteEntity(rentedVeh)
    end
end)

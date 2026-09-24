local renting = false
local busy = false

local function tryRent()
    if busy then return end
    busy = true

    ESX.TriggerServerCallback('scooterverhuur:server:rent', function(ok, reason)
        busy = false

        if not ok then
            Notify(_L(reason or 'no_money'))
            return
        end

        renting = true
        Notify(_L('rented', Config.RentTime))
    end)
end

RegisterNetEvent('scooterverhuur:client:ended', function(reason)
    renting = false
    Notify(_L(reason))
end)

local point = lib.points.new({
    coords = Config.Location.coords,
    distance = 15.0,
})

function point:nearby()
    local c = self.coords

    DrawMarker(37, c.x, c.y, c.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.8, 0.8, 0.8, 255, 200, 0, 150, false, true, 2, false, nil, nil, false)

    if renting then
        if self.currentDistance < Config.ReturnDistance then
            HelpText(_L('press_return'))

            if IsControlJustReleased(0, 38) then
                TriggerServerEvent('scooterverhuur:server:return')
            end
        end
    elseif self.currentDistance < Config.Distance then
        HelpText(_L('press_rent', Config.Price, Config.RentTime))

        if IsControlJustReleased(0, 38) then
            tryRent()
        end
    end
end

CreateRentBlip()

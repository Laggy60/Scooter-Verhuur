local renting = {}
local pending = {}

ESX.RegisterServerCallback('scooterverhuur:server:rent', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        return cb(false)
    end

    if renting[source] and renting[source] > os.time() then
        return cb(false, 'already_rented')
    end

    local pedCoords = GetEntityCoords(GetPlayerPed(source))
    if #(pedCoords - Config.Location.coords) > 10.0 then
        print(('[scooterverhuur] %s (%s) probeerde te huren van te ver weg'):format(xPlayer.getName(), source))
        return cb(false, 'too_far')
    end

    local account = xPlayer.getAccount(Config.Account)
    if not account or account.money < Config.Price then
        return cb(false, 'no_money')
    end

    xPlayer.removeAccountMoney(Config.Account, Config.Price, 'Scooter verhuur')
    xPlayer.showNotification(_L('paid', Config.Price))

    renting[source] = os.time() + (Config.RentTime * 60)
    pending[source] = true

    cb(true)

    SetTimeout(10000, function()
        pending[source] = nil
    end)
end)

RegisterNetEvent('scooterverhuur:server:refund', function()
    local src = source
    if not pending[src] then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        xPlayer.addAccountMoney(Config.Account, Config.Price, 'Scooter verhuur refund')
    end

    pending[src] = nil
    renting[src] = nil
end)

RegisterNetEvent('scooterverhuur:server:done', function()
    renting[source] = nil
end)

AddEventHandler('playerDropped', function()
    renting[source] = nil
    pending[source] = nil
end)

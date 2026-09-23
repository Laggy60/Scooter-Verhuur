function Notify(msg)
    ESX.ShowNotification(msg)
end

function HelpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

function CreateRentBlip()
    local c = Config.Location.coords
    local blip = AddBlipForCoord(c.x, c.y, c.z)

    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.Blip.name)
    EndTextCommandSetBlipName(blip)
end

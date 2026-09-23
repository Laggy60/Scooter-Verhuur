Locale = {
    ['press_rent']     = '~INPUT_CONTEXT~ Scooter huren (~g~€%s~s~ voor %s min)',
    ['press_return']   = '~INPUT_CONTEXT~ Scooter inleveren',
    ['rented']         = 'Je hebt een scooter gehuurd voor %s minuten. Rij voorzichtig!',
    ['no_money']       = 'Je hebt niet genoeg geld op je bank.',
    ['already_rented'] = 'Je hebt al een scooter gehuurd.',
    ['too_far']        = 'Je staat te ver weg.',
    ['spawn_blocked']  = 'Er staat iets in de weg, probeer het zo nog eens.',
    ['time_warning']   = 'Je huurtijd is bijna om, nog %s seconden.',
    ['time_up']        = 'Je huurtijd is voorbij, de scooter is teruggebracht.',
    ['returned']       = 'Bedankt! Je scooter is ingeleverd.',
    ['bring_scooter']  = 'Neem de scooter mee naar het inleverpunt.',
    ['paid']           = 'Er is €%s van je bankrekening afgeschreven.',
}

function _L(key, ...)
    local str = Locale[key]
    if not str then
        return ('missing locale: %s'):format(key)
    end
    return str:format(...)
end

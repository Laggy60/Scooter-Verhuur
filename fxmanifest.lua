fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Scooter verhuur - huur een scooter voor een paar minuutjes'
version '1.0.2'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
    'locales/nl.lua'
}

client_scripts {
    'client/utils.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

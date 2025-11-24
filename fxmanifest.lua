fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Claude Code'
description 'Système de drogues complet ESX avec plantation, croissance, traitement et conditionnement'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/dui.lua',
    'client/processing.lua',
    'client/items.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/growth.lua',
    'server/processing.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'oxmysql'
}

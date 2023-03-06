fx_version 'cerulean'
games { 'gta5' }
description 'multijob (unlimited jobs) script for esx fw'
author 'maku#5434'

client_scripts {
    'client/cl_main.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/sv_main.lua'
}

fx_version 'cerulean'
game 'gta5'
description 'multijob (unlimited jobs) script for esx fw'
author 'maku#5434'
repository 'https://github.com/itIsMaku/maku_multijob'

client_scripts {
    'client/cl-*.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/sv-*.lua'
}

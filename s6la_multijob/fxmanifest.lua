fx_version 'cerulean'
game 'gta5'
shared_script '@WaveShield/resource/include.lua'
shared_script '@WaveShield/resource/waveshield.js'

author 'templ8scripts'
description 'advanced FREE esx & qb multijob script.'
github 'github.com/templ8scripts/s6la_multijob/'

shared_scripts {
    'shared/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'core/server/main.lua'
}

client_scripts {
    'core/client/main.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/app.js'
}

dependency 'oxmysql'


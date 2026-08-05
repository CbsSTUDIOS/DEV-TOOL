fx_version 'cerulean'
game 'gta5'

version '1.0.1'

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**/*',
}

client_scripts {
    'client/client.lua',}

server_scripts {
    'server/server.lua', 'versionchecker.lua',}

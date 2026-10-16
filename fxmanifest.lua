shared_script '@avappearancee2a691fa/init.lua'
fx_version 'cerulean'
game 'gta5'

name        'Vehicle Lock System'
description 'Owner lock/unlock and lockpick system using ox_lib and ox_target.'
version     '1.0.0'
author      'Zeph'

-- ox_lib must be loaded first (shared, provides the `lib` global)
shared_scripts {
    '@ox_lib/init.lua',   -- Required: loads ox_lib into this resource
    'config.lua',         -- Your tunable settings
}

-- Client-side scripts
client_scripts {
    'client/client.lua',
}

-- Server-side scripts
server_scripts {
    'server/server.lua',
}

-- lua54 'yes' enables modern Lua 5.4 features (recommended)
lua54 'yes'

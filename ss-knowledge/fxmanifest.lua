fx_version 'cerulean'
game 'gta5'

author 'Sky\'s Scripts'
description 'Multi use knowledge/rep/xp resource'

version '1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'language.lua',
	'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
	'server/main.lua',
	'bridge/server/framework.lua',
	'bridge/server/utilities.lua',
}

client_scripts {
	'client/main.lua',
	'client/gui.lua',
	'client/functions.lua',
	'bridge/client/framework.lua',
	'bridge/client/utilities.lua',
}

escrow_ignore {
	'client/main.lua',
	'client/gui.lua',
	'client/functions.lua',
	'server/main.lua',
	'language.lua',
	'config.lua',
	'bridge/client/framework.lua',
	'bridge/client/utilities.lua',
	'bridge/server/framework.lua',
	'bridge/server/utilities.lua',
}

lua54 'yes'
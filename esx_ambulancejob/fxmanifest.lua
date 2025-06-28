fx_version 'adamant'

game 'gta5'

description 'ESX Ambulance Job'

lua54 'yes'

version '2.5.0'

shared_scripts{
	'@es_extended/imports.lua',
	'@es_extended/locale.lua',
	'@ox_lib/init.lua',
	'config.lua',
	'locales/en.lua',
}

client_scripts {
	'client/main.lua',
	'client/job.lua',
	'client/laststand.lua',
	'client/dead.lua',
	'client/objects.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'locales/en.lua',
	'server/main.lua'
}

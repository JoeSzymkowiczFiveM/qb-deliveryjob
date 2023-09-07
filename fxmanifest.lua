fx_version 'cerulean'
game 'gta5'

lua54 'yes'

client_scripts {
    --'@salty_tokenizer/init.lua',
	'config.lua',
    'client/main.lua',
}

server_scripts {
    --'@salty_tokenizer/init.lua',
    'config.lua',
	'server/main.lua'
}

shared_scripts {
	'@ox_lib/init.lua'
}
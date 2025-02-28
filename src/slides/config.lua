if false then -- local testing
    return {
        enable_imgur = false, -- if you wish to enable imgur, you must provide a file called `api_key.lua` with the following code: `return <CLIENTID>`
        question_input_pos = {x=-449, y=67, z=398},
        remote_control_channel = 16459,
        logo = {url="https://blanketcon.b-cdn.net/pub/23/8219_logo.png", width=1080, height=379},
        monitors = {
            display = 1,
            backstage_a = 2,
            backstage_b = 3,
            backstage_c = 4,

            album_art = 13,
            now_playing = 14
        },
        enable_commands = false,
        command_secret = "totally_secret", -- DO NOT LEAK THIS, used for verifying commands
        --  (obviously this should be changed when put into production use, and if you're here
        --   from the CTF video, it was changed on BC23)
        spindle_discs_pos = {x=-449, y=72, z=393},
        jukebox_pos = {x=-456, y=68, z=393},
        include_hardcoded_songs = false
    }
else
    return {
        enable_imgur = false, -- if you wish to enable imgur, you must provide a file called `api_key.lua` with the following code: `return <CLIENTID>`
        question_input_pos = {x=-449, y=67, z=398},
        remote_control_channel = 16459,
        logo = {url="https://blanketcon.b-cdn.net/pub/23/8219_logo.png", width=1080, height=379},
        monitors = {
            display = 20,
            backstage_a = 16, --left
            backstage_b = 17, --right
            backstage_c = 15, --back

            album_art = 13,
            now_playing = 14
        },
        enable_commands = false,
        command_secret = "totally_secret", -- DO NOT LEAK THIS, used for verifying commands
        --  (obviously this should be changed when put into production use, and if you're here
        --   from the CTF video, it was changed on BC23)
        spindle_discs_pos = {x=-449, y=72, z=393},
        jukebox_input_pos = {x=-456, y=68, z=393},
        include_hardcoded_songs = false
    }
end

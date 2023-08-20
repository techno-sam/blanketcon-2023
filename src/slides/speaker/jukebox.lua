local config = require "/config"

local sounds = {
    {
        name   = "Joy of Remembrance",
        artist = "Lena Raine",
        art    = "art/celeste.lua",
        url    = "https://squiddev.cc/r/sound/rememberance.dfpwm",
    },
    {
        name   = "Yoshiwara Lament",
        artist = "Tokyo Philharmonic",
        art    = "art/miku.lua",
        url    = "https://squiddev.cc/r/sound/lament.dfpwm",
    },
    {
        name   = "Soliloquy [Remake]",
        artist = "Alcaknight",
        art    = "art/alcaknight.lua",
        url    = "https://squiddev.cc/r/sound/example.dfpwm",
    },
    {
        name   = "Akari Has Arrived!",
        artist = "GYARI",
        art    = "art/snapshot.lua",
        url    = "https://squiddev.cc/r/sound/snapshot.dfpwm",
    },
    {
        name   = "Seize the Day",
        artist = "Asaka",
        art    = "art/yuru.lua",
        url    = "https://squiddev.cc/r/sound/yuru.dfpwm",
    },
    {
        name   = "Diggy Diggy Hole",
        artist = "WIND ROSE",
        art    = "art/diggy.lua",
        url    = "https://squiddev.cc/r/sound/diggy.dfpwm",
    },
    {
        name   = "Agape",
        artist = "Melocure + Ayasa",
        art    = "art/valkyrie.lua",
        url    = "https://squiddev.cc/r/sound/valkyrie.dfpwm",
    },
    {
        name   = "Sakuramochi",
        artist = "Shibayan Records",
        art    = "art/bossa-nova-4.lua",
        url    = "https://squiddev.cc/r/sound/sakuramochi.dfpwm",
    },
    {
        name   = "I Was The Sun",
        artist = "Curtis Schweitzer",
        art    = "art/starbound.lua",
        url    = "https://squiddev.cc/r/sound/the-sun.dfpwm",
    },
    {
        name   = "The Theme of Sachio",
        artist = "Mabanua",
        art    = "art/megalo.lua",
        url    = "https://squiddev.cc/r/sound/megalo-sachio.dfpwm",
    },
}

if ... == "viewer" then
    local i = 1
    local arts = {}
    for i = 1, #sounds do arts[i] = dofile(sounds[i].art).draw end
    while true do
        term.setCursorPos(1, 1)
        arts[i](term)

        local _, key = os.pullEvent("key")
        if key == keys.right then i = (i % #arts) + 1
        elseif key == keys.left then i = ((i - 2) % #arts) + 1
        end
    end
end

local album_art = peripheral.wrap("monitor_"..config.monitors.album_art)
local now_playing = peripheral.wrap("monitor_"..config.monitors.now_playing)
local speaker = peripheral.wrap("speaker_"..config.speakers.a)
local speaker2 = peripheral.wrap("speaker_"..config.speakers.b)

if speaker == nil and speaker2 == nil then
    speaker = peripheral.find("speaker")
end

album_art.setTextScale(0.5)

now_playing.setTextScale(1)
now_playing.setBackgroundColour(colours.white)

while true do
    -- Lazy shuffle here so we don't play the same songs in order.
    local last = sounds[#sounds]
    repeat
        for i = #sounds - 1, 2, -1 do
            local j = math.random(i)
            sounds[i], sounds[j] = sounds[j], sounds[i]
        end
    until sounds[1] ~= last or #sounds == 1

    for _, sound in pairs(sounds) do
        print("Playing " .. sound.name)

        -- Display now playing
        now_playing.clear()
        now_playing.setCursorPos(1, 2)
        now_playing.setTextColour(colours.black)
        now_playing.write("Now playing:")
        now_playing.setCursorPos(1, 3)
        now_playing.setTextColour(colours.red)
        now_playing.write(sound.name)
        now_playing.setCursorPos(1, 4)
        now_playing.setTextColour(colours.cyan)
        now_playing.write(sound.artist)

        album_art.setCursorPos(1, 1)
        local old_set_palette_color = album_art.setPaletteColor
        album_art.setPaletteColor = function(c, packed)
            local r, g, b = colors.unpackRGB(packed)
            old_set_palette_color(c, r, g, b)
        end
        dofile("speaker/"..sound.art).draw(album_art)

        local handle, err = http.get { url = sound.url, binary = true }
        if not handle then
            printError(err)
        else
            local decoder = require "cc.audio.dfpwm".make_decoder()
            while true do
                local chunk = handle.read(16 * 1024)
                if not chunk then break end

                local buffer = decoder(chunk)
                local function make_player(speak)
                    return function()
                        while not speak.playAudio(buffer, sound.volume or 2) do
                            os.pullEvent("speaker_audio_empty")
                        end
                    end
                end
                if speaker ~= nil and speaker2 ~= nil then
                    parallel.waitForAny(make_player(speaker), make_player(speaker2))
                elseif speaker ~= nil then
                    make_player(speaker)()
                elseif speaker2 ~= nil then
                    make_player(speaker2)()
                else
                    sleep(0.05)
                end
            end
        end

        local deadline = os.epoch("utc") + 10 * 1000
        repeat sleep(1) until os.epoch("utc") >= deadline
    end
end

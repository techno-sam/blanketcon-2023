local config = require "/config"

--[[local sounds = {
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
}--]]

local sounds = {
    {
        name = "Pigstep",
        artist = "Lena Raine",
        art = {id="minecraft:music_disc_pigstep", Count=1}, -- placeholder
        sound_event = "music_disc.pigstep", -- https://minecraft.fandom.com/wiki/Sounds.json#Sound_events
        duration = (2*60 + 28)*20 -- https://minecraft.fandom.com/wiki/Music_Disc#Discs
    },
    {
        name = "Otherside",
        artist = "Lena Raine",
        art = {id="minecraft:music_disc_otherside", Count=1},
        sound_event = "music_disc.otherside", -- https://minecraft.fandom.com/wiki/Sounds.json#Sound_events
        duration = (3*60 + 15)*20 -- https://minecraft.fandom.com/wiki/Music_Disc#Discs
    },
    {
        name = "Papillons",
        artist = "xyce & malmen",
        art = {id="yttr:music_disc_papillons", Count=1}, -- /data modify entity @e[tag=stage_disc_display,limit=1] item set value {id:"minecraft:music_disc_pigstep", Count:1b}
        sound_event = "yttr:papillons",
        duration = (3*60 + 39)*20
    }
}

-- get sounds from disc chest
local x, y, z = config.spindle_discs_pos.x, config.spindle_discs_pos.y, config.spindle_discs_pos.z
local info = commands.getBlockInfo(x, y, z)
for slot, item in pairs(info.nbt.Items) do
    if item.id == "spindlemark:disc" and item.tag and item.tag.SongLength and item.tag.Description and item.tag.CustomMusicDiscSound then
        local song = {
            name = item.tag.Description,
            artist = "",
            art = item,
            sound_event = item.tag.CustomMusicDiscSound,
            duration = tonumber(item.tag.SongLength)
        }
        local dash_idx, _ = string.find(item.tag.Description, '-')
        if dash_idx then
            song.artist = string.sub(item.tag.Description, 1, dash_idx-2)
            song.name = string.sub(item.tag.Description, dash_idx+2)
        end
        sounds[#sounds+1] = song
    end
end

--[[
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
end--]]

local album_art = peripheral.wrap("monitor_"..config.monitors.album_art)
local now_playing = peripheral.wrap("monitor_"..config.monitors.now_playing)
--local speakers = {peripheral.find("speaker")}

--print("Found "..#speakers.." speakers")

album_art.setTextScale(0.5)

now_playing.setTextScale(1)
now_playing.setBackgroundColour(colours.white)

local function to_json(tbl)
    return ("%q"):format(textutils.serializeJSON(tbl))
end

print("Delay to ensure jukebox availability")
sleep(1)
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
        --[[local item_data = to_json(sound.art.tag)
        local regex_match_backslash = "\\\\" -- double escaped for regex and lua
        local regex_match_quote = "\\\"" -- double escaped for regex and lua
        item_data = string.gsub(item_data, regex_match_backslash..regex_match_quote, "<QUOTE>")
        item_data = string.gsub(item_data, regex_match_quote, "")
        item_data = string.gsub(item_data, "<QUOTE>", "\"")
        print(item_data)--]]
        commands.async.data.modify("entity", "@e[tag=stage_disc_display,limit=1]", "item.id", "set", "value", "\""..sound.art.id.."\"") -- /data modify entity @e[tag=stage_disc_display,limit=1] item set value {id:"minecraft:music_disc_pigstep", Count:1b}
        if sound.art.tag ~= nil then
            local item_data = textutils.serializeJSON(sound.art.tag)
            print(item_data)
            commands.async.data.modify("entity", "@e[tag=stage_disc_display,limit=1]", "item.tag", "set", "value", item_data)
        end
        --dofile("speaker/"..sound.art).draw(album_art)

        --[[local handle, err = http.get { url = sound.url, binary = true }
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
                if #speakers >= 1 then
                    local players = {}
                    for _, speaker in pairs(speakers) do
                        players[#players+1] = make_player(speaker)
                    end
                    parallel.waitForAny(unpack(players))
                else
                    sleep(0.05)
                end
            end
        end--]]

        --[[if #speakers >= 1 then
            for _, speaker in pairs(speakers) do
                speaker.playSound(sound.sound_event)
            end
            sleep(sound.duration)
        else
            sleep(0.05)
        end--]]
        local x1, y1, z1 = config.jukebox_input_pos.x, config.jukebox_input_pos.y, config.jukebox_input_pos.z
        sound.art.Count = 1
        sound.art.Slot = 1
        local ser, _ = string.gsub(textutils.serializeJSON(sound.art), '"Count"\s*:\s*1', '"Count":1b') -- yes this is really correct
        print("Inserting:")
        print(ser)
        commands.async.data.modify("block", x1, y1, z1, "Items", "append", "value", ser)
        -- delay for song playing (duration is in ticks)
        local deadline1 = os.epoch("utc") + (sound.duration/20) * 1000
        repeat sleep(1) until os.epoch("utc") >= deadline1
        --sleep(sound.duration/20) -- duration is in ticks
        print("Waiting 10 seconds for cooldown")

        local deadline = os.epoch("utc") + 10 * 1000
        repeat sleep(1) until os.epoch("utc") >= deadline
        redstone.setBundledOutput("left", colours.yellow)
        sleep(0.1)
        redstone.setBundledOutput("left", 0)
        print("Sleeping 1 second before playing again...")
        sleep(1)
    end
end

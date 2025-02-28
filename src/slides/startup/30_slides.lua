print("Behold, my terrible wiring!")

local function waitForPower()
    while true do
        local event, arg1, arg2, arg3, arg4, arg5 = os.pullEvent()
        if event == "redstone" then
            local mask = redstone.getBundledInput("left")
            if colours.test(mask, colours.brown) then
                return true
            end
        end
    end
end

local function stopSpeakers()
    local speakers = {peripheral.find("speaker")}
    for _, speaker in pairs(speakers) do
        speaker.stop()
    end
end

local function runBGM()
    local function inner()
        shell.run("/speaker/jukebox")
    end
    if not pcall(inner) then
        print("Error running BGM, sleeping for 5 seconds")
        redstone.setBundledOutput("left", colours.red)
        sleep(0.05)
        redstone.setBundledOutput("left", 0)
        sleep(5)
    end
end

local function clearAllMonitors()
    local monitors = {peripheral.find("monitor")}
    for _, monitor in pairs(monitors) do
        monitor.setPaletteColour(colours.black, 0, 0, 0)
        monitor.setBackgroundColour(colours.black)
        monitor.clear()
    end
end

if pocket then
    shell.run("/slide-control")
else
    redstone.setBundledOutput("left", colours.brown)
    sleep(0.1)
    redstone.setBundledOutput("left", 0)
    print("Sleeping 2 seconds...")
    sleep(2)
    term.setTextColour(colours.green)
    print("Automatic slide management system")
    term.setTextColour(colours.white)
    
    shell.run("bg /reboot_watchdog")

    --os.queueEvent("paste", "/slides https://imgur.com/a/38KMRGa")
    while true do
        local mask = redstone.getBundledInput("left")
        if colours.test(mask, colours.brown) then
            print("Item found")
            local info = commands.getBlockInfo(-446, 72, 393).nbt
            if info~=nil and info.HeldItem~=nil and info.HeldItem.Item~=nil and info.HeldItem.Item.tag~=nil and info.HeldItem.Item.tag.pages~=nil and info.HeldItem.Item.tag.pages[0] ~= nil then
                local text = info.HeldItem.Item.tag.pages[0]
                print("Running slides")
                print("/slides "..text)
                clearAllMonitors()
                local function inner()
                    return shell.run("/slides "..text)
                end
                local success, results = pcall(inner)
                if not success or not results then
                    print("Error during slideshow, rebooting after 5 seconds")
                    redstone.setBundledOutput("left", colours.red)
                    sleep(0.05)
                    redstone.setBundledOutput("left", 0)
                    for i = 0, 5 do
                        print(""..(5-i).."...")
                        sleep(1)
                    end
                    break
                end
            end
        else
            print("Running BGM")
            clearAllMonitors()
            --waitForPower()
            parallel.waitForAny(waitForPower, runBGM) -- disable bgm for now (going to use jukebox system instead)
            pcall(stopSpeakers)
        end
    end

    os.reboot()
end

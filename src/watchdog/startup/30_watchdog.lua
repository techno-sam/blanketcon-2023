local function check_command(ok, result)
    local display = ok and print or printError
        for _, line in pairs(result) do display(line) end
end

parallel.waitForAll(function()
    while true do

        -- Turn on all computers
        -- 22: GPS
        -- 25: Quarry
        -- 26: Tree Farm Display
        -- 28: Speaker
        -- 30: Prometheus
        -- 31: Prometheus Monitor
        -- 32: Display
        check_command(commands.computercraft("turn-on #22 #26 #28 #30 #31 #32"))

        sleep(30)
    end
end)

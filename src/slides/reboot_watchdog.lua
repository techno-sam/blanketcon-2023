print("Provide power to a black bundled wire to reboot system")
while true do
    local mask = redstone.getBundledInput("left")
    if colours.test(mask, colours.black) then
        redstone.setBundledOutput("left", colours.red)
        sleep(0.05)
        redstone.setBundledOutput("left", 0)
        os.reboot()
    end
    sleep(0.5)
end
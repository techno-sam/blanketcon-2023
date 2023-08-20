while true do
    local mask = redstone.getBundledInput("left")
    if colours.test(mask, colours.black) then
        os.reboot()
    end
    sleep(0.5)
end
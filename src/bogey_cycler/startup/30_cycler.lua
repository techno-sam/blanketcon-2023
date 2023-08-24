local x, y, z = -113, 78, 64

-- /setblock -113 78 64 railways:tripleaxle_bogey[axis=z,waterlogged=false]{BogeyData:{BogeyStyle:"railways:singleaxle"}} destroy

local bogeys = {
    ["railways:invisible_bogey"] = {
        "railways:invisible"
    },
    ["railways:singleaxle_bogey"] = {
        "railways:singleaxle",
        "railways:leafspring",
        "railways:coilspring"
    },
    ["railways:large_platform_doubleaxle_bogey"] = {
        "railways:freight",
        "railways:archbar",
        "railways:y25"
    },
    ["railways:doubleaxle_bogey"] = {
        "railways:passenger",
        "railways:modern",
        "railways:blomberg"
    },
    ["railways:tripleaxle_bogey"] = {
        "railways:heavyweight",
        "railways:radial"
    }
}

print("Cycling through bogeys!")

while true do
    for block_name, styles in pairs(bogeys) do
        for _, style in ipairs(styles) do
            commands.setblock(x, y, z, block_name.."[axis=z,waterlogged=false]{BogeyData:{BogeyStyle:\""..style.."\"}} destroy")
            sleep(1)
        end
    end
end
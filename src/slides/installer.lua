-- To install: `wget run https://raw.githubusercontent.com/techno-sam/blanketcon-2023/main/src/slides/installer.lua`
-- check if commands are present

if ... == "update" then
    shell.run("rm *")
    shell.run("wget run https://raw.githubusercontent.com/techno-sam/blanketcon-2023/main/src/slides/installer.lua")
end

if not (commands or pocket) then
    printError("The slides system must be installed on a command computer, and a pocket computer. Exiting.")
    exit()
end

local fs_idx
if pocket then
    fs_idx = {
        startup = {
            "30_slides.lua"
        },
        "slide-control.lua",
        "config.lua",
        "button.lua",
        "installer.lua"
    }
    local modem = peripheral.find("modem")
    if not modem then
        printError("Pocket computer must be wireless to work. Exiting.")
        exit()
    end
else
    fs_idx = {
        startup = {
            "30_slides.lua"
        },
        speaker = {
            art = {
                "alcaknight.lua",
                "bossa-nova-4.lua",
                "celeste.lua",
                "diggy.lua",
                "megalo.lua",
                "miku.lua",
                "snapshot.lua",
                "starbound.lua",
                "valkyrie.lua",
                "yuru.lua"
            },
            "jukebox.lua"
        },
        "button.lua",
        "config.lua",
        "loader.lua",
        "questions.lua",
        "reboot_watchdog.lua",
        "slides.lua",
        "installer.lua",
        "hmac_lib.lua",
        "b64_lib.lua"
    }
end

---Install a fs table recursively
---@param path string path so far
---@param tbl table
local function install(path, tbl)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            install(path..k.."/", v)
        elseif type(v) == "string" then
            -- fetch from GH
            local fs_path = path..v
            local gh_path = "https://raw.githubusercontent.com/techno-sam/blanketcon-2023/main/src/slides"..fs_path

            shell.run("wget "..gh_path.." "..fs_path)
        end
    end
end

install("/", fs_idx)

shell.run("reboot")
-- To install: `wget run https://raw.githubusercontent.com/techno-sam/blanketcon-2023/main/src/bogey_cycler/installer.lua`
-- check if commands are present

if ... == "update" then
    shell.run("rm *")
    shell.run("wget run https://raw.githubusercontent.com/techno-sam/blanketcon-2023/main/src/bogey_cycler/installer.lua")
end

if not commands then
    printError("The bogey cycler system must be installed on a command computer. Exiting.")
    exit()
end

local fs_idx = {
    startup = {
        "30_cycler.lua"
    },
    "installer.lua"
}

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
            local gh_path = "https://raw.githubusercontent.com/techno-sam/blanketcon-2023/main/src/bogey_cycler"..fs_path

            shell.run("wget "..gh_path.." "..fs_path)
        end
    end
end

install("/", fs_idx)

shell.run("reboot")
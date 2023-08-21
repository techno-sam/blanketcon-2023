local config = require "config"
local hmac_lib = require "hmac_lib"
local b64 = require "b64_lib"
local api_key = config.enable_imgur and (require "api_key") or ""

local function format_image(image)
    local description = image.description
    local commands = {}
    if description ~= nil then
        local actual_description = nil
        for line in description:gmatch("[^\n]+") do
            if line:sub(1, 1) == "/" then
                commands[#commands + 1] = line
            elseif line ~= "" and actual_description == nil then
                actual_description = line
            end
        end

        description = actual_description
    end

    return {
        url = image.link, width = image.width, height = image.height,
        desc = description, commands = commands,
    }
end

local function load_album(album)
    local response = assert(http.get('https://api.imgur.com/3/album/' .. album .. '/images', {
        Authorization = "Client-ID "..api_key
    }))

    local contents = textutils.unserialiseJSON(response.readAll())
    response.close()

    local images = {}
    for i, image in pairs(contents.data) do images[i] = format_image(image) end
    return images
end


local function stage1(name)
    local album = name:match("^https://imgur.com/a/(.+)")
    if config.enable_imgur and album then return load_album(album) end

    if name:sub(1, 8) == "https://" or name:sub(1, 7) == "http://" then
        local handle = assert(http.get(name))
        local result = textutils.unserialiseJSON(handle.readAll())
        handle.close()
        return result
    else
        local handle = assert(fs.open("slides/" .. name .. ".json", "r"))
        local result = textutils.unserialiseJSON(handle.readAll())
        handle.close()
        return result
    end
end

return function(name)
    local loaded = stage1(name) or {}
    -- command verification and image mode processing: PS for static image, LS for looping video, VS for non-looping video
    for _, slide in ipairs(loaded) do
        local commands = {}
        if slide.commands ~= nil and type(slide.commands) == "table" then
            for command, verification_hash in pairs(slide.commands) do
                if command ~= nil and verification_hash ~= nil and type(command) == "string" and type(verification_hash) == "string" then
                    local real_hash = b64.encode(tostring(hmac_lib.hmac(command, config.command_secret)))
                    if real_hash == verification_hash then
                        commands[#commands+1] = command
                    else
                        print("Unverified command: `"..command.."`, discarding")
                    end
                else
                    print("Unverified command: `"..(type(command)=="string" and command or verification_hash).."`, discarding")
                end
            end
        end
        slide.commands = commands

        local mode = "PS"

        if slide.is_video or string.sub(slide.url, slide.url:len()-2) == "ogv" then
            mode = "VS"

            if slide.looping then
                mode = "LS"
            end
        end

        slide.sign_mode = mode
    end

    return loaded
end

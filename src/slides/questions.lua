local config = require "config"
local x, y, z = config.question_input_pos.x, config.question_input_pos.y, config.question_input_pos.z

local questions, dirty = {}, false

local h = fs.open("/questions.json", "r")
if h then
    questions = textutils.unserialiseJSON(h.readAll())
    h.close()
end

print(("Read %d questions"):format(#questions))

local function save_questions()
    local h = fs.open("/questions.json", "w")
    h.write(textutils.serialiseJSON(questions))
    h.close()
    dirty = true
end

local function add_question(pages, author)
    local pages = table.concat(pages, "\n"):gsub("\n[\n ]*", "\n")
    questions[#questions + 1] = {
        author = author, pages = pages, visible = true,
    }
    save_questions()
end

local function poll_dirty()
    if not dirty then return false end
    dirty = false
    return true
end

local function importQuestion(slot, item)
    if item.id == "minecraft:writable_book" and item.tag and item.tag.pages then
        local pages = {}
        for i = 0, #item.tag.pages do pages[i + 1] = item.tag.pages[i] end
        add_question(pages, "Anonymous")
    elseif item.id == "minecraft:written_book" and item.tag and item.tag.pages then
        local pages = {}
        for i = 0, #item.tag.pages do
            local page = item.tag.pages[i]
            pages[i + 1] = textutils.unserialiseJSON(page).text
        end

        add_question(pages, item.tag.author)
    end
end

local function runInner()
    while true do
        local info = commands.getBlockInfo(x, y, z)
        for slot, item in pairs(info.nbt.Items) do
            local function imp() -- curried form of importQuestion, just to wrap in pcall to catch any exceptions
                return importQuestion(slot, item)
            end
            pcall(imp) -- added for safety

            commands.async.data.remove.block(x, y, z, "Items[" .. slot .. "]")
        end

        sleep(1)
    end
end

local function run()
    while true do
        pcall(runInner)
        print("There was an error in runInner. That's all we know. Waiting 5 seconds to restart question handler...")
        sleep(5)
    end
end

return {
    run = run,
    poll_dirty = poll_dirty,
    questions = questions,
    save_questions = save_questions,
}

local config = require "config"
local pretty = require "cc.pretty"
local button = require "button"
local questions = require "questions"
local wrap = require "cc.strings".wrap
local loader = require "loader"

local CHANNEL = config.remote_control_channel
local modem = peripheral.find("modem", function(_, x) return x.isWireless() end)
modem.open(CHANNEL)

local function to_json(tbl)
    return ("%q"):format(textutils.serializeJSON(tbl))
end

local logo = config.logo

local function create_display(
    x, y, z,
    display_x, display_y, display_z, side_x,
    t_width, t_height
)
    local current_image = false

    return function(image)
        if image == current_image then return end
        current_image = image

        if not image then
            commands.async.data.modify("block", x, y, z, "front_text.messages[0]", "set", "value", to_json { text = "" })
            return
        end

        commands.async.data.modify("block", x, y, z, "front_text.messages[0]", "set", "value", to_json {
            text = ("!%s:%s"):format(image.sign_mode or "PS", image.url)
        })

        local width, height = image.width, image.height

        local scale = math.min(t_width / width, t_height / height)
        width = scale * width
        height = scale * height

        local dx, dy, dz = display_x - x + width * side_x / 2, display_y - y - height / 2, display_z - z

        commands.async.data.modify("block", x, y, z, "front_text.messages[3]", "set", "value", to_json {
            text = ("%s:%s:%s:%s:%s"):format(width, height, dx, dy, dz)
        })
    end
end

local file = ... or error("slides [ALBUM]", 0)
local images = loader(file) or {}
print(("%s has %d images"):format(file, #images))

local margin = 2/16
local display_image = create_display(
    -453, 67, 395,
    -449.0, 76.0, 394.0005, -1,
    10 - margin * 2, 6 - margin * 2
)

local prev_slide_l = create_display(
    -440, 67, 398,
    -440.53125, 71.5625, 398.98, 1,
    0.8, 0.8
)

local next_slide_l = create_display(
    -441, 67, 398,
    -441.46875, 71.5625, 398.98, 1,
    0.8, 0.8
)

local prev_slide_r = create_display(
    -458, 67, 398,
    -458.53125, 71.5625, 398.98, 1,
    0.8, 0.8
)

local next_slide_r = create_display(
    -459, 67, 398,
    -459.46875, 71.5625, 398.98, 1,
    0.8, 0.8
)

local prev_slide_b = create_display(
    -443, 67, 393,
    -443.53125, 72.5625, 393.98, 1,
    0.8, 0.8
)

local next_slide_b = create_display(
    -444, 67, 393,
    -444.46875, 72.5625, 393.98, 1,
    0.8, 0.8
)

local image, blank, dirty, run_cmd = 1, false, true, false
local function go_next() if image < #images then image = image + 1 dirty = true end end
local function go_prev() if image > 1 then image = image - 1 dirty = true end end
local function run_slide_cmd() run_cmd = true end

local display_monitor = peripheral.wrap("monitor_"..config.monitors.display)
display_monitor.setTextScale(5)

local display_width = display_monitor.getSize()

local backstage_monitors = {}
for _, monitor in pairs({ "monitor_"..config.monitors.backstage_a, "monitor_"..config.monitors.backstage_b, "monitor_"..config.monitors.backstage_c }) do
    local backstage_monitor = peripheral.wrap(monitor)
    backstage_monitor.setTextScale(0.5)
    backstage_monitors[monitor] = backstage_monitor
end

local backstage_image = false
local backstage_buttons = {
    next = { x =  2, y = 9, text = "Prev Slide", touch = go_prev },
    prev = { x = 24, y = 9, text = "Next Slide", touch = go_next },
    clear = { x = 2, y = 6, text = "Clear Slide", bg = colours.red, touch = function(self)
        blank = not blank
        dirty = true
    end },
    run_cmd = {x = 20, y = 6, text = "Run Command(s)", bg=colours.purple, touch = run_slide_cmd},
}
if not config.enable_commands then
    backstage_buttons.run_cmd = nil
end
local backstage_width = backstage_monitors["monitor_"..config.monitors.backstage_a].getSize()

local function dismiss_q(self)
    self._question.visible = false
    questions.save_questions()
end

local function show_q(self)
    blank = true
    dirty = true

    dismiss_q(self)

    display_monitor.setTextColour(colours.black)
    display_monitor.setBackgroundColour(colours.white)
    display_monitor.clear()

    -- Display the question
    local lines = wrap(self._question.pages, display_width - 2)
    for y, text in pairs(lines) do
        display_monitor.setCursorPos(2, y + 1)
        display_monitor.write(text)
    end
    display_monitor.setCursorPos(2, #lines + 3)
    display_monitor.write(" - " .. self._question.author)
end

local function sync_remote(slide, next_slide)
    modem.transmit(CHANNEL, CHANNEL, {
        action = "set_state",
        blank = blank,
        current_slide = slide.desc or slide.url,
        next_slide = next_slide and (next_slide.desc or next_slide.url) or "",
        questions = questions.questions,
    })
end

local function draw_box(x, y, w, h, color)
    for i = 0, h do
        term.setBackgroundColour(color)
        term.setCursorPos(x, y + i)
        term.write(string.rep(" ", w))
    end
end

local function tick()
    local slide, next_slide, prev_slide = images[image], images[image + 1], images[image - 1]
    if blank then display_image(nil) else display_image(slide) end
    prev_slide_l(prev_slide) prev_slide_r(prev_slide) prev_slide_b(prev_slide)
    next_slide_l(next_slide) next_slide_r(next_slide) next_slide_b(next_slide)

    if dirty or questions.poll_dirty() then
        dirty = false

        -- Clear all our old buttons
        for k, v in pairs(backstage_buttons) do if v._question then backstage_buttons[k] = nil end end
        backstage_buttons.clear.text = blank and "Show  Slide" or "Clear Slide"
        backstage_buttons.clear.bg = blank and colours.green or colours.red

        for _, backstage_monitor in pairs(backstage_monitors) do
            backstage_monitor.setTextColour(colours.black)
            backstage_monitor.setBackgroundColour(colours.white)
            backstage_monitor.clear()

            local old = term.redirect(backstage_monitor)

            local y, i = 6, 0
            local function start_line() term.setCursorPos(2, y) term.clearLine() y = y + 1 end
            --[[for _, question in pairs(questions.questions) do
                if question.visible then
                    i = i + 1
                    local bg = i % 2 == 0 and colours.lightGrey or colours.white

                    term.setBackgroundColour(bg)
                    start_line()

                    backstage_buttons["q_" .. i] = { x = 55, y = y - 1, text = "\2", bg = colours.green, border = bg, _question = question, touch = show_q }
                    backstage_buttons["r_" .. i] = { x = 55, y = y + 1, text = "X",  bg = colours.red,   border = bg, _question = question, touch = dismiss_q }

                    local wrapped = wrap(question.pages, backstage_width - 4)
                    for i = 1, math.min(6, #wrapped) do -- Trim too long questions. They're probably fine?
                        start_line()
                        term.write(wrapped[i])
                    end
                    start_line()
                    term.write(" - From " .. question.author)

                    start_line()
                    if #wrapped <= 1 then start_line() end
                end
            end]]
            term.setBackgroundColour(colours.white)

            term.setCursorPos(1, 1)
            pretty.print(
                pretty.text("Current Slide: ", colours.lightGrey) .. pretty.text(slide.desc or slide.url) ..
                pretty.space_line ..
                pretty.text("   Next Slide: ", colours.lightGrey) .. pretty.text(next_slide and (next_slide.desc or next_slide.url) or "")
            )
            draw_box(0, 13, backstage_width+1, 11, colours.black)
            draw_box(0, 12, backstage_width+1, 0, colours.grey)
            draw_box(18, 13, 2, 11, colours.grey)
            term.redirect(old)

            button.draw(backstage_buttons, backstage_monitor)
        end

        if not blank then
            display_monitor.setBackgroundColour(colours.black)
            display_monitor.clear()
        end

        sync_remote(slide, next_slide)
    end

    if run_cmd then
        run_cmd = false
        if config.enable_commands then
            for _, command in pairs(slide.commands) do
                print("Running " .. command)
                commands.execAsync(command)
            end
        end
    end

    local event, arg1, arg2, arg3, arg4, arg5 = os.pullEvent()
    if event == "redstone" then
        local mask = redstone.getBundledInput("left")
        if colours.test(mask, colours.white) or colours.test(mask, colours.magenta) then go_next()
        elseif colours.test(mask, colours.lightBlue) or colours.test(mask, colours.orange) then go_prev()
        elseif colours.test(mask, colours.yellow) or colours.test(mask, colours.lime) then
            if config.enable_commands then
                for _, command in pairs(slide.commands) do
                    print("Running " .. command)
                    commands.execAsync(command)
                end
            end
        elseif not colours.test(mask, colours.brown) then
            print("quitting slides")
            prev_slide_l(nil) prev_slide_r(nil) prev_slide_b(nil)
            next_slide_l(nil) next_slide_r(nil) next_slide_b(nil)
            display_image(logo)
            return true
        end
    elseif event == "key" and arg1 == keys.right then go_next()
    elseif event == "key" and arg1 == keys.left then go_prev()
    elseif event == "key" and arg1 == keys.backspace then
        print("Exit key received")
        return true
    elseif event == "monitor_touch" and backstage_monitors[arg1] then
        button.touch(backstage_buttons, arg2, arg3)
    elseif event == "modem_message" and arg2 == CHANNEL and arg5 <= 64 then
        local msg = arg4

        print("Processing " .. pretty.pretty(msg))
        if msg.action == "next_slide" then go_next()
        elseif msg.action == "prev_slide" then go_prev()
        elseif msg.action == "set_blank" then dirty = true blank = msg.blank
        elseif msg.action == "sync_remote" then sync_remote(slide, next_slide)
        elseif msg.action == "show_q" then show_q({ _question = questions.questions[msg.q] })
        elseif msg.action == "dismiss_q" then dismiss_q({ _question = questions.questions[msg.q] })
        end
    elseif event == "modem_message" then print(arg1, arg2, arg3, arg4, arg5)
    elseif event == "task_complete" and arg3 == false then
        -- pretty.print("Task failed " .. pretty.pretty({ ok = arg3, data = arg4 }))
    end
end

parallel.waitForAny(function() repeat until tick() end, questions.run)

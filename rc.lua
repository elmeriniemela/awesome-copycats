--[[

     Awesome WM configuration template
     github.com/lcpz

--]]

-- Required libraries
local awesome, client, mouse, screen, tag = awesome, client, mouse, screen, tag
local ipairs, string, os, table, tostring, tonumber, type = ipairs, string, os, table, tostring, tonumber, type

local gears         = require("gears")
local awful         = require("awful")
                      require("awful.autofocus")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local lain          = require("lain")
--local menubar       = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local vicious       = require("vicious")
local theme         = require("theme")
local exit_screen   = require("widget.exit.exit-screen")




-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
-- require("awful.hotkeys_popup.keys")


local my_table      = awful.util.table or gears.table -- 4.{ 0,1 } compatibility
local dpi           = require("beautiful.xresources").apply_dpi


-- Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end


-- Autostart windowless processes

local function run_or_raise(cmd, class)
    name = class:lower()
    local matcher = function (c)
        if not c.class then
            return false
        end
        local client_class = c.class:lower()
        if client_class:find(class) then
            return true
        end
        return false
    end
    awful.client.run_or_raise(cmd, matcher)
end

local function run_or_raise_name(cmd, name)
    name = name:lower()
    local matcher = function (c)
        if not c.name then
            return false
        end
        local client_class = c.name:lower()
        if client_class:find(name) then
            return true
        end
        return false
    end
    awful.client.run_or_raise(cmd, matcher)
end

-- This function will run once every time Awesome is started
local function run_once(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        awful.spawn.with_shell(string.format("pgrep -u $USER -fx '%s' > /dev/null || (%s &)", cmd, cmd))
    end
end

run_once({
    "nm-applet",
    "picom",
    "lxqt-policykit-agent",
    "clipmenud",
    -- "blueman-applet", -- not really used atmgit s
})

-- run_once({ "urxvtd", "unclutter -root" }) -- entries must be separated by commas

-- This function implements the XDG autostart specification
--[[
awful.spawn.with_shell(
    'if (xrdb -query | grep -q "^awesome\\.started:\\s*true$"); then exit; fi;' ..
    'xrdb -merge <<< "awesome.started:true";' ..
    -- list each of your autostart commands, followed by ; inside single quotes, followed by ..
    'dex --environment Awesome --autostart --search-paths "$XDG_CONFIG_DIRS/autostart:$XDG_CONFIG_HOME/autostart"' -- https://github.com/jceb/dex
)
--]]


-- {{{ Naughty
-- Disable spotify notifications:
-- naughty.config.presets.spotify = {callback = function() return false end}
-- table.insert(naughty.config.mapping, {{appname = "Spotify"}, naughty.config.presets.spotify})

--  Make notifications smaller:
naughty.config.defaults.icon_size = 64

-- }}}

-- Variable definitions


local modkey       = "Mod4"
local altkey       = "Mod1"
local terminal     = "terminator"
local vi_focus     = false -- vi-like client focus - https://github.com/lcpz/awesome-copycats/issues/275
local cycle_prev   = true -- cycle trough all previous client or just the first -- https://github.com/lcpz/awesome-copycats/issues/274
local editor       = os.getenv("EDITOR") or "vim"
local browser      = os.getenv("BROWSER") or "firefox"
local filemanager  = os.getenv("FILEMANAGER") or "pcmanfm"

awful.util.terminal = terminal
awful.util.tagnames = { "WORK", "CHAT", "OTHER", }
awful.layout.layouts = {
    lain.layout.cascade.tile,
    awful.layout.suit.max,
    awful.layout.suit.tile,
    awful.layout.suit.fair,
    awful.layout.suit.floating,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
    -- lain.layout.cascade,
    -- lain.layout.centerwork,
    -- lain.layout.centerwork.horizontal,
    -- lain.layout.termfair,
    -- lain.layout.termfair.center,
}

awful.util.taglist_buttons = my_table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

awful.util.tasklist_buttons = my_table.join(
    awful.button({ }, 1, function (c)
        if c == client.focus then
            c.minimized = true
        else
            --c:emit_signal("request::activate", "tasklist", { raise = true })<Paste>

            -- Without this, the following
            -- :isvisible() makes no sense
            c.minimized = false
            if not c:isvisible() and c.first_tag then
                c.first_tag:view_only()
            end
            -- This will also un-minimize
            -- the client, if needed
            client.focus = c
            c:raise()
        end
    end),
    awful.button({ }, 2, function (c) c:kill() end),
    awful.button({ }, 3, function ()
        local instance = nil

        return function ()
            if instance and instance.wibox.visible then
                instance:hide()
                instance = nil
            else
                instance = awful.menu.clients({ theme = { width = dpi(250) }})
            end
        end
    end),
    awful.button({ }, 4, function () awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function () awful.client.focus.byidx(-1) end)
)

lain.layout.termfair.nmaster           = 3
lain.layout.termfair.ncol              = 1
lain.layout.termfair.center.nmaster    = 3
lain.layout.termfair.center.ncol       = 1
lain.layout.cascade.tile.offset_x      = dpi(2)
lain.layout.cascade.tile.offset_y      = dpi(32)
lain.layout.cascade.tile.extra_padding = dpi(5)
lain.layout.cascade.tile.nmaster       = 5
lain.layout.cascade.tile.ncol          = 2


beautiful.init(theme)




-- Screen
-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", function(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end)

-- No borders when rearranging only 1 non-floating or maximized client
-- screen.connect_signal("arrange", function (s)
--     local only_one = #s.tiled_clients == 1
--     for _, c in pairs(s.clients) do
--         if only_one and not c.floating or c.maximized then
--             c.border_width = 0
--         else
--             c.border_width = beautiful.border_width
--         end
--     end
-- end)


-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s) beautiful.at_screen_connect(s) end)


-- Mouse bindings
-- root.buttons(my_table.join(
--     awful.button({ }, 4, awful.tag.viewnext),
--     awful.button({ }, 5, awful.tag.viewprev)
-- ))


-- Key bindings
globalkeys = my_table.join(

    -- X screen locker
    awful.key({ altkey, "Control" }, "l",
        function ()
            os.execute("slock")
        end,
        { description = "lock screen", group = "hotkeys" }
    ),

    -- -- Hotkeys
    awful.key({ }, "F1",
        function ()
            hotkeys_popup.new{ width = 3000, height = 1500 }:show_help()
        end,
        { description="show help", group="awesome" }
    ),

    -- Tag browsing
    awful.key({ modkey }, "Left",
        awful.tag.viewprev,
        { description = "view previous", group = "tag" }
    ),

    awful.key({ modkey }, "Right",
        awful.tag.viewnext,
        { description = "view next", group = "tag" }
    ),

    awful.key({ modkey }, "Escape",
        awful.tag.history.restore,
        { description = "go back", group = "tag" }
    ),

    -- Non-empty tag browsing
    awful.key({ altkey }, "Left",
        function ()
            lain.util.tag_view_nonempty(-1)
        end,
        { description = "view  previous nonempty", group = "tag" }
    ),

    awful.key({ altkey }, "Right",
        function ()
            lain.util.tag_view_nonempty(1)
        end,
        { description = "view  previous nonempty", group = "tag" }
    ),

    awful.key({ }, "Print",
        function()
            awful.util.spawn_with_shell("flameshot gui")
        end,
        { description = "print screen", group = "hotkeys" }
    ),

    -- Default client focus
    awful.key({ altkey, }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        { description = "focus next by index", group = "client" }
    ),

    awful.key({ altkey, }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        { description = "focus previous by index", group = "client" }
    ),

    -- By direction client focus
    awful.key({ modkey }, "j",
        function()
            awful.client.focus.global_bydirection("down")
            if client.focus then client.focus:raise() end
        end,
        { description = "focus down", group = "client" }
    ),

    awful.key({ modkey }, "k",
        function()
            awful.client.focus.global_bydirection("up")
            if client.focus then client.focus:raise() end
        end,
        { description = "focus up", group = "client" }
    ),

    awful.key({ modkey }, "h",
        function()
            awful.client.focus.global_bydirection("left")
            if client.focus then client.focus:raise() end
        end,
        { description = "focus left", group = "client" }
    ),

    awful.key({ modkey }, "l",
        function()
            awful.client.focus.global_bydirection("right")
            if client.focus then client.focus:raise() end
        end,
        { description = "focus right", group = "client" }
    ),


    -- Layout manipulation
    awful.key({ modkey, "Shift" }, "j",
        function ()
            awful.client.swap.byidx(1)
        end,
        { description = "swap with next client by index", group = "client" }
    ),

    awful.key({ modkey, "Shift" }, "k",
        function ()
            awful.client.swap.byidx( -1)
        end,
        { description = "swap with previous client by index", group = "client" }
    ),

    awful.key({ modkey, "Control" }, "j",
        function ()
            awful.screen.focus_relative(1)
        end,
        { description = "focus the next screen", group = "screen" }
    ),

    awful.key({ modkey, "Control" }, "k",
        function ()
            awful.screen.focus_relative(-1)
        end,
        { description = "focus the previous screen", group = "screen" }
    ),

    awful.key({ modkey }, "u",
        awful.client.urgent.jumpto,
        { description = "jump to urgent client", group = "client" }
    ),

    awful.key({ modkey }, "Tab",
        function ()
            if cycle_prev then
                awful.client.focus.history.previous()
            else
                awful.client.focus.byidx(-1)
            end
            if client.focus then
                client.focus:raise()
            end
        end,
        { description = "cycle with previous/go back", group = "client" }
    ),

    awful.key({ modkey, "Shift" }, "Tab",
        function ()
            if cycle_prev then
                awful.client.focus.byidx(1)
                if client.focus then
                    client.focus:raise()
                end
            end
        end,
        { description = "go forth", group = "client" }
    ),


    -- On the fly useless gaps change
    awful.key({ altkey, "Control" }, "+",
        function ()
            lain.util.useless_gaps_resize(1)
        end,
        { description = "increment useless gaps", group = "tag" }
    ),

    awful.key({ altkey, "Control" }, "-",
        function ()
            lain.util.useless_gaps_resize(-1)
        end,
        { description = "decrement useless gaps", group = "tag" }
    ),


    -- Standard program
    awful.key({ modkey, "Control" }, "r",
        awesome.restart,
        { description = "reload awesome", group = "awesome" }
    ),

    awful.key({ modkey, "Shift" }, "q",
        awesome.quit,
        { description = "quit awesome", group = "awesome" }
    ),

    awful.key({ altkey, "Shift" }, "l",
        function ()
            awful.tag.incmwfact( 0.05)
        end,
        { description = "increase master width factor", group = "layout" }
    ),

    awful.key({ altkey, "Shift" }, "h",
        function ()
            awful.tag.incmwfact(-0.05)
        end,
        { description = "decrease master width factor", group = "layout" }
    ),

    awful.key({ modkey, "Shift" }, "h",
        function ()
            awful.tag.incnmaster(1, nil, true)
        end,
        { description = "increase the number of master clients", group = "layout" }
    ),

    awful.key({ modkey, "Shift" }, "l",
        function ()
            awful.tag.incnmaster(-1, nil, true)
        end,
        { description = "decrease the number of master clients", group = "layout" }
    ),

    awful.key({ modkey, "Control" }, "h",
        function ()
            awful.tag.incncol( 1, nil, true)
        end,
        { description = "increase the number of columns", group = "layout" }
    ),

    awful.key({ modkey, "Control" }, "l",
        function ()
            awful.tag.incncol(-1, nil, true)
        end,
        { description = "decrease the number of columns", group = "layout" }
    ),

    awful.key({ modkey }, "space",
        function ()
            os.execute("rofi -show drun")
        end,
        { description = "select next", group = "layout" }
    ),

    awful.key({ modkey, "Shift" }, "space",
        function ()
            awful.layout.inc(-1)
        end,
        { description = "select previous", group = "layout" }
    ),

    awful.key({ modkey, "Control" }, "n",
        function ()
            local c = awful.client.restore()
            -- Focus restored client
            if c then
                client.focus = c
                c:raise()
            end
        end,
        { description = "restore minimized", group = "client" }
    ),

    -- Widgets popups
    awful.key({ altkey, }, "c",
        function ()
            if beautiful.cal then
                beautiful.cal.show(7)
            end
        end,
        { description = "show calendar", group = "widgets" }
    ),

    awful.key({ altkey, }, "h",
        function ()
            if beautiful.fs then
                beautiful.fs.show(7)
            end
        end,
        { description = "show filesystem", group = "widgets" }
    ),


    -- Brightness
    awful.key({ }, "XF86MonBrightnessUp",
        function ()
            os.execute("xbacklight -inc 10")
        end,
        { description = "+10%", group = "hotkeys" }
    ),

    awful.key({ }, "XF86MonBrightnessDown",
        function ()
            os.execute("xbacklight -dec 10")
        end,
        { description = "-10%", group = "hotkeys" }
    ),

    awful.key({ }, "XF86PowerOff",
        function()
            exit_screen.show()
        end,
        { description = "show exitscreen", group = "hotkeys" }
    ),

    awful.key({ }, "XF86PowerDown",
        function()
            exit_screen.show()
        end,
        { description = "show exitscreen", group = "hotkeys" }
    ),

    -- ALSA volume control
    awful.key({ }, "XF86AudioRaiseVolume",
        function ()
            os.execute(string.format("amixer -q set %s 5%%+", beautiful.volume.channel))
            beautiful.volume.update()
        end,
        { description = "volume up", group = "hotkeys" }
    ),

    awful.key({ }, "XF86AudioLowerVolume",
        function ()
            os.execute(string.format("amixer -q set %s 5%%-", beautiful.volume.channel))
            beautiful.volume.update()
        end,
        { description = "volume down", group = "hotkeys" }
    ),

    awful.key({ }, "XF86AudioMute",
        function ()
            os.execute(string.format("amixer -q set %s toggle", beautiful.volume.togglechannel or beautiful.volume.channel))
            beautiful.volume.update()
        end,
        { description = "toggle audio mute", group = "hotkeys" }
    ),

    awful.key({ "Control" }, "XF86AudioRaiseVolume",
        function ()
            os.execute(string.format("amixer -q set %s 5%%+", beautiful.mic.channel))
            beautiful.mic.update()
        end,
        { description = "mic up", group = "hotkeys" }
    ),

    awful.key({ "Control" }, "XF86AudioLowerVolume",
        function ()
            os.execute(string.format("amixer -q set %s 5%%-", beautiful.mic.channel))
            beautiful.mic.update()
        end,
        { description = "mic down", group = "hotkeys" }
    ),

    awful.key({ }, "XF86AudioMicMute",
        function ()
            os.execute(string.format("amixer -q set %s toggle", beautiful.mic.togglechannel or beautiful.mic.channel))
            beautiful.mic.update()
        end,
        { description = "toggle mic mute", group = "hotkeys" }
    ),


    awful.key({ }, "XF86Tools",
        function ()
            run_or_raise("pavucontrol", "pavucontrol")
        end,
        { description = "configure audio", group = "hotkeys" }
    ),

    awful.key({ }, "XF86ScreenSaver",
        function ()
            run_or_raise("arandr", "arandr")
        end,
        { description = "reconfigure monitors", group = "hotkeys" }
    ),

    awful.key({ }, "XF86Display",
        function ()
            run_or_raise("arandr", "arandr")
        end,
        { description = "reconfigure monitors", group = "hotkeys" }
    ),

    awful.key({ altkey, }, "w",
        function ()
            awful.spawn.easy_async(
                "bootstrap-linux monitor",
                function (stdout, stderr, exitreason, exitcode)
                    awesome.restart()
                end
            )
        end,
        { description = "autoconfigure monitors", group = "hotkeys" }
    ),

    -- User programs
    awful.key({ modkey }, "Return",
        function ()
            run_or_raise(terminal, terminal)
        end,
        { description = "open existing or new terminal", group = "launcher" }
    ),

    awful.key({ modkey, "Shift" }, "Return",
        function ()
            awful.spawn(terminal)
        end,
        { description = "open new terminal", group = "launcher" }
    ),

    awful.key({ modkey, }, "d",
        function ()
            run_or_raise_name("libreoffice Documents/DEADLINES.ods", "DEADLINES.ods")
        end,
        { description = "open new terminal", group = "launcher" }
    ),

    awful.key({ modkey }, "q",
        function ()
            run_or_raise(browser, browser)
        end,
        { description = "open browser", group = "launcher" }
    ),

    -- By default firefox binds this to exit which is inconvinent considering { modkey }, "q" should open firefox
    -- awful.key({ "Control" }, "q",
    --     function ()
    --         run_or_raise(browser, browser)
    --     end,
    --     { description = "open browser", group = "launcher" }
    -- ),

    awful.key({ modkey }, "e",
        function ()
            run_or_raise(filemanager, filemanager)
        end,
        { description = "open filemanager", group = "launcher" }
    ),

    awful.key({ modkey }, "t",
        function ()
            run_or_raise("thunderbird", "thunderbird")
        end,
        { description = "open thunderbird", group = "launcher" }
    ),

    awful.key({ modkey }, "w",
        function ()
            run_or_raise("whatsapp-nativefier", "whatsapp")
        end,
        { description = "open whatsapp", group = "launcher" }
    ),

    awful.key({ modkey }, "a",
        function ()
            run_or_raise("signal-desktop", "signal")
        end,
        { description = "open signal", group = "launcher" }
    ),

    awful.key({ modkey }, "s",
        function ()
            run_or_raise("slack", "slack")
        end,
        { description = "open slack", group = "launcher" }
    ),

    awful.key({ modkey }, "z",
        function ()
            run_or_raise("zoom", "zoom")
        end,
        { description = "open zoom", group = "launcher" }
    ),

    awful.key({ modkey }, "v",
        function ()
            awful.spawn.with_shell("clipmenu && xdotool key Shift+Insert")
        end,
        { description = "open clipmenu", group = "launcher" }
    ),

    awful.key({ modkey }, "c",
        function ()
            run_or_raise("code", "code")
        end,
        { description = "open code", group = "launcher" }
    ),

    awful.key({ modkey }, "g",
        function ()
            run_or_raise("galculator", "galculator")
        end,
        { description = "open galculator", group = "launcher" }
    ),

    -- Prompt
    awful.key({ modkey }, "r",
        function ()
            os.execute("rofi -show run")
        end,
        { description = "run prompt", group = "launcher" }
    )

)

clientkeys = my_table.join(

    awful.key({ altkey, "Shift" }, "m",
        lain.util.magnify_client,
        { description = "magnify client", group = "client" }
    ),

    awful.key({ modkey }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        { description = "toggle fullscreen", group = "client" }
    ),

    awful.key({ altkey, }, "F4",
        function (c)
            c:kill()
        end,
        { description = "close", group = "client" }
    ),

    awful.key({ modkey, "Control" }, "space",
        awful.client.floating.toggle,
        { description = "toggle floating", group = "client" }
    ),

    awful.key({ modkey, "Control" }, "Return",
        function (c)
            c:swap(awful.client.getmaster())
        end,
        { description = "move to master", group = "client" }
    ),

    awful.key({ modkey }, "o",
        function (c)
            c:move_to_screen()
        end,
        { description = "move to screen", group = "client" }
    ),

    awful.key({ modkey }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        { description = "minimize", group = "client" }
    ),

    awful.key({ modkey }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        { description = "maximize", group = "client" }
    )
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    -- Hack to only show tags 1 and 9 in the shortcut window (mod+s)
    local descr_view, descr_toggle, descr_move, descr_toggle_focus
    if i == 1 or i == 9 then
        descr_view = { description = "view tag #", group = "tag" }
        descr_toggle = { description = "toggle tag #", group = "tag" }
        descr_move = { description = "move focused client to tag #", group = "tag" }
        descr_toggle_focus = { description = "toggle focused client on tag #", group = "tag" }
    end
    globalkeys = my_table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
            function ()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
            descr_view
        ),

        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
            function ()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end,
            descr_toggle
        ),

        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
            function ()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                    end
                end
            end,
            descr_move
        ),

        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
            function ()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                    end
                end
            end,
            descr_toggle_focus
        )
    )
end

-- Set keys
root.keys(globalkeys)

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end)
)


-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    {
        -- All clients will match this rule.
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            switch_to_tags=true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen,
            size_hints_honor = false,
            maximized = false,
            maximized_horizontal = false,
            maximized_vertical = false,
            floating = false,
            -- tag = "WORK" -- Default workspace for new windows
        }
    },
    -- Floating clients.
    {
        rule_any = {
            instance = {
                "DTA",  -- Firefox addon DownThemAll.
            },
            class = {
                "Arandr",
                "Gpick",
                "Kruler",
                "MessageWin",  -- kalarm.
                "MPlayer",
                "Sxiv",
                "Wpa_gui",
                "pinentry",
                "veromix",
                "xtightvncviewer",
                ".*%.py$",
                "zoom",
                "Matplotlib",
                "Galculator",
            },

            name = {
                "Event Tester",  -- xev.
            },
            role = {
                "AlarmWindow",  -- Thunderbird's calendar.
                "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
            },
            type = {
                "popup_menu",
                "notification",
                "dnd",
                "dialog",       -- "Pop up" dialog
            }
        },

        properties = {
            floating = true,
            placement = awful.placement.under_mouse + awful.placement.no_offscreen,
        }
    },

    -- Titlebars
    {
        rule_any = { type = { "dialog", "normal" } },
        properties = { titlebars_enabled = true }
    },

    -- -- find class with 'xprop WM_CLASS'
    {
        rule_any = {
            class = {
                "Slack",
                "Thunderbird",
                "whatsapp-nativefier-d40211",
                "zoom",
                "Signal",
                "Zulip",
                "TelegramDesktop",
                "discord",
            },
        },
        properties = {
            tag = "CHAT"
        },
    },


    {
        rule_any = {
            class = {
                "firefox",
                "Terminator",
                "code-oss",
            },
        },
        properties = {
            tag = "WORK"
        },
    },



}


-- Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- Custom
    if beautiful.titlebar_fun then
        beautiful.titlebar_fun(c)
        return
    end

    -- Default
    -- buttons for the titlebar
    local buttons = my_table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c, { size = dpi(20) }) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.minimizebutton (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
    awful.titlebar.enable_tooltip = false
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", { raise = vi_focus })
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

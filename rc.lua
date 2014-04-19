-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local bashets = require("bashets/bashets")
-- Monkey Patches
local progressbar = require("progressbar")

-- {{{ Error handling
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
    awesome.connect_signal("debug::error", function(err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Quit handler
awesome.connect_signal("exit", function() bashets.stop() end)
-- }}}

-- {{{ Variable definitions
local myroot = "/home/jin/.config/awesome/"
-- This is used later as the default terminal and editor to run.
terminal = "urxvt" or "xterm"
editor = os.getenv("EDITOR") or "vi"
editor_cmd = terminal .. " -e " .. editor
browser = "google-chrome-stable"

-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/zenburn/theme.lua")

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
altkey = "Mod1"
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    --awful.layout.suit.max.fullscreen,
    --awful.layout.suit.magnifier,
    awful.layout.suit.floating,
}
-- }}}

-- {{{ Wallpaper
local wp_timer = timer { timeout = 10 }
local wp_files = {}
wp_timer:connect_signal("timeout", function()
    if next(wp_files) == nil then
        local fh = io.popen("find /home/jin/images/bkg -type f | grep -Ei \"\\\.(jpg|jpeg|gif|bmp|png)\$\" | grep -v vertical | rl")
        for file in fh:lines() do table.insert(wp_files, file) end
        io.close(fh)
    end
    local wp_file = table.remove(wp_files)
    naughty.notify({title = "wallpaper", text = wp_file})
    for s=1, screen.count() do
        if string.match(wp_file, '/center/') then
            gears.wallpaper.centered(wp_file, s, "#000000")
        else
            gears.wallpaper.fit(wp_file, s, "#000000")
        end
    end
    wp_timer:stop()
    wp_timer.timeout = 60 * 60
    wp_timer:start()
end)
wp_timer:start()
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 'α', 'β', 'γ', 'δ' }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit },
   --{ "reboot", "reboot" },
   --{ "shutdown", "shutdown" },
}

mymainmenu = awful.menu({ items = {
   { "terminal", terminal },
   { "browser", browser },
   { "awesome", myawesomemenu, beautiful.awesome_icon },
}})

mylauncher = awful.widget.launcher({
    image = beautiful.awesome_icon, menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
menubar.show_categories = false
--menubar.cache_entries = true
--menubar.app_folders = { "/usr/share/applications" }
-- }}}

-- {{{ Wibox
local separator = wibox.widget.textbox()
separator:set_text(" ◦ ")

-- Create a textclock widget
local calendar = nil
local offset = 0
mytextclock = awful.widget.textclock(" %a %m/%d %H:%M ", 60)

function remove_calendar()
    if calendar ~= nil then
        naughty.destroy(calendar)
        calendar = nil
        offset = 0
    end
end

function add_calendar(inc_offset)
    local save_offset = offset
    remove_calendar()
    offset = save_offset + inc_offset
    local datespec = os.date("*t")
    datespec = datespec.year * 12 + datespec.month - 1 + offset
    datespec = (datespec % 12 + 1) .. " " .. math.floor(datespec / 12)
    local cal = awful.util.pread("cal " .. datespec)
    cal = string.gsub(cal, "^%s*(.-)%s*$", "%1")
    calendar = naughty.notify({
        text = string.format('<span font_desc="terminus">%s</span>', cal),
        timeout = 0,
        hover_timeout = 0.5,
    })
end

mytextclock:connect_signal("mouse::enter", function() add_calendar(0) end)
mytextclock:connect_signal("mouse::leave", remove_calendar)
mytextclock:buttons( awful.util.table.join(
    awful.button({ }, 4, function() add_calendar(-1) end),
    awful.button({ }, 5, function() add_calendar(1)  end)))

-- Bashets
local bashets_shm_path = string.format("/run/tmp/%s-bashets/", os.getenv("USER"))
bashets.set_script_path(bashets_shm_path)
bashets.set_temporary_path(bashets_shm_path)
os.execute("mkdir -p " .. bashets_shm_path)
os.execute("cp " .. myroot .. "bashets/userscripts/* " .. bashets_shm_path)
os.execute("cp " .. myroot .. "mybashets/* " .. bashets_shm_path)
local volumew = progressbar()
volumew:set_max_value(100)
volumew:set_vertical(true):set_ticks(true)
volumew:set_width(5):set_ticks_size(1)
volumew:set_color('#eab93d')
volumew.get_volume_string = function()
    return string.format("Volume: %d%%", volumew:get_value())
end
volumew.tooltip = awful.tooltip({
    objects = { volumew },
    timer_function = volumew.get_volume_string
})
bashets.register("vollevel.sh Master", {widget = volumew, callback = function(data)
    if data[1] ~= volumew.last_value then
        volumew.naughty_id = naughty.notify({
            text = volumew.get_volume_string(),
            replaces_id = volumew.naughty_id,
            timeout = 1}).id
        volumew.last_value = data[1]
    end
end})
bashets.start()

-- Create awesompd
local awesompd = require('awesompd/awesompd')
local mpdw = awesompd:create() -- Create awesompd widget
mpdw.font = "Terminus 8" -- Set widget font
mpdw.background = "#2a2a2a" --Set widget background color
mpdw.scrolling = true -- If true, the text in the widget will be scrolled
mpdw.output_size = 30 -- Set the size of widget in symbols
mpdw.update_interval = 10 -- Set the update interval in seconds
mpdw.path_to_icons = myroot .. "awesompd/icons"
mpdw.jamendo_format = awesompd.FORMAT_MP3
mpdw.browser = browser
mpdw.show_album_cover = true
mpdw.album_cover_size = 50 -- max 100
mpdw.mpd_config = "/etc/mpd.conf"
mpdw.ldecorator = "" -- empty for outside decoration
mpdw.rdecorator = " " -- empty for outside decoration
mpdw.servers = { { server = "localhost", port = 6600 }, }
mpdw:register_buttons({
    { "", "XF86AudioPlay", mpdw:command_playpause() },
    { modkey, "XF86Back", mpdw:command_prev_track() },
    { modkey, "XF86Forward", mpdw:command_next_track() },
    { "Control", awesompd.MOUSE_SCROLL_UP, mpdw:command_prev_track() },
    { "Control", awesompd.MOUSE_SCROLL_DOWN, mpdw:command_next_track() },
    { "", awesompd.MOUSE_LEFT, mpdw:command_toggle() },
    { "", awesompd.MOUSE_RIGHT, mpdw:command_show_menu() },
})
mpdw:run() -- After all configuration is done, run the widget

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
    awful.button({ }, 1, awful.tag.viewonly),
    awful.button({ modkey }, 1, awful.client.movetotag),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, awful.client.toggletag),
    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end))

mytasklist = {}
mytasklist.buttons = awful.util.table.join(
    awful.button({ }, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            -- Without this, the following
            -- :isvisible() makes no sense
            c.minimized = false
            if not c:isvisible() then
                awful.tag.viewonly(c:tags()[1])
            end
            -- This will also un-minimize
            -- the client, if needed
            client.focus = c
            c:raise()
        end
    end),
    awful.button({ }, 2, function()
        if instance then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ width=250 })
        end
    end),
    awful.button({ }, 4, function()
        awful.client.focus.byidx(1)
        if client.focus then client.focus:raise() end
    end),
    awful.button({ }, 5, function()
        awful.client.focus.byidx(-1)
        if client.focus then client.focus:raise() end
    end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
        awful.button({ }, 1, function() awful.layout.inc(layouts, 1) end),
        awful.button({ }, 3, function() awful.layout.inc(layouts, -1) end),
        awful.button({ }, 4, function() awful.layout.inc(layouts, 1) end),
        awful.button({ }, 5, function() awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mylayoutbox[s])
    left_layout:add(separator)
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(mpdw.widget)
    right_layout:add(volumew)
    right_layout:add(separator)
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(separator)
    right_layout:add(mytextclock)

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    --awful.button({ }, 4, awful.tag.viewnext),
    --awful.button({ }, 5, awful.tag.viewprev),
    awful.button({ }, 3, function() mymainmenu:toggle() end)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j", function()
        awful.client.focus.byidx( 1)
        if client.focus then client.focus:raise() end
    end),
    awful.key({ modkey,           }, "k", function()
        awful.client.focus.byidx(-1)
        if client.focus then client.focus:raise() end
    end),
    awful.key({ modkey,           }, "w", function() mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function() awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function() awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function() awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function() awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab", function()
        --awful.client.focus.history.previous()
        awful.client.focus.byidx(-1)
        if client.focus then client.focus:raise() end
    end),
    awful.key({ modkey, "Shift"   }, "Tab", function()
        awful.client.focus.byidx(1)
        if client.focus then client.focus:raise() end
    end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function() awful.util.spawn(terminal) end),
    awful.key({ modkey, "Shift"   }, "Return", function() awful.util.spawn(browser) end),
    awful.key({ modkey, "Control" }, "l", function() awful.util.spawn("slock", false) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Control" }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function() awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function() awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function() awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function() awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function() awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function() awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function() awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function() awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey }, "r", function() awful.prompt.run(
        { prompt = "Run: " },
        mypromptbox[mouse.screen].widget,
        function(cmd) -- terminal check
            cmd = cmd:gsub('^:', terminal .. " -e ", 1)
            awful.util.spawn(cmd)
        end,
        function(cmd, pos, ncomp, shell) -- clean for completion
            local use_term = false
            if cmd:sub(1,1) == ":" then
                term = true
                cmd = cmd:sub(2)
                pos = pos - 1
            end
            cmd, pos = awful.completion.shell(cmd, pos, ncomp, shell)
            if term == true then
                cmd = ':' .. cmd
                pos = pos + 1
            end
            return cmd, pos
        end,
        awful.util.getdir("cache") .. "/history")
    end),
    awful.key({ modkey }, "x", function() awful.prompt.run(
        { prompt = "Run Lua code: " },
        mypromptbox[mouse.screen].widget,
        awful.util.eval, nil,
        awful.util.getdir("cache") .. "/history_eval")
    end),

    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end),

    -- mpc
    --awful.key({ modkey }, "XF86Forward", function() awful.util.spawn("mpc next", false) end),
    --awful.key({ modkey }, "XF86Back", function() awful.util.spawn("mpc prev", false) end),
    --awful.key({        }, "XF86AudioPlay", function() awful.util.spawn("mpc toggle", false) end),

    -- Audio
    awful.key({}, "XF86AudioMute",
       function() awful.util.spawn("amixer -q sset Master toggle", false) end),
    awful.key({}, "XF86AudioLowerVolume",
       function() awful.util.spawn("amixer -q set Master 1%-", false) end),
    awful.key({}, "XF86AudioRaiseVolume",
       function() awful.util.spawn("amixer -q set Master 1%+", false) end),

    -- Startup
    --XF86HomePage
    --XF86Search
    --XF86Mail
    --XF86Favorites
    --XF86Launch5
    --XF86Launch6
    --XF86Launch7
    --XF86Launch8
    --XF86Launch9
    awful.key({ modkey }, "XF86Calculator", function() awful.util.spawn(terminal .. " -e python") end),
    awful.key({        }, "XF86Calculator", function() awful.prompt.run(
        { prompt = "Calculate: " },
        mypromptbox[mouse.screen].widget,
        function(expr)
            local result = awful.util.eval("return (" .. expr .. ")")
            naughty.notify({text = expr .. " = " .. result, position = "top_left", timeout = 10})
        end)
    end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function(c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Control" }, "c",      function(c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function(c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function(c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n", function(c)
        -- The client currently has the input focus, so it cannot be
        -- minimized, since minimized clients can't have the focus.
        c.minimized = true
    end),
    awful.key({ modkey,           }, "m", function(c)
        c.maximized_horizontal = not c.maximized_horizontal
        c.maximized_vertical   = not c.maximized_vertical
    end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.movetotag(tag)
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.toggletag(tag)
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function(c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
mpdw:append_global_keys()
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     size_hints_honor = false } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
    { rule = { class = "qemu" }, properties = { floating = true } },
    { rule = { class = "Vlc" }, properties = { floating = true } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- vim: set ts=4 sw=4:

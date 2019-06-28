local gears = require("gears")
local awful = require('awful')
local naughty = require('naughty')
local wibox = require('wibox')
local lain = require('lain')
local helpers = require('lain.helpers')
local markup = lain.util.markup
local dofile = dofile
local format = string.format

local theme = gears.protected_call(dofile, awful.util.get_themes_dir() .. 'zenburn/theme.lua')

-- desktop background color
theme.desktop_color = '#000'

-- fonts
theme.font = 'roboto sans 8'
theme.monofont = 'roboto mono 8'

-- icons
theme.notification_icon_size = 64
theme.lain_icons         = os.getenv('HOME') ..
                           '/.config/awesome/lain/icons/layout/zenburn/'
theme.layout_termfair    = theme.lain_icons .. 'termfair.png'
theme.layout_centerfair  = theme.lain_icons .. 'centerfair.png'  -- termfair.center
theme.layout_cascade     = theme.lain_icons .. 'cascade.png'
theme.layout_cascadetile = theme.lain_icons .. 'cascadetile.png' -- cascade.tile
theme.layout_centerwork  = theme.lain_icons .. 'centerwork.png'
theme.layout_centerhwork = theme.lain_icons .. 'centerworkh.png' -- centerwork.horizonta

-- clock & calendar
theme.clock = wibox.widget.textclock(' %H:%M ')
lain.widget.cal({
   attach_to = { theme.clock },
   week_start = 1,
   three = true,
   notification_preset = {
      font = theme.monofont,
      fg = theme.fg_normal,
      bg = theme.bg_systray,
   }
})

-- volume
local volume = lain.widget.pulsebar({
   ticks = true, ticks_size = 3,
   colors = {
      background = theme.bg_focus,
      unmute = theme.fg_normal,
      mute = theme.fg_urgent,
   },
})
--volume.tooltip.font = theme.font
--volume.tooltip.fg = theme.fg_normal
--volume.tooltip.bg = theme.bg_systray
volume.widget = wibox.container.rotate(volume.bar, 'east')
volume.widget.forced_width = 10
local vol_set_cmd = function(action, value)
   return format('pactl %s %s %s', action, volume.device, value)
end
volume.fx = {
   mixer = function() awful.spawn('pavucontrol') end,
   mute = function()
      awful.spawn(vol_set_cmd('set-sink-mute', 'toggle'), false)
      volume.update()
   end,
   up = function()
      awful.spawn(vol_set_cmd('set-sink-volume', '+1%'), false)
      volume.update()
   end,
   down = function()
      awful.spawn(vol_set_cmd('set-sink-volume', '-1%'), false)
      volume.update()
   end,
}
volume.widget:buttons(gears.table.join(
   awful.button({}, 1, volume.fx.mixer),
   awful.button({}, 3, volume.fx.mute),
   awful.button({}, 4, volume.fx.up),
   awful.button({}, 5, volume.fx.down)
))
theme.volume = volume

-- mpd
local mode_icons = {
   repeat_mode = '↻',
   random_mode = '?',
   single_mode = '1',
   consume_mode = '🍽',
}
local mpd = lain.widget.mpd({
   music_dir = '/zmedia/music',
   settings = function()
      if mpd_now.state == 'stop' then
         widget:set_markup('')
      else
         widget:set_markup(markup.font(theme.font, mpd_now.artist))
         if widget.tooltip == nil then
            widget.tooltip = awful.tooltip({ objects = { widget } })
         end
         local modes = {mpd_now.state}
         for k,v in pairs(mpd_now) do
            if mode_icons[k] ~= nil and v then
               table.insert(modes, mode_icons[k])
            end
         end
         widget.tooltip:set_text(
            format('%s\n--\n%s\n%s', mpd_notification_preset.text, mpd_now.file, table.concat(modes, ' ')))
      end
   end
})
theme.mpd = mpd

-- randomized wallpaper
local wp_file = nil
local wp_files = {}
theme.wallpaper = function(s)
   if next(wp_files) == nil then
      local fh = io.popen([[ find /home/jin/images/bkg -type f | grep -Ei "\\.(jpg|jpeg|gif|bmp|png)$" | grep -Ev "vertical" | shuf ]])
      for file in fh:lines() do
         table.insert(wp_files, file)
      end
   end
   if wp_file == nil or s == nil then wp_file = table.remove(wp_files) end
   if wp_file ~= nil then
      naughty.notify({title = 'wallpaper', text = wp_file, position = 'bottom_right'})
      if string.match(wp_file, '/center/') then
         gears.wallpaper.centered(wp_file, s, theme.desktop_color)
      elseif string.match(wp_file, '/fit/') then
         gears.wallpaper.fit(wp_file, s, theme.desktop_color)
      else
         gears.wallpaper.maximized(wp_file, s, true)
      end
   end
end
helpers.newtimer('wallpaper', 30 * 60, function() theme.wallpaper(nil) end, true, true)

return theme

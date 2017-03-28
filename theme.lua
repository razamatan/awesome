local awful = require('awful')
local wibox = require('wibox')
local lain = require('lain')
local protected_call = require('gears.protected_call')
local dofile = dofile
local format = string.format

local theme = protected_call(dofile, awful.util.get_themes_dir() .. 'zenburn/theme.lua')

-- fonts
theme.font = 'roboto sans 8'
theme.monofont = 'roboto mono 8'

-- icons
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
theme.clock.font = theme.font
lain.widget.calendar({
   attach_to = { theme.clock },
   notification_preset = {
      font = theme.monofont,
      fg = theme.fg_normal,
      bg = theme.bg_systray,
   }
})

-- volume
local volume = lain.widget.alsabar({
   notification_preset = { font = theme.font },
   ticks = true, ticks_size = 3,
   colors = {
      background = theme.bg_focus,
      unmute = theme.fg_normal,
      mute = theme.fg_urgent,
   },
})
volume.tooltip.wibox.font = theme.font
volume.tooltip.wibox.fg = theme.fg_normal
volume.tooltip.wibox.bg = theme.bg_systray
volume.widget = wibox.container.rotate(volume.bar, 'east')
volume.widget.forced_width = 10
local vol_set_cmd = function(action)
   return format('%s set %s %s', volume.cmd, volume.channel, action)
end
volume.fx = {
   mixer = function() awful.spawn('pavucontrol') end,
   mute = function()
      awful.spawn(vol_set_cmd('toggle'), false)
      volume.update()
   end,
   up = function()
      awful.spawn(vol_set_cmd('1%+'), false)
      volume.update()
   end,
   down = function()
      awful.spawn(vol_set_cmd('1%-'), false)
      volume.update()
   end,
}
volume.widget:buttons(awful.util.table.join(
   awful.button({}, 1, volume.fx.mixer),
   awful.button({}, 3, volume.fx.mute),
   awful.button({}, 4, volume.fx.up),
   awful.button({}, 5, volume.fx.down)
))
theme.volume = volume

return theme

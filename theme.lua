local dofile = dofile
local awful = require("awful")
local protected_call = require("gears.protected_call")
local theme = protected_call(dofile, awful.util.get_themes_dir() .. "zenburn/theme.lua")

local lain = require("lain")

theme.volume = lain.widget.alsa({
   settings = function()
      if volume_now.status == 'off' then
         volume_now.level = volume_now.level .. 'M'
      end
      widget:set_markup(volume_now.level .. '% ')
   end
})

return theme

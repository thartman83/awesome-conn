-------------------------------------------------------------------------------
-- init.lua for awesome-conn                                                 --
-- Copyright (c) 2018 Tom Hartman (thomas.lees.hartman@gmail.com)            --
--                                                                           --
-- This program is free software; you can redistribute it and/or             --
-- modify it under the terms of the GNU General Public License               --
-- as published by the Free Software Foundation; either version 2            --
-- of the License, or the License, or (at your option) any later             --
-- version.                                                                  --
--                                                                           --
-- This program is distributed in the hope that it will be useful,           --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of            --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             --
-- GNU General Public License for more details.                              --
-------------------------------------------------------------------------------

--- Commentary -- {{{
-- 
-- }}}

--- awesome-conn -- {{{

--- Variables and Libraries-- {{{
local wibox     = require('wibox'       )
local awful     = require('awful'       )
local gtable    = require('gears.table' )
local gstring   = require('gears.string')
local connman   = require('connman_dbus')
local serpent   = require('serpent'     )
local naughty   = require('naughty'     )
local ac        = {}
-- }}}

--- enums -- {{{
local conn_state = { online = "online", idle = "idle", ready = "ready",
                     offline = "offline", failure = "failure" }
-- }}}

--- helper functions -- {{{
function gstring.trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end
-- }}}

--- ac:scan -- {{{
-- 
function ac:scan ()
   if self.scanning then
      naughty.notify { text="Already Scanning, please wait" }
   else
      self.scanning = true
      awful.spawn.easy_async({ "connmanctl", "scan", "wifi" },
         function (so, se, er, ec)
            self.scanning = false
            if ec ~= 0 or se ~= "" then
               naughty.notify({title = "Error Scanning for Wifi",
                              text = "An error occured while scanning wifi: " .. error_reason ..
                                 " " .. strerr, timeout = 0})
            else
               naughty.notify {title = "Scan Complete", text = "", timeout = 3}
            end
      end)
   end
end
-- }}}

--- ac:build_connect_fn -- {{{
-- 
function ac:build_connect_fn (service)
   return function ()
      local service_id = service.object_path:gsub("/.*/","")

      awful.spawn.easy_async( { "connmanctl", "connect", service_id },
         function (so, se, er, ec)
            if se ~= "" or ec ~= 0 then
               naughty.notify { text = "Error occured while connecting: " .. se }
            else               
               naughty.notify( { text = "Connected to " .. service.Name } )
            end
         end
      )
   end
end
-- }}}

--- ac:build_menu_item -- {{{
-- 
function ac:build_menu_item (service)
   local lock_glyph = "🔒 "
   local heart_glyph = "❤ "
   local check_glyph = "✓ "

   local item_name = ""

   if service.State == "online" then
      item_name = item_name .. check_glyph
   elseif service.Favorite then
      item_name = item_name .. heart_glyph
   end
      
   if #(service.Security) ~= 0 then
      item_name = item_name .. lock_glyph
   end

   item_name = item_name .. service.Name

   return { item_name, self:build_connect_fn(service) }   
end
-- }}}

--- w:update -- {{{
----------------------------------------------------------------------
-- Update the widget
----------------------------------------------------------------------
function ac:update ()
   self._cur_service = self._connMgr.services[1]
   
   self._serviceInfo.text = self._cur_service.Name .. " - " ..
      self._cur_service.Strength

   self._menu_tbl = { { "Scan...", function () self:scan() end }, { "" } }
   for k,v in pairs(self._connMgr.services) do
      if v.Name ~= nil then
         table.insert(self._menu_tbl, self:build_menu_item(v))
      end
   end

   self._menu = awful.menu( { items = self._menu_tbl } )
   self:emit_signal("widget::updated")
end
-- }}}

--- ac:toggle_menu -- {{{
-- 
function ac:toggle_menu ()
   self._menu:toggle()
end
-- }}}
   
--- new -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
local function new (...)
   local w        = wibox.layout.fixed.horizontal()
   w._connIcon    = wibox.widget {image = nil,
                                  resize = false,
                                  widget = wibox.widget.imagebox}
   w._serviceInfo = wibox.widget {markup = 'placeholder',
                                  align = "center",
                                  valign = "center",
                                  resize = true,
                                  widget = wibox.widget.textbox}
   w:add(w._connIcon, w._serviceInfo)
   
   gtable.crush(w, ac, true)
   w._connMgr = connman

   -- Connect up the signals
   connman:connect_signal(
      function (self)
         w:update()
      end,
      "PropertyChanged"
   )

   connman:connect_signal(
      function (self)
         w:update()
      end,
      "ServicesChanged"
   )

   -- hook up the menu
   w:buttons(gtable.join(awful.button({}, 1,
                            function ()
                               w:toggle_menu() end)))

   w.scanning = false
   w:update()
   return w
end
-- }}}

return setmetatable(ac, {__call = function(_, ...) return new(...) end})
-- }}}

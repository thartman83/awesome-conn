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
      print("Already scanning, please wait")
   else
      self.scanning = true
      awful.spawn.easy_async({ "connmanctl", "scan", "wifi" },
         function (so, se, er, ec)
            self.scanning = false
            if ec ~= 0 or se ~= "" then
               naught.notify({title = "Error Scanning for Wifi",
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
         table.insert(self._menu_tbl, { v.Name, self:build_connect_fn(v) })
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
   -- if self._menu.visible then
   --    self._menu:hide()
   --    self._menu.visible = false
   -- else
   --    self._menu.visible = true
   --    self._menu:show()
   -- end
end
-- }}}
   
--- new -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
local function new (...)
   local w        = wibox.layout.fixed.horizontal()
   w._props       = {}
   w._techs       = {}
   w._services    = {} 
   w._connIcon    = wibox.widget {image = nil,
                                  resize = false,
                                  widget = wibox.widget.imagebox}
   w._serviceInfo = wibox.widget {markup = 'placeholder',
                                  align = "center",
                                  valign = "center",
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

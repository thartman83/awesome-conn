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
local dp      = require('dbus_proxy' )
local wibox   = require('wibox'      )
local gtable  = require('gears.table')

local ac = {}
-- }}}

--- ac:OnMgrPropertyChanged -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
function ac:OnMgrPropertyChanged (proxy_obj, ...)
   print("Entered OnMgrPropertyChanged")
end
-- }}}

--- ac:OnMgrServicesChanged -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
function ac:OnMgrServicesChanged (proxy_obj, ...)
   print("Enetered OnMgrServicesChanged")
end
-- }}}

--- new -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
local function new (...)
   -- local obj = wibox.widget.base.empty_widget()
   local obj = wibox.widget.textbox("CONNMAN")
   
   gtable.crush(obj, ac, true)

   obj._connman_mgr = dp.Proxy:new( { bus       = dp.Bus.SYSTEM,
                                      name      = "net.connman",
                                      interface = "net.connman.Manager",
                                      path      = "/" })
   
   obj._connman_mgr:connect_signal(function (...) obj:OnMgrPropertyChanged(...) end,
                                   "PropertyChanged", nil)
   obj._connman_mgr:connect_signal(function (...) obj:OnMgrServicesChanged(...) end,
                                   "ServicesChanged", nil)
   return obj
end
-- }}}

return setmetatable(ac, {__call = function(_, ...) return new(...) end})
-- }}}

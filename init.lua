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
local dp        = require('dbus_proxy' )
local wibox     = require('wibox'      )
local gtable    = require('gears.table')
local ac        = {}
-- }}}

--- Table Helper Functions -- {{{

--- table.print -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
function table.print(t, level)
   local level = level or 0
   local pad   = ""
   for i=1,level do
      pad = pad .. "\t"
   end

   if type(t) == "string" then
      print(t)
      return 
   end
      
   for i,v in pairs(t) do
      if type(v) == "table" then
         print(pad .. tostring(i) .. " = ")
         table.print(v, level + 1)
      else
         print(pad .. tostring(i) .. " = " .. tostring(v))
      end
   end
end
-- }}}

-- }}}

--- enums -- {{{
local conn_state = { online = "online", idle = "idle", ready = "ready",
                     offline = "offline"}
-- }}}

--- ac:currentTechnology -- {{{
----------------------------------------------------------------------
-- Returns the current Technology in use. If there is only one
-- technology available it will return the name of that, if there are
-- mutliple it will prefer the one that has an active connection. If
-- no technologies are active it will prefer `powered' connections
-- over `unpowered' ones. If multiples of those exist it will prefer
-- whatever is first in the list of available technologies as provided
-- by connman. If no technologies are available this function will
-- return nil.
--
-- @return string, the object path of the current technology
----------------------------------------------------------------------
function ac:currentTech ()

   -- return nil if nothing is available
   if self._techs == nil then
      return nil
   end

   -- if only one technology is available return it
   local keys = gtable.keys(self._techs)
   if #keys == 1 then
      return keys[1]
   end

   -- return the first technology that is connected
   local retval = ""
   for _,k in ipairs(keys) do
      if self._techs[k].Connected == true then
         retval = k
      end
   end

   if retval ~= "" then
      return retval      
   end

   -- return the first technology that is powered
   for _,k in ipairs(keys) do
      if self._techs[k].Powered == true then
         retval = k
      end
   end

   if retval ~= "" then
      return retval
   end

   -- return the first technology
   return keys[1]
end
-- }}}
   
--- ac:updateDisplay -- {{{
----------------------------------------------------------------------
-- Update the display widget information
----------------------------------------------------------------------
function ac:updateDisplay ()
   local tech = ac:currentTech()

   self._serviceInfo.markup = self._props.State
end
-- }}}

--- ac:OnMgrPropertyChanged -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
function ac:OnMgrPropsChanged (_, prop, value)
   self._props[prop] = value

   print("Entering event OnMgrPropsChanged")
   table.print(self._props)

   self:updateDisplay()
end
-- }}}

--- ac:OnServicesChanged -- {{{
----------------------------------------------------------------------
-- Update the list of currently available services in connman
--
-- @param proxy dbus_proxy object
-- @param newServices Array of string and table tuples, providing the
-- object path and properties of each new service. The properties
-- table may only contain a list of new or changed properties
-- @param oldServices Array of object paths of services that are no longer
-- available
-- return nothing
----------------------------------------------------------------------
function ac:OnServicesChanged (_, newServices, oldServices)
   for _, service in ipairs(newServices) do
      if self._services[service[1]] ~= nil then
         gtable.crush(self._services[service[1]], service[2], true)
      else
         self._services[service[1]] = service[2]
      end      
   end

   for _, service in ipairs(oldServices) do
      self._services[service] = nil
   end

   self:updateDisplay()
end
-- }}}

--- ac:OnTechAdded -- {{{
----------------------------------------------------------------------
-- Add a technology to the list of available technologies in connman
--
-- @param objpath, the name of the technology's object path in dbus
-- @param props, table of properties of the new technology
-- @return nothing
----------------------------------------------------------------------
function ac:OnTechAdded (_, objpath, props)
   self._techs[objpath] = props

   self:updateDisplay()
end
-- }}}

--- ac:OnTechRemoved -- {{{
----------------------------------------------------------------------
-- Remove a technology from the list of available technologies in connman
--
-- @param objpath, the name of the technology's object path to be removed
-- @return nothing
----------------------------------------------------------------------
function ac:OnTechRemoved (_, objpath)
   self._techs[objpath] = nil

   self:updateDisplay()
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

   w._connMgr = dp.Proxy:new( { bus       = dp.Bus.SYSTEM,
                                name      = "net.connman",
                                interface = "net.connman.Manager",
                                path      = "/" })

   table.print(w._connMgr:GetTechnologies())

   -- connect to dbus signals
   w._connMgr:connect_signal(function (...) w:OnMgrPropsChanged(...) end,
      "PropertyChanged", nil)
   w._connMgr:connect_signal(function (...) w:OnServicesChanged(...) end,
      "ServicesChanged", nil)
   w._connMgr:connect_signal(function (...) w:OnTechAdded(...)       end,
      "TechnologyAdded", nil)
   w._connMgr:connect_signal(function (...) w:OnTechRemoved(...)     end,
      "TechnologyRemoved", nil)


   -- Initialize Technologies
   local techs = w._connMgr:GetTechnologies()
   for _, v in ipairs(techs) do
      w._techs[v[1]] = v[2]
   end


   -- Initialize Manager Properties
   w._props = w._connMgr:GetProperties()

   -- Initialize the display
   w:updateDisplay()
   return w
end
-- }}}

return setmetatable(ac, {__call = function(_, ...) return new(...) end})
-- }}}

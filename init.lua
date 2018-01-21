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
-- awesome-conn is a pure lua widget to interact with connman from
-- within awesome
-- }}}

--- awesome-conn  -- {{{
local wibox = require('wibox'       )
local awful = require('awful'       )
local s     = require('gears.string')

local capi           = {timer=timer}
local techs          = {}
local display        = ""
local scanning       = nil
local connmanctl_cmd = "/usr/bin/connmanctl"
local err_msg        = ""

--- s.trim -- {{{
----------------------------------------------------------------------
-- Helper string function to remove whitespace from beginning and end
-- of a string
----------------------------------------------------------------------
s.trim = function (s)
   return (s:gsub("^%s*(.-)%s*$","%1"))
end
-- }}}


--- processTechs -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
local function processTechs (stdout, stderr, exitreason, exitcode)   
   
   -- connmanctl doesn't return a positive error code if it fails to
   -- find the connman service but it does dump to stderr
   if stderr ~= "" then
      err_msg = "Unable to connect to connman"
      return
   end

   techs = {}
   -- loop over technologies
   for i,v in ipairs(s.split("",stdout)) do
      techs[i] = {}
      lines = split("\n",v)
      
   end
end
-- }}}

--- updateTechs -- {{{
----------------------------------------------------------------------
-- Updates the `techs' table with the values from connmanctl
----------------------------------------------------------------------
local function updateTechs ()
   -- There are 5 network types recognized by connman
   --  - ethernet
   --  - gadget
   --  - wifi
   --  - bluetooth
   --  - cellular
   awful.spawn.easy_async("/usr/bin/connmanctl technologies",
                          function(stdout,stderr,exitreason,exitcode)
                             techs = {}
                             local t = s.split("",stdout)                             
                             for i,v in ipairs(t) do
                                techs[i] = {}
                                
                             end
                             -- finally after the techs have been
                             -- updated, run the updateServices to
                             -- grab any wifi/bt information
                             updateServices()
   end)
end
-- }}}

--- update -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
local function update (w)
   awful.spawn.easy_async(connmanctl_cmd .. "technologies"
end
-- }}}

--- new -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
local function new (args)
   local args = args or {}
   local w = wibox.widget.textbox()

   local t = capi.timer({timeout=5})
   t:connect_signal("timeout",function() update(w) end)
   t:start()
   update(w)
   
   return w
end
-- }}}

return setmetatable({}, { __call = function(_, ...) return new(...) end })
-- }}}

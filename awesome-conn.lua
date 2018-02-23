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
local wibox     = require('wibox'       )
local awful     = require('awful'       )
local s         = require('gears.string')
local gtable    = require('gears.table' )
local radical   = require('radical'     )
local beautiful = require('beautiful'   )
local capi      = {timer=timer          }

local dbg       = require('debugger'    )

beautiful.init()

--- Variable definitions -- {{{
local home_path = '/home/' .. os.getenv('USER')
local awesome_path = home_path .. '/.config/awesome/'

-- Themes define colours, icons, font and wallpapers.
beautiful.init(awesome_path .. 'theme.lua')

--}}}

--- String Helper Functions -- {{{

--- s.trim -- {{{
----------------------------------------------------------------------
-- Helper string function to remove whitespace from beginning and end
-- of a string
----------------------------------------------------------------------
function s.trim (str)
   return (str:gsub("^%s*(.-)%s*$","%1"))
end
-- }}}

--- s.lines -- {{{
----------------------------------------------------------------------
-- Split a string into a table of lines
----------------------------------------------------------------------
function s.lines (str)
   local t = {}
   local function helper(line) table.insert(t, line) return "" end
   helper((str:gsub("(.-)\r?\n", helper)))
   return t
end
-- }}}

--- s.split -- {{{
----------------------------------------------------------------------
-- Split a string by delimiter
----------------------------------------------------------------------
function s.split (str, delim)
   if str == nil then return {} end

   local t = {}
   local function helper(part) table.insert(t, part) return "" end   
   helper((str:gsub("(.-)" .. delim, helper)))

   return t
end

-- }}}

--- s.join -- {{{
----------------------------------------------------------------------
-- Join the values in table t into a single string
----------------------------------------------------------------------
function s.join (t, sep)
   local sep = sep or ''
   local retval

   for i,v in ipairs(t) do
      if i == 1 then
         retval = v
      else
         retval = retval .. sep .. v
      end
   end
   return retval
end
-- }}}

-- }}}

--- Table Helper Functions -- {{{

--- gtable.noblanks -- {{{
----------------------------------------------------------------------
-- Return a new table with no blanks in it. If nowhitespaces is set to
-- true also remove any entries that are all whitespaces.
----------------------------------------------------------------------
function gtable.noblanks (t, nowhitespaces)
   local retval = {}   
   for k,v in pairs(t) do
      if v ~= "" and v ~= nil then
         if not nowhitespaces or not (v == v:match("(%s*)")) then
            if type(k) == "number" then
               table.insert(retval,v)
            else
               retval[k] = v
            end
         end
      end
   end
   return retval
end
-- }}}

--- gtable.keys -- {{{
----------------------------------------------------------------------
-- Return an array of the keys in a table
----------------------------------------------------------------------
function gtable.keys (t)
   local retval = {}
   for k,v in pairs(t) do
      table.insert(retval, k)
   end
   return retval
end
-- }}}

-- }}}

--- semaphore Functions -- {{{

local semaphore = { }
semaphore.__index = semaphore

setmetatable(semaphore, { __call = function (s, ...) return s.new(...) end, })

function semaphore.new()
   local obj = setmetatable({}, semaphore)
   obj.count = 0
   return obj
end

function semaphore:increment(n)
   local n = n or 1
   self.count = self.count + n
end

function semaphore:decrement()
   self.count = self.count - 1
end

function semaphore:isFree()
   return self.count == 0
end

function semaphore:clear()
   self.count = 0
end

-- }}}

--- constructor -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
local ac = {}
ac.__index = ac
setmetatable(ac, {__call = function (a, ...) return ac.new(...) end })

function ac.new (args)
   local args = args or {}
   local connmanctl_cmd = args.connmanctl_cmd or "/usr/bin/connmanctl"
   local obj            = setmetatable({}, ac)
   
   obj.w                = wibox.widget.textbox("CONNMAN")
   obj.services         = {}
   obj.connmanctl_cmd   = connmanctl_cmd
   obj.updateCount      = semaphore.new()

   obj:update()
   return obj
end
-- }}}

--- enums -- {{{
ac.TechType = { ethernet = "ethernet", wifi = "wifi", tether = "tether",
                cellular = "cellular", gadget = "gadget" }
-- }}}

--- Services Accessors -- {{{
-- Functions to get service information from the properties returned from connmanctl

--- ac:getTechType -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
function ac:getServiceTechType (serviceName)
   local serviceTbl = self.services[serviceName]

   if serviceTbl == nil then
      return
   end

   return ac.TechType[serviceTbl.props.Type]
end
-- }}}

--- ac:getTechTypes -- {{{
----------------------------------------------------------------------
-- Return a list of tech types available given the list of current services
----------------------------------------------------------------------
function ac:getTechTypes ()
   local retval = {}
   local temp   = {}
   
   for k,_ in self.services do
      temp[k] = true
   end

   for _,v in temp do
      retval.insert(v)
   end

   return retval
end
-- }}}

--- ac:getServiceByTechType -- {{{
----------------------------------------------------------------------
-- Return a list of services based on a certain tech type
----------------------------------------------------------------------
function ac:getServiceByTechType (techType)
   local retval = {}

   for _,v in self.services do
      if v.props.Type == techType then
         retval.insert(v)
      end
   end

   return retval
end
-- }}}

-- }}}

--- connmanctlParseServicesList -- {{{c
----------------------------------------------------------------------
-- Parse the list of servers grouping by technology
--
-- Parse the output of `connmanctl services' into a table with keys
-- for each available device and sub tables of each available service
-- to that device.
--
-- eg: { ethernet_080027606158 -> {
--                                  {
--                                    name -> Wired,
--                                    ServiceName -> ethernet_080027606158_cable
--                                  }
--                                },
--       wifi_dc85de828967 ->     {
--                                  {
--                                    name -> WifiNetwork,
--                                    ServiceName -> wifi_dc85de828967_38303944616e69656c73_managed_psk
--                                  },
--                                  {
--                                    name -> OtherWifiNetwork,
--                                    ServiceName -> wifi_dc85de828967_32574952453638367_managed_wep
--                                  }
--                                }
--     }
----------------------------------------------------------------------
function ac:connmanctlParseServicesList (services_list)
   local retval = {}
   
   local lines = gtable.noblanks(s.lines(services_list))
   for _, line in ipairs(lines) do            
      local parts = gtable.noblanks(s.split(line, " "))
      local serviceName = parts[#parts == 3 and 3 or 2]

      retval[serviceName] = {} 
   end

   return retval
end
-- }}}

--- connmanctlParseService -- {{{
----------------------------------------------------------------------
-- Parse connman information from an individual service
--
-- Parse the output of `connmanctl services [servicename]' into a
-- table with kv pairs for each service property.
----------------------------------------------------------------------
function ac:connmanctlParseService (service)
   local retval = {}
   local lines = gtable.noblanks(s.lines(service))
   
   local service_path = table.remove(lines,1)
   retval["servicepath"] = service_path

   for _, line in ipairs(lines) do
      local parts = s.split(line, "=")
      local key   = s.trim(table.remove(parts,1))
      local val   = (#parts == 1 and s.trim(parts[1]) or
                        s.trim(s.join(parts,"=")))

      if val == "True" or val == "False" then
         retval[key] = val == "True"
      elseif val:sub(1,1) == "[" then
         retval[key] = {}
         local subparts = gtable.noblanks(s.split(val:sub(2,-2),","), true)
         for _,subpart in ipairs(subparts) do
            local subsubparts = s.split(subpart,"=")

            if #subsubparts == 1 then
               table.insert(retval[key],s.trim(subpart))
            else
               local subkey = s.trim(subsubparts[1])
               local subval = s.trim(subsubparts[2])
               retval[key][subkey] = subval
            end
         end
      else
         retval[key] = val
      end         
   end

   return retval
end
-- }}}

--- serviceCount -- {{{
----------------------------------------------------------------------
-- Return the number of services listed in the service table
----------------------------------------------------------------------
function ac:serviceCount ()
   local retval = 0
   for _, t in pairs(self.services) do
      retval = retval + #t
   end
   return retval
end
-- }}}

--- update -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
function ac:update ()   
   self.updateCount:clear()
   awful.spawn.easy_async(self.connmanctl_cmd .. " services",
        function (stdout, stderr, exitreason, exitcode)           
           if stderr ~= "" then
              naughty.notify("An error occured while contacting connman: " .. stderr)
              return
           end

           self.services = self:connmanctlParseServicesList(stdout)
           self.updateCount:increment(#gtable.keys(self.services))
           
           
           -- Loop over each service in the service table
           for serviceName, s_tbl in pairs(self.services) do
              awful.spawn.easy_async(self.connmanctl_cmd .. " services " ..
                                        serviceName,
                 function (stdout, stderr, exitreason, exitcode)
                    if stderr ~= "" then
                       naughty.notify("An error occured while contacting connman: " .. stderr)
                    else
                       s_tbl.props = self:connmanctlParseService(stdout)
                    end
                    
                    self.updateCount:decrement()
                    
                    if self.updateCount:isFree() then
                       self:updateMenu()
                    end
              end)
           end
   end)
end
-- }}}

--- updateMenu -- {{{
----------------------------------------------------------------------
-- Update the awesome-conn menu
----------------------------------------------------------------------
function ac:updateMenu ()
   local m         = radical.context{ style = beautiful.radical.menu.style or
                                         radical.style.classic }
         
   self.w:set_menu(m, "button::pressed", 1)
end
-- }}}

return ac
-- }}}

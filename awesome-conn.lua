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
-- local wibox = require('wibox'       )
-- local awful = require('awful'       )
local s      = require('gears.string')
local gtable = require('gears.table' )

local capi           = {timer=timer}

local techs          = {}
local display        = ""
local scanning       = nil
local connmanctl_cmd = "/usr/bin/connmanctl"
local err_msg        = ""

--- String Helper Functions -- {{{

--- s.trim -- {{{
----------------------------------------------------------------------
-- Helper string function to remove whitespace from beginning and end
-- of a string
----------------------------------------------------------------------
function s.trim (s)
   return (s:gsub("^%s*(.-)%s*$","%1"))
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
-- Return a new table with no blanks in it
----------------------------------------------------------------------
function gtable.noblanks (t)
   local retval = {}
   for k,v in pairs(t) do
      if v ~= "" and v ~= nil then
         if type(k) == "number" then
            table.insert(retval,v)
         else
            retval[k] = v
         end
      end
   end
   return retval
end
-- }}}

-- }}}

--- connmanctl parsing functions -- {{{
-- A set of functions to parse the output from connmanctl into lua tables

--- connmanctl_parse_technologies -- {{{
----------------------------------------------------------------------
-- Parse the list of technologies from connman
-- There are 5 network types recognized by connman
--  - ethernet
--  - gadget
--  - wifi
--  - bluetooth
--  - cellular
----------------------------------------------------------------------
local function connmanctl_parse_technologies (technologies)
   local lines = s.lines(technologies)

   -- Pop the first line
   table.remove(lines,1)

   local t = {}
   t[1] = {}
   
   for i,line in ipairs(lines) do
      local kvpair = s.split(line, "=")
      if #kvpair == 2 then 
         local key   = s.trim(kvpair[1])
         local value = s.trim(kvpair[2])                          
         
         if value == "True" then
            t[1][key] = true
         elseif value == "False" then
            t[1][key] = false
         else
            t[1][key] = value
         end

      end
   end
   
   return t
end
-- }}}

--- connmanctl_parse_services_list -- {{{
----------------------------------------------------------------------
-- Parse the list of servers grouping by technology
----------------------------------------------------------------------
local function connmanctl_parse_services_list (services_list)
   local retval = {}
   
   local lines = gtable.noblanks(s.lines(services_list))
   for _, line in ipairs(lines) do            
      local parts = gtable.noblanks(s.split(line, " "))

      local common_name, service_name

      common_name  = parts[#parts == 2 and 1 or 2]
      service_name = parts[#parts == 3 and 3 or 2]

      local service_name_parts = s.split(service_name, "_")
      local tech_name          = table.remove(service_name_parts,1) .. "_" ..
         table.remove(service_name_parts,1)
      
      if retval[tech_name] == nil then
         retval[tech_name] = {}
      end

      table.insert(retval[tech_name],
                   { Name = common_name,
                     ServiceName = s.join(service_name_parts, "_") })

   end

   return retval
end
-- }}}

--- connmanctl_parse_service -- {{{
----------------------------------------------------------------------
-- Parse connman information from an individual service
----------------------------------------------------------------------
local function connmanctl_parse_service (service)
   local retval = {}
   local lines = gtable.noblanks(s.lines(service))

   local service_path = table.remove(lines,1)
   retval["servicepath"] = service_path

   for _, line in ipairs(lines) do
      local parts = s.split(line, "=")
      local key   = s.trim(parts[1])
      local val   = s.trim(parts[2])

      if val == "True" or val == "False" then
         retval[key] = val == "True"
      elseif val:sub(1,1) == "[" then
         retval[key] = {}
         local subparts = s.split(val:sub(2,-2),",")
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

-- }}}

--- update -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
local function update (w)

end
-- }}}

--- new -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
local function new (args)
   local w = {}
   w.connmanctl_parse_technologies = connmanctl_parse_technologies
   w.connmanctl_parse_services_list = connmanctl_parse_services_list
   w.connmanctl_parse_service = connmanctl_parse_service
   return w
end
-- }}}

return setmetatable({}, { __call = function(_, ...) return new(...) end })
-- }}}

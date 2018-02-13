-------------------------------------------------------------------------------
-- spawn.lua for awful.spawn mocks                                           --
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
-- Awful Spawn mocks
-- }}}

--- Spawn -- {{{
local response_tbl = { services =
                          { [[*AO Wired                ethernet_080027606158_cable
*AR Wired                ethernet_0800270ed8db_cable]],
                             ethernet_080027606158_cable = { [[/net/connman/service/ethernet_080027606158_cable
  Type = ethernet
  Security = [  ]
  State = online
  Favorite = True
  Immutable = False
  AutoConnect = True
  Name = Wired
  Ethernet = [ Method=auto, Interface=enp0s3, Address=08:00:27:60:61:58, MTU=1500 ]
  IPv4 = [ Method=dhcp, Address=10.0.2.15, Netmask=255.255.255.0, Gateway=10.0.2.2 ]
  IPv4.Configuration = [ Method=dhcp ]
  IPv6 = [  ]
  IPv6.Configuration = [ Method=auto, Privacy=disabled ]
  Nameservers = [ 192.168.32.102, 192.168.24.132 ]
  Nameservers.Configuration = [  ]
  Timeservers = [ 10.0.2.2 ]
  Timeservers.Configuration = [  ]
  Domains = [ hudco.com ]
  Domains.Configuration = [  ]
  Proxy = [ Method=direct ]
  Proxy.Configuration = [  ]
  Provider = [  ] ]] },
                             ethernet_0800270ed8db_cable = { [[/net/connman/service/ethernet_0800270ed8db_cable
  Type = ethernet
  Security = [  ]
  State = ready
  Favorite = True
  Immutable = False
  AutoConnect = True
  Name = Wired
  Ethernet = [ Method=auto, Interface=enp0s8, Address=08:00:27:0E:D8:DB, MTU=1500 ]
  IPv4 = [ Method=dhcp, Address=10.0.3.15, Netmask=255.255.255.0 ]
  IPv4.Configuration = [ Method=dhcp ]
  IPv6 = [  ]
  IPv6.Configuration = [ Method=auto, Privacy=disabled ]
  Nameservers = [ 192.168.32.102, 192.168.24.132 ]
  Nameservers.Configuration = [  ]
  Timeservers = [ 10.0.3.2 ]
  Timeservers.Configuration = [  ]
  Domains = [ hudco.com ]
  Domains.Configuration = [  ]
  Proxy = [ Method=direct ]
  Proxy.Configuration = [  ]
  Provider = [  ] ]]}
                             
                          
                          }
}

--- FunctionDescription -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
local function split (str, delim)
   if str == nil then return {} end

   local t = {}
   local function helper(part) table.insert(t, part) return "" end   
   helper((str:gsub("(.-)" .. delim, helper)))

   return t
end
-- }}}

--- easy_sync_fn -- {{{
----------------------------------------------------------------------
-- Calls `callback_fn' with response data based on the connmanctl
-- input. Currently only understands `services'
----------------------------------------------------------------------
function easy_async (cmdstr, callback_fn)
   local parts = split(cmdstr, " ")
   local prog  = table.remove(parts,1)

   if prog ~= "/usr/bin/connmanctl" then
      error("This mock object doesn't understand the command `" .. prog "'")
   end

   local cur_tbl = response_tbl
   for _, k in ipairs(parts) do
      if cur_tbl[k] == nil then
         error("Unknown response key `" .. k .. "'")
      end

      cur_tbl = cur_tbl[k]
   end

   callback_fn(cur_tbl[1], "", "", 0)
end
-- }}}

local spawn = { easy_async = easy_async }

return spawn
-- }}}

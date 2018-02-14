-------------------------------------------------------------------------------
-- awesome-conn-tests.lua for awesome-conn                                   --
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
-- Unit and functional tests for awesome-conn
-- }}}

--- awesome-conn tests -- {{{
require 'busted.runner'()
package.path = 'mocks/?.lua;mocks/?/init.lua;./?.lua;' .. package.path

--- Helper functions -- {{{

--- freadall -- {{{
----------------------------------------------------------------------
-- Returns the contents of a file as a string
----------------------------------------------------------------------
local function freadall (filename)
   local f = assert(io.open(filename, "rb"))
   local content = f:read("*all")
   f:close()
   return content
end
-- }}}

--- keys -- {{{
----------------------------------------------------------------------
-- Return a array of keys
----------------------------------------------------------------------
function keys (t)
   local retval = {}
   for k,v in pairs(t) do
      table.insert(retval, k)
   end
   return retval
end
-- }}}

-- }}}

--- connmanctl parser tests -- {{{
describe("a set of tests for connmanctl output parsing", function ()

  -- connmanctl_parse_technologies -- {{{
  describe("tests for parsing technology output", function ()
    it("should return a table with a single entry describing an ethernet port",
       function ()
          local awesome_conn = require('awesome-conn')()
          local txt          = freadall("test-output/tech_eth_only.txt")
          local t            = awesome_conn:connmanctl_parse_technologies(txt)

          assert.are.equal(1, #t)
          assert.are.equal("Wired"    , t[1]["Name"    ])
          assert.are.equal("ethernet" , t[1]["Type"    ])
          
          assert.is_true  (t[1]["Powered"   ])
          assert.is_true  (t[1]["Connected" ])
          assert.is_false (t[1]["Tethering" ])
    end)
  end)
  -- }}}

  --- connmanctl_parse_services_list -- {{{
  describe("tests for parsing service list output", function ()
    it("should return a tbl w/ all of the services organized by techology name",
       function ()
          local awesome_conn = require('awesome-conn')()
          local txt          = freadall("test-output/services-list.txt")
          local t            = awesome_conn:connmanctl_parse_services_list(txt)

          assert.are.equal(2, #keys(t)                   )
          assert.are.equal(1, #t["ethernet_080027606158"])
          assert.are.equal(4, #t["wifi_dc85de828967"    ])

          assert.are.equal("Wired", t["ethernet_080027606158"][1]["Name"])
          assert.are.equal("ethernet_080027606158_cable",
                           t["ethernet_080027606158"][1]["ServiceName"])

          assert.are.equal("OtherNET"     , t["wifi_dc85de828967"][1]["Name"])
          assert.are.equal("AnotherOne"   , t["wifi_dc85de828967"][2]["Name"])
          assert.are.equal("FourthNetwork", t["wifi_dc85de828967"][3]["Name"])
          assert.are.equal("AnOpenNetwork", t["wifi_dc85de828967"][4]["Name"])
          
          assert.are.equal("wifi_dc85de828967_38303944616e69656c73_managed_psk",
                           t["wifi_dc85de828967"][1]["ServiceName"])
          assert.are.equal("wifi_dc85de828967_3257495245363836_managed_wep",
                           t["wifi_dc85de828967"][2]["ServiceName"])
          assert.are.equal("wifi_dc85de828967_4d7572706879_managed_wep",
                           t["wifi_dc85de828967"][3]["ServiceName"])
          assert.are.equal("wifi_dc85de828967_4d6568657272696e_managed_none",
                           t["wifi_dc85de828967"][4]["ServiceName"])
    end)
  end)
  -- }}}

  --- connmanctl_parse_service -- {{{
  describe("test for parsing service information", function ()
    it("should return a tbl w/ information about an eth service", function ()
          local awesome_conn = require('awesome-conn'    )()
          local txt          = freadall('test-output/services-output.txt')
          local t            = awesome_conn:connmanctl_parse_service(txt)

          assert.are.equal(22, #keys(t))
          assert.are.equal("/net/connman/service/ethernet_080027606158_cable",
                           t["servicepath"])
          assert.are.equal("ethernet",t["Type"])
          assert.are.equal(0,#keys(t["Security"]))
          assert.are.equal(State,t["ready"])
          assert.is_true(t["Favorite"])
          assert.is_false(t["Immutable"])
          assert.is_true(t["AutoConnect"])
          assert.are.equal("Wired",t["Name"])

          assert.are.equal(4                  ,#keys(t["Ethernet"        ]))
          assert.are.equal("auto"             , t["Ethernet"]["Method"   ] )
          assert.are.equal("enp0s3"           , t["Ethernet"]["Interface"] )
          assert.are.equal("08:00:27:60:61:58", t["Ethernet"]["Address"  ] )
          assert.are.equal("1500"             , t["Ethernet"]["MTU"      ] )

          assert.are.equal(4              ,#keys(t["IPv4"      ]))
          assert.are.equal("dhcp"         , t["IPv4"]["Method" ] )
          assert.are.equal("10.0.2.15"    , t["IPv4"]["Address"] )
          assert.are.equal("255.255.255.0", t["IPv4"]["Netmask"] )
          assert.are.equal("10.0.2.2"     , t["IPv4"]["Gateway"] )

          assert.are.equal(1     ,#keys(t["IPv4.Configuration"     ]))
          assert.are.equal("dhcp", t["IPv4.Configuration"]["Method"] )

          assert.are.equal(0, #keys(t["IPv6"]))
          
          assert.are.equal(2         ,#keys(t["IPv6.Configuration"      ]))
          assert.are.equal("auto"    , t["IPv6.Configuration"]["Method" ] )
          assert.are.equal("disabled", t["IPv6.Configuration"]["Privacy"] )
                           
          assert.are.equal(2               ,#keys(t["Nameservers"]))
          assert.are.equal("192.168.32.102", t["Nameservers"][1]   )
          assert.are.equal("192.168.24.132", t["Nameservers"][2]   )

          assert.are.equal(0, #keys(t["Nameservers.Configuration"]))
          
          assert.are.equal(1         , #keys(t["Timeservers"]))
          assert.are.equal("10.0.2.2", t["Timeservers"][1]    )
          
          assert.are.equal(0, #keys(t["Timeservers.Configuration"]))

          assert.are.equal(1           ,#keys(t["Domains"]))
          assert.are.equal("domain.com", t["Domains"][1]   )

          assert.are.equal(0, #keys(t["Domains.Configuration"]))

          assert.are.equal(1       , #keys(t["Proxy"])   )
          assert.are.equal("direct", t["Proxy"]["Method"])

          assert.are.equal(0, #keys(t["Proxy.Configuration"]))
          assert.are.equal(0, #keys(t["Provider"]))
    end)
  end)
  -- }}}
end)

-- }}}

--- awesome-conn update tests -- {{{
describe("a suite of tests for the awesome-conn:update method", function()
  it("should cycle through .", function ()
        local awesome_conn = require('awesome-conn')()
        spy.on(awesome_conn, "updateMenu")
        
        awesome_conn:update()
        assert.are.equal(2,awesome_conn:serviceCount())
        assert.spy(awesome_conn.updateMenu).was_called()
        assert.is_true(awesome_conn.updateCount:isFree())
  end)
end)
-- }}}
-- }}}

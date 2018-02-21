-------------------------------------------------------------------------------
-- init.lua for Beautiful Mocks                                              --
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
-- Beautiful mocks
-- }}}

--- Beautiful Mocks -- {{{

local beautiful = {}

function beautiful.init(themepath)
   beautiful.radical                   = {}
   beautiful.radical.menu              = {}
   beautiful.radical.style             = nil
   beautiful.radical.menu.margin_left  = 10
   beautiful.radical.menu.margin_right = 10
   
   beautiful.connman                   = {}
   beautiful.connman.icons             = {}
   beautiful.connman.icons.ethernet    = "ethernet.png"
end

return beautiful

-- }}}

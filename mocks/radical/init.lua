-------------------------------------------------------------------------------
-- init.lua for radical mocks                                                --
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
-- radical mocks
-- }}}

local dbg = require ('debugger')

--- radical -- {{{
local menu = {}
menu.__index = menu

--- menu:add_item -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
function menu:add_item (...)
   
end
-- }}}

function menu.newmenu (...)
   local obj = setmetatable({}, menu)
   return obj
end

local function context (...)
   return menu.newmenu(...)
end

return { context = context }
-- }}}

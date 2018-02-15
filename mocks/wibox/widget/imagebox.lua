-------------------------------------------------------------------------------
-- imagebox.lua for wibox.widget.imagebox mocks                              --
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
-- wibox.widget.imagebox mocks
-- }}}

--- wibox.widget.imagebox -- {{{
local imgbox = {}
imgbox.__index = imgbox

setmetatable(imgbox, { __call = function (c, ...) return imgbox.new() end })

function imgbox.new (...)
   local obj = setmetatable({}, imgbox)
   return obj
end

function imgbox:set_menu(...)
end

return imgbox
-- }}}

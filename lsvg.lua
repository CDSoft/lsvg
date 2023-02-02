#!/usr/bin/env luax

--[[
This file is part of lsvg.

lsvg is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

lsvg is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with lsvg.  If not, see <https://www.gnu.org/licenses/>.

For further information about lsvg you can visit
http://cdelord.fr/lsvg
--]]

local usage = [[
lsvg <Lua scripts> <output files>

<Lua scripts>
    Lua script using the svg module
    to build an SVG image in a global variable (img)

<output files>
    Output file names where the image is saved
    (SVG or PNG)
]]

local F = require "fun"
local fs = require "fs"
local svg = require "svg".open()

-- The Lua script shall use the global variable `img` to describe the SVG image
_ENV.img = svg()

local n = 0
F(arg):map(function(a)
    local _, ext = fs.splitext(a)
    if ext == ".lua" then
        n = n + 1
        assert(loadfile(a))()
    elseif ext == ".svg" or ext == ".png" then
        if not _ENV.img:save(a) then
            io.stderr:write(arg[0], ": can not save ", a, "\n")
            os.exit(1)
        end
    else
        io.stderr:write("Invalid argument: ", a, "\n")
        io.stderr:write(usage)
        os.exit(1)
    end
end)

-- Nothing done, prints some help
if n == 0 then
    print(usage)
end

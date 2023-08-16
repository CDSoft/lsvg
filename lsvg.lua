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
lsvg <Lua scripts> <output files> [-- <other args>]

<Lua scripts>
    Lua script using the svg module
    to build an SVG image in a global variable (img)

<output files>
    Output file names where the image is saved
    (SVG, PNG or PDF)

<other args>
    Arguments given to the input Lua scripts
    through the arg global variable

For further information, please visit http://cdelord.fr/lsvg
]]

local F = require "F"
local fs = require "fs"
local svg = require "svg".open()

-- The Lua script shall use the global variable `img` to describe the SVG image
_ENV.img = svg()

local inputs = F{}
local outputs = F{}

for i = 1, #arg do
    local _, ext = fs.splitext(arg[i])
    if ext == ".lua" then
        inputs[#inputs+1] = arg[i]
    elseif ext == ".svg" or ext == ".png" or ext == ".pdf" then
        outputs[#outputs+1] = arg[i]
    elseif arg[i] == "--" then
        arg = F.drop(i, arg)
        break
    else
        io.stderr:write("Invalid argument: ", arg[i], "\n")
        io.stderr:write(usage)
        os.exit(1)
    end
end

if #inputs == 0 then
    print(usage)
    os.exit(0)
end

inputs:foreach(function(name)
    assert(loadfile(name))()
end)

outputs:foreach(function(name)
    if not _ENV.img:save(name) then
        io.stderr:write(arg[0], ": can not save ", name, "\n")
        os.exit(1)
    end
end)

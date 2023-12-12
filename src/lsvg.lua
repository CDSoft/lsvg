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

local F = require "F"
local fs = require "fs"

local version = require "version"

local function parse_args()
    local parser = require "argparse"()
        : name "lsvg"
        : description(F.unlines {
            "SVG generator scriptable in LuaX",
            "",
            "Arguments after \"--\" are given to the input scripts",
        } : rtrim())
        : epilog "For more information, see https://github.com/CDSoft/lsvg"

    parser : flag "-v"
        : description(('Print Bang version ("%s")'):format(version))
        : action(function() print(version); os.exit() end)

    parser : option "-o"
        : description "Output file name (SVG, PNG or PDF)"
        : argname "output"
        : target "output"

    parser : argument "input"
        : description "Lua script using the svg module to build an SVG image"
        : args "+"

    local lsvg_arg, script_arg = F.break_(F.partial(F.op.eq, "--"), arg)
    local args = parser:parse(lsvg_arg)
    _G.arg = script_arg:drop(1)

    return args
end

local args = parse_args()

local svg = require "svg".open()

-- The Lua script shall use the global variable `img` to describe the SVG image
_ENV.img = svg()

F.foreach(args.input, function(name)
    _G.arg[0] = name
    assert(loadfile(name))()
end)

if args.output then
    local name = args.output
    if not _ENV.img:save(name) then
        io.stderr:write(arg[0], ": can not save ", name, "\n")
        os.exit(1)
    end
end

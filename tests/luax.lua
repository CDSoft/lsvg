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

img {
    width = 1024,
    height = 1024,
    font_size=1024/4, text_anchor="middle",
}

local orbit_width = 20
local r_orbit = 512-orbit_width
local r_planet = 384-10
local r_moon = r_planet / 4 + 20

img:Circle {
    cx = 512, cy = 512, r = r_orbit,
    fill = "transparent",
    stroke = "grey", stroke_width = orbit_width, stroke_dasharray = 50
}
img:Circle { cx = 512, cy = 512, r = r_planet, fill = "blue" }
local x0 = 512 + r_planet/2^0.5
local y0 = 512 - r_planet/2^0.5
local x1 = 512 + (r_orbit+44)/2^0.5
local y1 = 512 - (r_orbit+44)/2^0.5
local x2 = x0 - (x1-x0)
local y2 = y0 - (y1-y0)
img:Circle { cx = x1, cy = y1, r = r_moon, fill = "blue" }
img:Circle { cx = x2, cy = y2, r = r_moon, fill = "white" }

img:Text "LuaX" { x = 512, y = 512+192, fill = "white" }

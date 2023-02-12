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
    font_size=1024//4, text_anchor="middle",
}

local w = img.attrs.width
local h = img.attrs.height
local fh = img.attrs.font_size

local orbit_width = 20
local r_orbit = w//2-orbit_width
local r_planet = 384-20
local r_moon = r_planet // 4 + 22

local g = img:G {
    transform = ("translate(%d, %d)"):format(w//2, h//2),
}

g:Circle {
    r = r_orbit,
    fill = "white", opacity = 1.0,
    stroke = "grey", stroke_width = orbit_width, stroke_dasharray = 60,
    transform = "rotate(-3)",
}
g:Circle { r = r_planet, fill = "blue" }
local x0 = math.floor( r_planet/2^0.5)
local y0 = math.floor(-r_planet/2^0.5)
local x1 = math.floor( (r_orbit+44)/2^0.5)
local y1 = math.floor(-(r_orbit+44)/2^0.5)
local x2 = x0 - (x1-x0)
local y2 = y0 - (y1-y0)
g:Circle { cx = x1, cy = y1, r = r_moon, fill = "blue" }
g:Circle { cx = x2, cy = y2, r = r_moon, fill = "white" }

g:Text "Lua" { y = fh*3//4, fill = "white" }
g:Text "X" { x = x1, y = y1+fh*1//8, fill = "white", font_size = fh//2 }
g:Text "X" { x = x2, y = y2+fh*1//8, fill = "blue", font_size = fh//2 }

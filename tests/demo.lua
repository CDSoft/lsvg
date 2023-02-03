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

-- The global variable `img` is an SVG object used by lsvg to produce the images
img {
    -- img can be called to add more attributes
    width = 320,
    height = 240,
}

local w = img.attrs.width
local h = img.attrs.height

img {font_size=w/8, text_anchor="middle", fill="green"}

-- G defines a group that will later be added to the main image object (img)
local flag = G {
    Rect {x=0*w/3, y=0, width=w/3, height=h, fill="blue"},
    Rect {x=1*w/3, y=0, width=w/3, height=h, fill="white"},
    Rect {x=2*w/3, y=0, width=w/3, height=h, fill="red"},
}

-- another group
local title = G {
    Rect {
        x=w/6, y=h/6, width=4*w/6, height=4*h/6,
        rx=w/16,
        fill="grey", fill_opacity=0.4,
        stroke="cyan", stroke_width=w/32, stroke_opacity=0.4
    },
    -- Text given on the command line
    Text(arg[1]) {x = w/2, y = h/2-w/8/2},
    Text(arg[2]) {x = w/2, y = h/2+w/8/2},
}

-- the final image
img {
    flag,
    title,
}

-- no need to generate an image here.
-- lsvg will call img:save("xxx.svg") according the its command line arguments

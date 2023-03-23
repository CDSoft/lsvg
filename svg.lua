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
local sh = require "sh"
local fs = require "fs"

local sin = math.sin
local cos = math.cos
local abs = math.abs
local min = math.min
local max = math.max

---------------------------------------------------------------------
-- Points and vectors
---------------------------------------------------------------------

-- Point (and Vector which is an alias for Point) is a 2-number list
-- representing a 2D point that can be used to define the position of
-- SVG nodes.
--
-- Point(x, y) returns a point defined by its coordinates
-- P:unpack() returns x, y
-- P+V translates P by V
-- P-V translates P by -V
-- k*P or P*k scales P with a factor k
-- P/k scales P with a factor 1/k
-- -V negates V
-- P:rot(C, theta) rotates P around C by the angle theta
-- V:norm() is the norm of the vector
-- V:direction() is the angle of the vector (atan2(y, x))
-- V:unit() is a unit vector with the same direction than V

local P_mt = {__index={}}

local function is_point(M)
    return type(M) == "table" and getmetatable(M) == P_mt
end

function Point(x, y) return setmetatable({x, y}, P_mt) end

function Vector(...) return Point(...) end

function P_mt.__index:unpack() return F.unpack(self) end

function P_mt.__index:x() return self[1] end

function P_mt.__index:y() return self[2] end

function P_mt.__index:xy() return {x=self[1], y=self[2]} end
function P_mt.__index:xy1() return {x1=self[1], y1=self[2]} end
function P_mt.__index:xy2() return {x2=self[1], y2=self[2]} end
function P_mt.__index:cxy() return {cx=self[1], cy=self[2]} end

function P_mt.__index:norm() return (self[1]^2 + self[2]^2)^0.5 end
function P_mt.__index:direction() return math.atan(self[2], self[1]) end

function P_mt.__index:unit() return self/self:norm() end

function P_mt.__add(M1, M2)
    if not is_point(M1) or not is_point(M2) then
        error("Can not add "..F.show(a).." and "..F.show(b))
    end
    return Point(F.zip_with(F.op.add, {M1, M2}):unpack())
end

function P_mt.__sub(M1, M2)
    if not is_point(M1) or not is_point(M2) then
        error("Can not substract "..F.show(a).." and "..F.show(b))
    end
    return Point(F.zip_with(F.op.sub, {M1, M2}):unpack())
end

function P_mt.__mul(M, k)
    if is_point(M) and type(k) == "number" then
        M, k = M, k
    elseif is_point(k) and type(M) == "number" then
        M, k = k, M
    else
        error("Can not multiply "..F.show(M).." by "..F.show(k))
    end
    return Point(F.map(F.curry(F.op.mul)(k), M):unpack())
end

function P_mt.__div(M, k)
    if not is_point(M) or not type(k) == "number" then
        error("Can not multiply "..F.show(a).." by "..F.show(b))
    end
    return Point(F.map(F.curry(F.flip(F.op.div))(k), M):unpack())
end

function P_mt.__unm(M)
    return M * (-1)
end

local Origin = Point(0, 0)

function P_mt.__index.rot(M, C, theta)
    if theta == nil then C, theta = Origin, C end
    local x, y = (M-C):unpack()
    local xr = x*cos(theta) - y*sin(theta)
    local yr = x*sin(theta) + y*cos(theta)
    return Point(xr, yr) + C
end

---------------------------------------------------------------------
-- Generic SVG node
---------------------------------------------------------------------

-- SVG tree representation in Lua
-- ------------------------------
-- An SVG node (as well as an entire SVG image) is a table containing
-- attributes and child nodes.
-- The `__call` metamethod can add new attributes or children,
-- or replace the existing ones.
-- The structure of the node tree defined in Lua is exactly the
-- structure of the final SVG file.

local node_mt = {__index = {}}
local arrow_mt = {__index = {}}

local function Node(name)
    local self = {
        cons = Node,
        name = name,
        attrs = F{},
        contents = F{},
    }
    return setmetatable(self, node_mt)
end

function node_mt:__call(x)
    if type(x) == "string" then
        self.contents[#self.contents+1] = x
    elseif type(x) == "table" and getmetatable(x) == node_mt then
        self.contents[#self.contents+1] = x
    elseif type(x) == "table" and getmetatable(x) == arrow_mt then
        self.contents[#self.contents+1] = x
    elseif type(x) == "table" then
        F(x):mapk(function(k, v)
            if type(k) == "string" then
                self.attrs[k] = v
            elseif type(k) == "number" and math.type(k) == "integer" then
                self.contents[#self.contents+1] = v
            end
        end)
    else
        error("Invalid node item: "..F.show(x))
    end
    return self
end

-- SVG generation
-- --------------
-- The Lua tree is converted to a string representing the final SVG document.
-- To reduce the size of the SVG image, the precision of floating point numbers
-- is limited to 2 digits.
-- The generation is implemented by the `__tostring` metamethod.

-- add quotes around a string
local function quote(s)
    return ("%q"):format(s)
end

-- format a number with a 2-digit precision
local function fmt_num_raw(x)
    return ('%.2f'):format(x):gsub("0+$", ""):gsub("%.$", "")
end

-- format a number with quotes
local function fmt_num(x)
    return quote(fmt_num_raw(x))
end

-- format a list of points ("x,y x,y ...")
local function fmt_points(ps)
    if type(ps) == "string" then
        ps = ps:words():map(function(p) return p:split ",":map(tonumber) end)
    end
    return quote(ps:map(function(p) return F.map(fmt_num_raw, p):str "," end):unwords())
end

-- default format
local function fmt_default(x)
    return ('"%s"'):format(x)
end

-- formatting function according to the field name
local fmt = {
    font_size = fmt_num,
    height = fmt_num, width = fmt_num,
    x = fmt_num, y = fmt_num,
    x1 = fmt_num, y1 = fmt_num,
    x2 = fmt_num, y2 = fmt_num,
    cx = fmt_num, cy = fmt_num, r = fmt_num, rx = fmt_num, ry = fmt_num,
    stroke_width = fmt_num,
    points = fmt_points,
}

-- rewrite some attributes before generating SVG attributes
-- To simplify the description of positions with Point, some attributes
-- are rewritten when generating the SVG file.
--
--    xy={x, y} -> x=x, y=y
--    xy1={x, y} -> x1=x, y1=y
--    xy2={x, y} -> x2=x, y2=y
--    cxy={x, y} -> cx=x, cy=y
--
--    points={{x1, y1}, {x2, y2}, ...} -> points="x1,y1 x2,y2"

local function rewrite(attrs)
    attrs = F.clone(attrs)
    if attrs.xy  then attrs.x,  attrs.y  = F.unpack(attrs.xy);  attrs.xy  = nil end
    if attrs.xy1 then attrs.x1, attrs.y1 = F.unpack(attrs.xy1); attrs.xy1 = nil end
    if attrs.xy2 then attrs.x2, attrs.y2 = F.unpack(attrs.xy2); attrs.xy2 = nil end
    if attrs.cxy then attrs.cx, attrs.cy = F.unpack(attrs.cxy); attrs.cxy = nil end
    return attrs
end

function node_mt.__index:propagate(t)
    local t2 = t:patch {
        tip = self.attrs.tip,
        anchor = self.attrs.anchor,
    }
    self.contents:map(function(item)
        local mt = getmetatable(item)
        if mt.__index.propagate then item:propagate(t2) end
    end)
end

local attributes_to_remove = F{"tip", "anchor"}:from_set(F.const(true))
local function is_svg_attribute(kv) return not attributes_to_remove[kv[1]] end

-- __tostring produces an SVG description of a node and its children.
function node_mt:__tostring()
    self:propagate(F{})
    local nl = self.contents:filter(function(t) return type(t) == "table" end):null() and {} or "\n"
    local attrs = rewrite(self.attrs)
    return F.flatten {
        "<", self.name,
        attrs:items():filter(is_svg_attribute):map(function(kv)
            local k, v = F.unpack(kv)
            local f = fmt[k] or fmt_default
            return { " ", k:gsub("_", "-"), "=", f(v) }
        end),
        #self.contents == 0
            and { "/>" }
            or { ">", nl, self.contents:map(tostring), "</", self.name, ">" },
        "\n",
    } : str()
end

-- save writes the image to a file.
-- The image format is infered from its name:
-- - file.svg : saved as an SVG text file
-- - file.png or file.pdf : saved as a PNG or PDF file
--   (SVG converted to PNG or PDF with ImageMagick)
function node_mt.__index:save(filename)
    local base, ext = fs.splitext(filename)
    if ext == ".svg" then
        return fs.write(filename, tostring(self))
    elseif ext == ".png" or ext == ".pdf" then
        return fs.with_tmpdir(function(tmp)
            local tmpname = fs.join(tmp, fs.basename(base)..".svg")
            local ok, err = fs.write(tmpname, tostring(self))
            if not ok then return nil, err end
            return sh.run("convert", tmpname, filename)
        end)
    else
        error(filename..": image format not supported")
    end
end

---------------------------------------------------------------------
-- Arrow SVG node
---------------------------------------------------------------------

-- An Arrow node is a meta node that builds an arrow with one or two
-- tips and an optional text.
local function Arrow(t)
    local self = {
        cons = function(_) return Arrow{} end,
        name = "Arrow",
        points = F{},
        attrs = F{},
        contents = F{},
    }
    return setmetatable(self, arrow_mt)(t)
end

function arrow_mt:__call(x)
    if is_point(x) then
        self.points[#self.points+1] = x
    elseif type(x) == "string" then
        self.contents[#self.contents+1] = x
    elseif type(x) == "table" and getmetatable(x) == node_mt then
        self.contents[#self.contents+1] = x
    elseif type(x) == "table" then
        F(x):mapk(function(k, v)
            if type(k) == "string" then
                self.attrs[k] = v
            elseif type(k) == "number" and math.type(k) == "integer" then
                if is_point(v) then
                    self.points[#self.points+1] = v
                else
                    self.contents[#self.contents+1] = v
                end
            end
        end)
    else
        error("Invalid arrow item: "..F.show(x))
    end
    return self
end

function arrow_mt.__index:propagate(t)
    self.attrs.tip = self.attrs.tip or t.tip
    self.attrs.anchor = self.attrs.anchor or t.anchor
end

local function gen_arrow(arrow)
    assert(#arrow.points == 2, "An arrow requires 2 points")
    local attrs = arrow.attrs or {}
    local contents = arrow.contents or {}
    local g = G(contents)
    local A, B = arrow.points:unpack()
    local length = (B-A):norm()
    local tip = attrs.tip or length/4
    local delta = attrs.delta or math.rad(15)
    local A_ = A - tip/length*(A-B)
    local B_ = B - tip/length*(B-A)
    g:Line(attrs)(A:xy1())(B:xy2())
    g:Line(attrs)(B:xy1())(B_:rot(B, delta):xy2())
    g:Line(attrs)(B:xy1())(B_:rot(B, -delta):xy2())
    if attrs.double then
        g:Line(attrs)(A:xy1())(A_:rot(A, delta):xy2())
        g:Line(attrs)(A:xy1())(A_:rot(A, -delta):xy2())
    end
    contents:map(function(item)
        local anchor = item.attrs.anchor or 0.5
        local M = (1-anchor)*A + anchor*B
        g { item { xy=M } }
    end)
    return g
end

-- __tostring produces an SVG description of an arrow
function arrow_mt:__tostring()
    return tostring(gen_arrow(self))
end

---------------------------------------------------------------------
-- Frames
---------------------------------------------------------------------

-- Frame returns a function that changes the frame of items in a SVG node.
-- xmin, xmax, ymin, ymax describe the coordinates of the items in the SVG node.
-- Xmin, Xmax, Ymin, Ymax describe the coordinates of the items in the final SVG image.
-- Note: the y-axis is upward in the first frame. The Y-axis is downward in the SVG image.
-- Frame recomputes the coordinates of items, not their intrinsic characteristics.
-- I.e. fields like x, y, x1, y1, x2, y2, cx, cy, r, rx, ry, width, height, points
-- are recomputed. Other fields (e.g. stroke_width, font_size) are keep to avoid
-- changing the aspect of the image.
function Frame(t)
    local xmin, ymin, xmax, ymax = t.xmin, t.ymin, t.xmax, t.ymax
    local Xmin, Ymin, Xmax, Ymax = t.Xmin, t.Ymin, t.Xmax, t.Ymax

    local function tx(x) return (x-xmin)*(Xmax-Xmin)/(xmax-xmin) + Xmin end
    local function ty(y) return (y-ymax)*(Ymax-Ymin)/(ymin-ymax) + Ymin end
    local function trx(x) return abs(tx(x) - tx(0)) end
    local function try(y) return abs(ty(y) - ty(0)) end
    local id = F.id

    local function txy(xy)
        local x, y = F.unpack(xy)
        return {tx(x), ty(y)}
    end

    local function txys(ps)
        if type(ps) == "string" then
            ps = ps:words():map(function(p) return p:split ",":map(tonumber) end)
        end
        return ps:map(txy)
    end

    local m = {
        x = tx, x1 = tx, x2 = tx,
        y = ty, y1 = ty, y2 = ty,
        width = trx, height = try,
        cx = tx, cy = ty, r = trx, rx = trx, ry = try,
        points = txys,
        xy = txy, xy1 = txy, xy2 = txy,
        cxy = txy,
        tip = trx,
    }

    local function transform(node)
        if type(node) ~= 'table' then return node end
        if node.name == "linearGradient" then return node end
        if node.name == "radialGradient" then return node end
        local new = node.cons(node.name)
        new.attrs = node.attrs:mapk(function(k, v)
            return (m[k] or id)(v)
        end)
        new.contents = node.contents:map(transform)
        if node.points then
            new.points = node.points:map(function(p)
                return Point(F.unpack(txy(p)))
            end)
        end
        return new
    end

    return transform
end

---------------------------------------------------------------------
-- SVG document
---------------------------------------------------------------------

local function SVG()
    return Node "svg" {
        version="1.1",
        xmlns="http://www.w3.org/2000/svg",
    }
end

---------------------------------------------------------------------
-- SVG module
---------------------------------------------------------------------

local svg = {}
local svg_mt = {}

local primitive_nodes = "g text rect circle ellipse line polygon polyline path"
local custom_nodes = F{ arrow=Arrow, }

primitive_nodes:words():map(function(name)
    svg[name:cap()] = function(t) return Node(name)(t) end
    node_mt.__index[name:cap()] = function(self, t)
        local node = Node(name)(t)
        self(node)
        return node
    end
end)

custom_nodes:mapk(function(name, func)
    svg[name:cap()] = function(...) return func(...) end
    node_mt.__index[name:cap()] = function(self, ...)
        local node = func(...)
        self(node)
        return node
    end
end)

function svg.open()
    _ENV.svg = svg
    F.mapk(function(k, v) _ENV[k] = v end, svg)
    return svg
end

function svg_mt:__call()
    return SVG()
end

return setmetatable(svg, svg_mt)

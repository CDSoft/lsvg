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

---------------------------------------------------------------------
-- Generic SVG node
---------------------------------------------------------------------

local node_mt = {__index = {}}

local function Node(name)
    local self = {
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

function node_mt:__tostring()
    local nl = self.contents:filter(function(t) return type(t) == "table" end):null() and {} or "\n"
    return F.flatten {
        "<", self.name,
        self.attrs:items():map(function(kv)
            local k, v = F.unpack(kv)
            return { " ", k:gsub("_", "-"), "=", ('"%s"'):format(v) }
        end),
        #self.contents == 0
            and { "/>" }
            or { ">", nl, self.contents:map(tostring), "</", self.name, ">" },
        "\n",
    } : str()
end

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
-- Frames
---------------------------------------------------------------------

function Frame(t)
    local xmin, ymin, xmax, ymax = t.xmin, t.ymin, t.xmax, t.ymax
    local Xmin, Ymin, Xmax, Ymax = t.Xmin, t.Ymin, t.Xmax, t.Ymax

    local function tx(x) return (x-xmin)*(Xmax-Xmin)/(xmax-xmin) + Xmin end
    local function ty(y) return (y-ymax)*(Ymax-Ymin)/(ymin-ymax) + Ymin end
    local function trx(x) return tx(x) - tx(0) end
    local function try(y) return ty(0) - ty(y) end
    local id = F.id

    local function txy(s)
        return s:words()
            :map(function(xy)
                local x, y = xy:split(","):map(tonumber):unpack()
                return F{tx(x), ty(y)}:str ","
            end)
            :unwords()
    end

    local m = {
        x = tx, x1 = tx, x2 = tx,
        y = ty, y1 = ty, y2 = ty,
        width = tx, height = ty,
        cx = tx, cy = ty, r = trx, rx = trx, ry = try,
        points = txy,
    }

    local function transform(node)
        if type(node) ~= 'table' then return node end
        if node.name == "linearGradient" then return end
        if node.name == "radialGradient" then return end
        local new = Node(node.name)
        new.attrs = node.attrs:mapk(function(k, v)
            return (m[k] or id)(v)
        end)
        new.contents = node.contents:map(transform)
        return new
    end

    return transform
end

---------------------------------------------------------------------
-- Points and vectors
---------------------------------------------------------------------

local sin = math.sin
local cos = math.cos

local P_mt = {__index={}}

local function is_point(M)
    return type(M) == "table" and getmetatable(M) == P_mt
end

function Point(x, y) return setmetatable({x, y}, P_mt) end

function Vector(x, y) return Point(x, y) end

function P_mt.__index:unpack() return F.unpack(self) end

function P_mt.__index:x() return self[1] end

function P_mt.__index:y() return self[2] end

function P_mt.__index:xy() return {x=self[1], y=self[2]} end
function P_mt.__index:xy1() return {x1=self[1], y1=self[2]} end
function P_mt.__index:xy2() return {x2=self[1], y2=self[2]} end
function P_mt.__index:cxy() return {cx=self[1], cy=self[2]} end

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

function P_mt.__index.rot(M, C, theta)
    local x, y = (M-C):unpack()
    local xr = x*cos(theta) - y*sin(theta)
    local yr = x*sin(theta) + y*cos(theta)
    return Point(xr, yr) + C
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

local nodes = "g text rect circle ellipse line polygon polyline path"

nodes:words():map(function(name)
    svg[name:cap()] = function(t) return Node(name)(t) end
    node_mt.__index[name:cap()] = function(self, t)
        local node = Node(name)(t)
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

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

local F = require "fun"
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

local nodes = "g text rect circle ellipse line polyline path"

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

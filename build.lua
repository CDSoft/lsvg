section [[
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
]]

help.name "lsvg"
help.description [[
$name: Lua scriptable SVG generator
]]

local fs = require "fs"

var "builddir" ".build"
clean "$builddir"

---------------------------------------------------------------------
section "Compilation"
---------------------------------------------------------------------

build "$builddir/lsvg" { ls "src/*.lua",
    command = "luax -q -o $out $in",
}

---------------------------------------------------------------------
section "Installation"
---------------------------------------------------------------------

install "bin" "$builddir/lsvg"

---------------------------------------------------------------------
section "Test"
---------------------------------------------------------------------

rule "lsvg" {
    command = "$builddir/lsvg $in $out -- lsvg demo",
    implicit_in = {
        "$builddir/lsvg",
    }
}

rule "diff" {
    command = "diff -b --color $in && touch $out",
}

local tests = {}

ls "tests/*.lua"
: foreach(function(input)
    local output_svg = fs.join("$builddir", fs.splitext(fs.basename(input))..".svg")
    build(output_svg) { "lsvg", input }
    local ref = fs.splitext(input)..".svg"
    local output_ok = fs.splitext(output_svg)..".ok"
    acc(tests)(build(output_ok) { "diff", ref, output_svg })
end)

---------------------------------------------------------------------
section "Shortcuts"
---------------------------------------------------------------------

help "compile" "Compile $name"
phony "compile" { "$builddir/lsvg" }

help "test" "Test $name"
phony "test" (tests)

help "all" "Compile and test $name"
phony "all" { "compile", "test" }

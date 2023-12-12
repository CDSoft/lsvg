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

var "builddir" ".build"
clean "$builddir"

---------------------------------------------------------------------
section "Compilation"
---------------------------------------------------------------------

local version = build "$builddir/version" {
    description = "GIT version",
    command = "echo -n `git describe --tags` > $out",
    implicit_in = ".git/refs/tags .git/index",
}

rule "luax" {
    description = "LUAX $out",
    command = "luax -q -o $out $in",
}

local lsvg = build "$builddir/lsvg" { "luax", ls "src/*.lua", version }

install "bin" { lsvg }

---------------------------------------------------------------------
section "Test"
---------------------------------------------------------------------

rule "lsvg" {
    description = "LSVG $in",
    command = { lsvg, "$in -o $out -- lsvg demo" },
    implicit_in = lsvg,
}

rule "diff" {
    description = "DIFF $in",
    command = "diff -b --color $in && touch $out",
}

local tests = ls "tests/*.lua"
    : map(function(input)
        local output_svg = "$builddir" / input:basename():splitext()..".svg"
        local ref = input:splitext()..".svg"
        local output_ok = output_svg:splitext()..".ok"
        return build(output_svg) { "lsvg", input,
            validations = build(output_ok) { "diff", ref, output_svg },
        }
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

default "all"

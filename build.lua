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

local F = require "F"
local sys = require "sys"

help.name "lsvg"
help.description [[
$name: Lua scriptable SVG generator
]]

local target, args = target(arg)
if #args > 0 then
    F.error_without_stack_trace(args:unwords()..": unexpected arguments")
end

var "builddir" (".build"/(target and target.name))
clean "$builddir"

---------------------------------------------------------------------
section "Compilation"
---------------------------------------------------------------------

local sources = ls "src/*.lua"

local version = build "$builddir/version" {
    description = "GIT version",
    command = "echo -n `git describe --tags` > $out",
    implicit_in = ".git/refs/tags .git/index",
}

rule "luax" {
    description = "LUAX $out",
    command = "luax $arg -q -o $out $in",
}

rule "luaxc" {
    description = "LUAXC $out",
    command = "luaxc $arg -q -o $out $in",
}

local binaries = {
    build("$builddir/lsvg"..(target or sys.build).exe) {
        "luaxc",
        sources, version,
        arg = target and {"-t", target.name},
    },
    build "$builddir/lsvg.lua" { "luax", sources, version, arg="-t lua" },
}

install "bin" { binaries }

---------------------------------------------------------------------
section "Test"
---------------------------------------------------------------------

rule "lsvg" {
    description = "LSVG $in",
    command = {
        "LUA_PATH=tests/?.lua",
        "$lsvg $in -o $out --MF $depfile -- lsvg demo",
    },
    depfile = "$out.d",
}

rule "diff" {
    description = "DIFF $in",
    command = "diff -b --color $in && touch $out",
}

local test_envs = F{
    { "$builddir/lsvg",     "$builddir/test/luax" },
    { "$builddir/lsvg.lua", "$builddir/test/lua" },
}

local tests = ls "tests/*.lua"
    : map(function(input)
        return test_envs : map(function(test_env)
            local lsvg, test_dir = F.unpack(test_env)
            local test_type = test_dir:basename()

            local output_svg = test_dir / input:basename():splitext()..".svg"
            local ref = input:splitext()..".svg"
            local output_ok = output_svg:splitext()..".ok"
            local output_svg_d = output_svg..".d"
            local ref_d = ref.."."..test_type..".d"
            local output_deps_ok = output_svg:splitext()..".d.ok"
            return build(output_svg) { "lsvg", input,
                lsvg = lsvg,
                implicit_in = lsvg,
                implicit_out = output_svg_d,
                validations = {
                    build(output_ok)      { "diff", ref, output_svg },
                    build(output_deps_ok) { "diff", ref_d, output_svg_d },
                },
            }
        end)
    end)

---------------------------------------------------------------------
section "Shortcuts"
---------------------------------------------------------------------

help "compile" "Compile $name"
phony "compile" { binaries }

if not target then
help "test" "Test $name"
phony "test" (tests)
end

help "all" "Compile and test $name"
phony "all" { "compile", target and {} or "test" }

default "all"

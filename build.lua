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
https://codeberg.org/cdsoft/lsvg
]]

local F = require "F"
local sh = require "sh"

help.name "lsvg"
help.description [[
$name: Lua scriptable SVG generator
]]

var "builddir" ".build"
clean "$builddir"

---------------------------------------------------------------------
section "Compilation"
---------------------------------------------------------------------

var "git_version" { sh "git describe --tags" }
generator { implicit_in = ".git/refs/tags" }

local sources = {
    ls "src/*.lua",
    build "$builddir/version" {
        description = "GIT version",
        command = "echo $git_version > $out",
    },
}

build.luax.add_global "flags" "-q"

-- used by LuaX only
local binaries = {
    build.luax.native "$builddir/lsvg" { sources },
    build.luax.lua "$builddir/lsvg.lua" { sources },
}

local lsvg_luax = build.luax.luax "$builddir/lsvg.luax" { sources }

install "bin" { binaries }

phony "release" {
    build.tar "$builddir/release/${git_version}/lsvg-${git_version}-lua.tar.gz" {
        base = "$builddir/release/.build",
        name = "lsvg-${git_version}-lua",
        build.luax.lua("$builddir/release/.build/lsvg-${git_version}-lua/bin/lsvg.lua") { sources },
    },
    require "targets" : map(function(target)
        return build.tar("$builddir/release/${git_version}/lsvg-${git_version}-"..target.name..".tar.gz") {
            base = "$builddir/release/.build",
            name = "lsvg-${git_version}-"..target.name,
            build.luax[target.name]("$builddir/release/.build/lsvg-${git_version}-"..target.name/"bin/lsvg") { sources },
        }
    end),
}

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
phony "compile" { binaries, lsvg_luax }

help "test" "Test $name"
phony "test" (tests)

help "all" "Compile and test $name"
phony "all" { "compile", "test" }

default "all"

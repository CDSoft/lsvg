# This file is part of lsvg.
#
# lsvg is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# lsvg is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with lsvg.  If not, see <https://www.gnu.org/licenses/>.
#
# For further information about lsvg you can visit
# http://cdelord.fr/lsvg

BUILD = .build

LSVG = $(BUILD)/lsvg

PREFIX := $(firstword $(wildcard $(PREFIX) $(HOME)/.local $(HOME)))

## Build and test lsvg
all: compile
all: test

## Install lsvg to $PREFIX/bin, ~/.local/bin or ~/bin
install: $(LSVG)
	@test -n "$(PREFIX)" || (echo "No installation path found" && false)
	@mkdir -p $(PREFIX)/bin
	@install -v $< $(PREFIX)/bin

## Clean the build directory
clean:
	rm -rf $(BUILD)

include makex.mk

welcome:
	@echo '${CYAN}lsvg${NORMAL}: Lua scriptable SVG generator'

## Compile lsvg
compile: $(LSVG)

$(LSVG): lsvg.lua svg.lua | $(LUAX)
	@echo '${BLACK}${BG_GREEN}[LUAX]${NORMAL} ${CYAN}compiling $@${NORMAL}'
	@mkdir -p $(dir $@)
	@$(LUAX) -o $@ $^

## Test lsvg
test: $(BUILD)/demo.ok
test: $(BUILD)/luax.ok
test:
	@echo '${BLACK}${BG_GREEN}[TEST]${NORMAL} ${GREEN}Test passed${NORMAL}'

$(BUILD)/%.ok: tests/%.svg $(BUILD)/%.svg
	@diff -b --color $^
	@touch $@

$(BUILD)/demo.svg: $(LSVG) tests/demo.lua
	@echo '${BLACK}${BG_GREEN}[TEST]${NORMAL} ${CYAN}running $^${NORMAL}'
	@$^ $@ -- lsvg demo

$(BUILD)/%.svg: $(LSVG) tests/%.lua
	@echo '${BLACK}${BG_GREEN}[TEST]${NORMAL} ${CYAN}running $^${NORMAL}'
	@$^ $@

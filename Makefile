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

LSVG_BIN = $(BUILD)/lsvg

PREFIX := $(firstword $(wildcard $(PREFIX) $(HOME)/.local $(HOME)))

## Build and test lsvg
all: compile
all: test

## Install lsvg to $PREFIX/bin, ~/.local/bin or ~/bin
install: $(LSVG_BIN)
	@test -n "$(PREFIX)" || (echo "No installation path found" && false)
	@mkdir -p $(PREFIX)/bin
	@install -v $< $(PREFIX)/bin

## Clean the build directory
clean:
	rm -rf $(BUILD)

###############################################################################
# Help
###############################################################################

.PHONY: help welcome

BLACK     := $(shell tput -Txterm setaf 0)
RED       := $(shell tput -Txterm setaf 1)
GREEN     := $(shell tput -Txterm setaf 2)
YELLOW    := $(shell tput -Txterm setaf 3)
BLUE      := $(shell tput -Txterm setaf 4)
PURPLE    := $(shell tput -Txterm setaf 5)
CYAN      := $(shell tput -Txterm setaf 6)
WHITE     := $(shell tput -Txterm setaf 7)
BG_BLACK  := $(shell tput -Txterm setab 0)
BG_RED    := $(shell tput -Txterm setab 1)
BG_GREEN  := $(shell tput -Txterm setab 2)
BG_YELLOW := $(shell tput -Txterm setab 3)
BG_BLUE   := $(shell tput -Txterm setab 4)
BG_PURPLE := $(shell tput -Txterm setab 5)
BG_CYAN   := $(shell tput -Txterm setab 6)
BG_WHITE  := $(shell tput -Txterm setab 7)
NORMAL    := $(shell tput -Txterm sgr0)

CMD_COLOR    := ${YELLOW}
TARGET_COLOR := ${GREEN}
TEXT_COLOR   := ${CYAN}
TARGET_MAX_LEN := 16

## show this help massage
help: welcome
	@echo ''
	@echo 'Usage:'
	@echo '  ${CMD_COLOR}make${NORMAL} ${TARGET_COLOR}<target>${NORMAL}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-_0-9]+:/ { \
	    helpMessage = match(lastLine, /^## (.*)/); \
	    if (helpMessage) { \
	        helpCommand = substr($$1, 0, index($$1, ":")-1); \
	        helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
	        printf "  ${TARGET_COLOR}%-$(TARGET_MAX_LEN)s${NORMAL} ${TEXT_COLOR}%s${NORMAL}\n", helpCommand, helpMessage; \
	    } \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

welcome:
	@echo '${CYAN}lsvg${NORMAL}: Lua scriptable SVG generator'

###############################################################################
# Compilation
###############################################################################

## Compile lsvg
compile: $(LSVG_BIN)

$(LSVG_BIN): lsvg.lua svg.lua | $(LUAX)
	@echo '${BLACK}${BG_GREEN}[LUAX]${NORMAL} ${CYAN}compiling $@${NORMAL}'
	@mkdir -p $(dir $@)
	@luax -q -o $@ $^

###############################################################################
# Test
###############################################################################

.SECONDARY:

## Test lsvg
test: $(BUILD)/demo.ok
test: $(BUILD)/luax.ok
test:
	@echo '${BLACK}${BG_GREEN}[TEST]${NORMAL} ${GREEN}Test passed${NORMAL}'

$(BUILD)/%.ok: tests/%.svg $(BUILD)/%.svg
	@diff -b --color $^
	@touch $@

$(BUILD)/demo.svg: $(LSVG_BIN) tests/demo.lua
	@echo '${BLACK}${BG_GREEN}[TEST]${NORMAL} ${CYAN}running $^${NORMAL}'
	@$^ $@ -- lsvg demo

$(BUILD)/%.svg: $(LSVG_BIN) tests/%.lua
	@echo '${BLACK}${BG_GREEN}[TEST]${NORMAL} ${CYAN}running $^${NORMAL}'
	@$^ $@

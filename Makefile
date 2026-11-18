GPRBUILD ?= gprbuild
GPRCLEAN ?= gprclean
SDLADA_DIR := ../sdlada
SDL_MODE   ?= release

GPRFLAGS      := -XSDL_MODE=$(SDL_MODE)
KEYBOARD_SPEC := $(SDLADA_DIR)/build/gnat/gen/src/sdl-events-keyboards.ads
GENERATOR     := $(SDLADA_DIR)/build/gnat/gen/$(SDL_MODE)/tools/gen_keyboard

.PHONY: all run test clean

all: tetris

tetris: tetris.gpr $(wildcard src/*.ads src/*.adb) $(KEYBOARD_SPEC)
	$(GPRBUILD) -p $(GPRFLAGS) -P tetris.gpr

# SDLAda generates its large SDL.Events.Keyboards spec with this tool.
$(KEYBOARD_SPEC):
	@test -d $(SDLADA_DIR) || \
	  git clone --depth 1 https://github.com/ada-game-framework/sdlada.git $(SDLADA_DIR)
	@mkdir -p $(SDLADA_DIR)/build/gnat/gen/src
	$(GPRBUILD) -p $(GPRFLAGS) -P $(SDLADA_DIR)/build/gnat/tools.gpr
	$(GENERATOR) > $@

run: tetris
	./tetris

test: tests/tetris_tests.gpr $(wildcard src/*.ads src/*.adb) $(wildcard tests/*.adb)
	$(GPRBUILD) -p $(GPRFLAGS) -P tests/tetris_tests.gpr
	./tests/logic_test

clean:
	-$(GPRCLEAN) -q $(GPRFLAGS) -P tetris.gpr
	-$(GPRCLEAN) -q $(GPRFLAGS) -P tests/tetris_tests.gpr
	rm -rf obj tests/logic_test

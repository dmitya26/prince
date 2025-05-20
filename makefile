LUA=luajit
FILES=game.lua render_zoomed.lua battle.lua

all: build
build:
	stty -icanon
	$(LUA) $(FILES)
	stty icanon

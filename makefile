LUA=lua
FILES=*.lua

all: build
build:
	stty -icanon
	$(LUA) $(FILES)
	stty icanon

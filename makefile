LUA=lua
FILES=*.lua

all: build
build:
	$(LUA) $(FILES)

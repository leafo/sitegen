
.PHONY: build local install lint

local: build
	luarocks make --local

install: build
	sudo luarocks make

build::
	moonc sitegen

lint::
	moonc -l sitegen


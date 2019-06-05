
.PHONY: build local install lint

local: build
	luarocks make --lua-version=5.1 --local

build::
	moonc sitegen

lint::
	moonc -l sitegen


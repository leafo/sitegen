

install: build
	sudo luarocks make

build::
	moonc sitegen.moon sitegen


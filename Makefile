.PHONY: setup-all setup-nvim setup-vscode setup-gnome
.PHONY: enable-hint-rust disable-hint-rust enable-hint-py disable-hint-py

setup-all:
	./zdotfiles setup

setup-nvim:
	./zdotfiles setup --only nvim

setup-vscode:
	./zdotfiles setup --only vscode

setup-gnome:
	./zdotfiles setup --only gnome

enable-hint-rust disable-hint-rust enable-hint-py disable-hint-py:
	nvim --headless -u NONE -i NONE -l scripts/nvim-hints.lua $(word 1,$(subst -, ,$@)) $(word 3,$(subst -, ,$@))

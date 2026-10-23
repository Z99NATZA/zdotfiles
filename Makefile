.PHONY: setup-all setup-nvim setup-vscode setup-gnome

setup-all:
	./zdotfiles setup

setup-nvim:
	./zdotfiles setup --only nvim

setup-vscode:
	./zdotfiles setup --only vscode

setup-gnome:
	./zdotfiles setup --only gnome

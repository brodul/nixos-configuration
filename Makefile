HOST ?= vipera

switch:
	sudo nixos-rebuild switch --flake /etc/nixos#$(HOST) --impure

.PHONY: switch

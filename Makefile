HOSTNAME ?= $(shell hostname)
USER ?= $(shell id -un)

ifeq ($(HOSTNAME),florian-nixos)
	HOST ?= desktop
	REBUILD_CMD ?= nixos-rebuild
	REBUILD_SWITCH_CMD ?= sudo nixos-rebuild
else ifeq ($(HOSTNAME),Florians-MacBook-Pro)
	HOST ?= macbookpro
	REBUILD_CMD ?= darwin-rebuild
endif

REBUILD_SWITCH_CMD ?= $(REBUILD_CMD)

build: build-host build-home
switch: switch-host switch-home

build-host:
	$(REBUILD_CMD) build --flake ".#$(HOST)"

switch-host:
	$(REBUILD_SWITCH_CMD) switch --flake ".#$(HOST)"

build-home:
	home-manager build --flake ".#$(USER)@$(HOST)"

switch-home:
	home-manager switch --flake ".#$(USER)@$(HOST)"

containers: container-apollo container-hermes container-poseidon container-hestia

server:
	nixos-rebuild --build-host server --target-host server --use-remote-sudo switch --flake '.#server'

container-%:
	nixos-rebuild --target-host $(patsubst container-%,%,$@) switch --flake .#$(patsubst container-%,%,$@)

.PHONY: build switch build-host switch-host build-home switch-home server containers

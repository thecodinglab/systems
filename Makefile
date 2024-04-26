SSH_SERVER_HOST := server
SSH_APOLLO_HOST := apollo
SSH_HERMES_HOST := hermes
SSH_POSEIDON_HOST := poseidon
SSH_HESTIA_HOST := hestia

CONTAINERS := apollo hermes poseidon hestia

default:
	@echo "Usage: make [desktop|macbookpro|server|containers]"

desktop:
	nixos-rebuild switch --flake '.#desktop' |& nom

macbookpro:
	darwin-rebuild switch --flake '.#macbookpro' |& nom

server:
	nixos-rebuild --build-host ${SSH_SERVER_HOST} --target-host ${SSH_SERVER_HOST} --use-remote-sudo switch --flake '.#server' |& nom

containers: $(CONTAINERS)

apollo:
	nixos-rebuild --target-host ${SSH_APOLLO_HOST} switch --flake '.#apollo' |& nom

hermes:
	nixos-rebuild --target-host ${SSH_HERMES_HOST} switch --flake '.#hermes' |& nom

poseidon:
	nixos-rebuild --target-host ${SSH_POSEIDON_HOST} switch --flake '.#poseidon' |& nom

hestia:
	nixos-rebuild --target-host ${SSH_HESTIA_HOST} switch --flake '.#hestia' |& nom

.PHONY: default desktop macbookpro server containers $(CONTAINERS)

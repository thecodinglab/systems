SSH_SERVER_HOST := server
SSH_APOLLO_HOST := apollo
SSH_HERMES_HOST := hermes
SSH_POSEIDON_HOST := poseidon
SSH_HESTIA_HOST := hestia

desktop:
	sudo nixos-rebuild switch --flake '.#desktop'

macbookpro:
	darwin-rebuild switch --flake '.#macbookpro'

server:
	nixos-rebuild --build-host ${SSH_SERVER_HOST} --target-host ${SSH_SERVER_HOST} --use-remote-sudo switch --flake '.#server'

apollo:
	nixos-rebuild --target-host ${SSH_APOLLO_HOST} switch --flake '.#apollo'

hermes:
	nixos-rebuild --target-host ${SSH_HERMES_HOST} switch --flake '.#hermes'

poseidon:
	nixos-rebuild --target-host ${SSH_POSEIDON_HOST} switch --flake '.#poseidon'

hestia:
	nixos-rebuild --target-host ${SSH_HESTIA_HOST} switch --flake '.#hestia'

.PHONY: desktop macbookpro server apollo hermes

SSH_SERVER_HOST := server
SSH_APOLLO_HOST := apollo
SSH_HERMES_HOST := hermes

desktop:
	sudo nixos-rebuild switch --flake '.#desktop'

macbookpro:
	darwin-rebuild switch --flake '.#macbookpro'

server:
	nixos-rebuild --build-host ${SSH_SERVER_HOST} --target-host ${SSH_SERVER_HOST} --use-remote-sudo switch --flake '.#server'

apollo:
	nixos-rebuild --build-host ${SSH_APOLLO_HOST} --target-host ${SSH_APOLLO_HOST} switch --flake '.#apollo'

hermes:
	nixos-rebuild --build-host ${SSH_HERMES_HOST} --target-host ${SSH_HERMES_HOST} switch --flake '.#hermes'

.PHONY: desktop macbookpro server apollo hermes

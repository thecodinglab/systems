HOSTNAME ?= $(shell hostname)

ifeq ($(HOSTNAME),florian-nixos)
	HOST ?= desktop
else ifeq ($(HOSTNAME),Florians-MacBook-Pro)
	HOST ?= macbookpro
else ifeq ($(HOSTNAME),Florians-Mac-Mini)
	HOST ?= macmini
endif

# the rebuild tool follows from the host, so HOST=<name> alone is enough
DARWIN_HOSTS := macbookpro macmini
PLATFORM ?= $(if $(filter $(HOST),$(DARWIN_HOSTS)),darwin,nixos)

# extra flags for every flake evaluation, e.g. `make build FLAKE_FLAGS=--show-trace`
FLAKE_FLAGS ?=

# per-machine experiments, see local/README.md; overriding an input never
# writes flake.lock
# expands a leading ~ (make passes `LOCAL_DIR=~/x` through literally) and
# makes the path absolute
expand-path = $(abspath $(patsubst ~/%,$(HOME)/%,$(1)))

LOCAL_DIR ?= $(HOME)/.config/systems-local
ifneq ($(wildcard $(LOCAL_DIR)),)
	override FLAKE_FLAGS += --override-input local path:$(call expand-path,$(LOCAL_DIR))
endif

KAKEIBO_SRC ?= $(HOME)/dev/kakeibo/main
ifeq ($(DEV_KAKEIBO),1)
	override FLAKE_FLAGS += --override-input kakeibo git+file://$(call expand-path,$(KAKEIBO_SRC))
endif

SHELL_SRC ?= $(HOME)/dev/shell
ifeq ($(DEV_SHELL),1)
	override FLAKE_FLAGS += --override-input shell git+file://$(call expand-path,$(SHELL_SRC))
endif

XCLOUD_SRC ?= $(HOME)/dev/xcloud/main
ifeq ($(DEV_XCLOUD),1)
	override FLAKE_FLAGS += --override-input xcloud git+file://$(call expand-path,$(XCLOUD_SRC))
endif

# Everything is evaluated and built as the calling user, only the activation
# runs as root (with -H: macOS sudo keeps the caller's HOME, which nix warns
# about; darwin-rebuild resets it the same way). root has no GitHub
# credentials, so `sudo darwin-rebuild switch` can only evaluate while the private kakeibo input still happens to be in the
# store (it is not a gc root), and it would also have to read the user's
# checkouts for the overrides above. darwin-rebuild has no equivalent of
# `nixos-rebuild --sudo`, so the darwin switch below does by hand what
# `darwin-rebuild switch` does after building: point the system profile at the
# new generation and run its activation.
SYSTEM_PROFILE ?= /nix/var/nix/profiles/system

build: check-host
ifeq ($(PLATFORM),darwin)
	darwin-rebuild build --flake ".#$(HOST)" $(FLAKE_FLAGS)
else
	nixos-rebuild build --flake ".#$(HOST)" $(FLAKE_FLAGS)
endif

switch: check-host
ifeq ($(PLATFORM),darwin)
	darwin-rebuild build --flake ".#$(HOST)" $(FLAKE_FLAGS)
	sudo -H nix-env --profile $(SYSTEM_PROFILE) --set "$$(readlink -f result)"
	sudo -H ./result/sw/bin/darwin-rebuild activate
else
	nixos-rebuild switch --sudo --flake ".#$(HOST)" $(FLAKE_FLAGS)
endif

check-host:
ifndef HOST
	$(error unknown hostname '$(HOSTNAME)', pass HOST=<name>)
endif

# update all inputs and nvfetcher sources, or only some inputs (without
# nvfetcher): make update INPUTS="nixpkgs stylix"
update:
	./scripts/update.sh $(INPUTS)

containers: container-apollo container-hermes container-hestia

server:
	nixos-rebuild --build-host server --target-host server --sudo switch --flake '.#server' $(FLAKE_FLAGS)

container-%:
	nixos-rebuild --target-host $(patsubst container-%,%,$@) switch --flake .#$(patsubst container-%,%,$@) $(FLAKE_FLAGS)
	sleep 5 # for some reason without a timeout rebuilding all containers will get stuck

.PHONY: build switch check-host update server containers

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

# point an input at a local checkout instead of its locked revision, e.g.
# `make switch DEV_SHELL=~/dev/shell/main`, so every machine can keep its
# checkouts wherever it likes
dev-input = $(if $(2),--override-input $(1) git+file://$(call check-dir,$(call expand-path,$(2)),$(1)))
check-dir = $(if $(wildcard $(1)/.),$(1),$(error $(2): no checkout at '$(1)'))

override FLAKE_FLAGS += $(call dev-input,kakeibo,$(DEV_KAKEIBO))
override FLAKE_FLAGS += $(call dev-input,shell,$(DEV_SHELL))
override FLAKE_FLAGS += $(call dev-input,xcloud,$(DEV_XCLOUD))
override FLAKE_FLAGS += $(call dev-input,devtools,$(DEV_DEVTOOLS))

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

# skip building the new nixos-rebuild and re-executing it before every build;
# pass `NIXOS_REBUILD_FLAGS=` if a nixpkgs bump ever changes it incompatibly
NIXOS_REBUILD_FLAGS ?= --no-reexec

build: check-host
ifeq ($(PLATFORM),darwin)
	darwin-rebuild build --flake ".#$(HOST)" $(FLAKE_FLAGS)
else
	nixos-rebuild build $(NIXOS_REBUILD_FLAGS) --flake ".#$(HOST)" $(FLAKE_FLAGS)
endif

switch: check-host
ifeq ($(PLATFORM),darwin)
	darwin-rebuild build --flake ".#$(HOST)" $(FLAKE_FLAGS)
	sudo -H nix-env --profile $(SYSTEM_PROFILE) --set "$$(readlink -f result)"
	sudo -H ./result/sw/bin/darwin-rebuild activate
else
	nixos-rebuild switch $(NIXOS_REBUILD_FLAGS) --sudo --flake ".#$(HOST)" $(FLAKE_FLAGS)
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

# render home-assistant/ and push it to the home assistant os host, see
# home-assistant/README.md
home-assistant:
	nix run .#home-assistant $(FLAKE_FLAGS)

.PHONY: build switch check-host update server containers home-assistant

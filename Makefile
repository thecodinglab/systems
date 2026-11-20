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

# nh evaluates and builds as the calling user and only elevates for the
# activation (root has no GitHub credentials for the private inputs, nor
# access to the checkouts of the overrides above). Before the first switch has
# installed it, it is taken from the flake's nixpkgs
NH ?= $(or $(shell command -v nh),nix run --inputs-from . nixpkgs\#nh --)

build: check-host
	$(NH) $(PLATFORM:nixos=os) build . --hostname $(HOST) --out-link result -- $(FLAKE_FLAGS)

switch: check-host
	$(NH) $(PLATFORM:nixos=os) switch . --hostname $(HOST) -- $(FLAKE_FLAGS)

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

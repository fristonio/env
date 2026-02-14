SHELL := bash

default: help

##@ Actions

switch:
	@if [[ -z "$(f)" ]]; then \
		echo "No configuration name provided, use: f=<configuration-name>"; \
		make help; exit 1; \
	fi
	@echo "Adding files to git index"
	git add . && git status

darwin-switch: switch ## Switch the darwin configuration: f=<configuration-name>. Example: make macbook
	echo "Switching darwin configuration for $(f)"
	sudo darwin-rebuild switch --flake .#$(f)

nixos-switch: ## Switch the nixos configuration: f=<configuration-name>. Example: make pacman
	echo "Switching nixos configuration for $(f)"
	sudo nixos-rebuild switch --flake .#$(f)

home-switch: ## Switch the home manager configuration: f=<configuration-name>. Example: make macbook-lima-vm
	echo "Switching home-manager configuration for $(f)"; \
	home-manager switch -b bak --flake .#$(f); \

patch-home-config: ## Apply any manual patch required.
	cp ./configs/zed/settings.json "${HOME}/.config/zed"
	cp ./configs/zed/keymap.json "${HOME}/.config/zed"

.PHONY: switch darwin-switch nixos-switch home-switch patch-home-config

##@ Development
format: ## Format the code.
	@find . -type f -name '*.nix' -exec nixfmt {} \;

##@ Initialize environment

show:
	@nix flake show

init-nix-darwin: ## Setup nix-darwin for macos setup
	@echo "Installing nix (Determinate installer)"
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install && exec bash
	nix --version

	@echo "Setting up nix-darwin"
	sudo nix run nix-darwin/nix-darwin-25.11#darwin-rebuild -- switch
	darwin-version

	@echo "nix-darwin installed, to activate run: 'sudo darwin-rebuild switch --flake .#<configuration>'"


init-home-manager: ## Setup home manager in standalone mode
	@echo "Installing nix"
	# curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon && exec bash
	nix --version

	@echo "Enabling nix flakes"
	echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf

	@echo "Installing home-manager in standalone mode"
	nix run home-manager/release-25.11 -- switch --flake .#
	home-manager --version

	@echo "Home Manager installed, to activate run: home-manager switch --flake .#<configuration>"

.PHONY: init-home-manager init-nix-darwin

##@ Helpers

help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: help

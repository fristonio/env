#!/usr/bin/env nu

use std/log

export-env {
  $env.ENV_ROOT_DIR = $env.FILE_PWD
}

# Names currently exposed under a flake output attribute (e.g.
# "homeConfigurations"), evaluated straight from the flake so this always
# matches whatever flake.nix actually defines.
def flake-attr-names [attr: string] {
    let flake_ref = $"($env.ENV_ROOT_DIR)#($attr)"
    let result = (
        ^nix eval --json --no-write-lock-file $flake_ref --apply "builtins.attrNames"
        | complete
    )
    if $result.exit_code != 0 {
        error make {msg: $"Failed to evaluate ($flake_ref):\n($result.stderr)"}
    }
    $result.stdout | from json
}

# Which flake output kind (home/darwin/nixos) a configuration name belongs
# to, so `switch` can't be pointed at the wrong rebuild command by mistake.
def resolve-switch-target [name: string] {
    let candidates = [
        {kind: "home", attr: "homeConfigurations"}
        {kind: "darwin", attr: "darwinConfigurations"}
        {kind: "nixos", attr: "nixosConfigurations"}
    ] | each {|c| {kind: $c.kind, names: (flake-attr-names $c.attr)} }

    let matches = $candidates | where {|c| $name in $c.names} | get kind

    if ($matches | is-empty) {
        let available = $candidates
        | each {|c| $"  ($c.kind): ($c.names | str join ', ')"}
        | str join "\n"
        error make {msg: $"No flake configuration named '($name)'. Available:\n($available)"}
    }
    if ($matches | length) > 1 {
        error make {msg: $"'($name)' exists in multiple flake outputs: ($matches | str join ', ')"}
    }

    $matches | first
}

# Initilize environment
export def env-init [] {
    sync-env-configs --backup
    init-nushell-autoloads
}

# Switch a home-manager, nix-darwin or nixos configuration. The configuration
# name is validated against the flake's actual outputs first, and the target
# platform is sanity-checked against the current host, so this can't fire the
# wrong rebuild command against the wrong machine.
export def nix-switch [
    name: string # configuration name, e.g. lima-vm-aarch64, macbook, pacman
] {
    let kind = resolve-switch-target $name
    let flake_ref = $"($env.ENV_ROOT_DIR)#($name)"

    # The flake is referenced locally (git+file), which only sees
    # tracked/staged files — stage everything first so new files aren't
    # silently invisible to the build, matching the old Makefile's `switch`.
    log info "Staging files for git-tracked flake evaluation"
    git -C ($env.ENV_ROOT_DIR) add .
    git -C ($env.ENV_ROOT_DIR) status

    match $kind {
        "darwin" => {
            if $nu.os-info.name != "macos" {
                error make {msg: $"'($name)' is a darwin configuration but this host is running ($nu.os-info.name)"}
            }
            log info $"Switching darwin configuration: ($name)"
            sudo darwin-rebuild switch --flake $flake_ref
        }
        "nixos" => {
            if not ("/etc/NIXOS" | path exists) {
                error make {msg: $"'($name)' is a nixos configuration but this host is not running NixOS"}
            }
            log info $"Switching nixos configuration: ($name)"
            sudo nixos-rebuild switch --flake $flake_ref
        }
        "home" => {
            log info $"Switching home-manager configuration: ($name)"
            home-manager switch -b bak --flake $flake_ref
        }
    }
}

# Show the flake's outputs (nix flake show).
export def show-flake [] {
    ^nix flake show ($env.ENV_ROOT_DIR)
}

# Format nix, nushell and lua files across the repo.
export def repo-format [] {
    let root = $env.ENV_ROOT_DIR

    log info "Formatting nix files"
    let nix_files = glob ($root | path join "**/*.nix") --exclude [".git"]
    if ($nix_files | is-not-empty) {
        ^nixfmt ...$nix_files
    }

    log info "Formatting nushell files"
    ^nufmt $root

    log info "Formatting lua files"
    ^stylua $root -g "*.lua"
}

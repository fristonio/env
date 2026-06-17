$env.ENV_DIR = ($env.HOME | path join ".env")
$env.ENV_LOCAL = ($env.ENV_DIR | path join "local")

$env.EDITOR = "nvim"

alias l = ls -a
alias ll = ls -la

alias gs = git status
alias gl = git log --oneline --graph --abbrev-commit --decorate

if (which eza | is-not-empty) {
    alias li = eza -l --icons
    alias tree = eza --tree
}

if (which go | is-not-empty) {
    $env.PATH ++= [
        ($env.HOME | path join "go/bin")
    ]
}

if (which cargo | is-not-empty) {
    $env.PATH ++= [
        ($env.HOME | path join ".cargo/bin")
    ]
}

@category env
def --env pick [
    action?: closure
    --default(-d): any
    --prompt(-p): string
    --multi(-m)
] {
    if ($in | is-empty) {
        return
    }

    let selection = $in | input list --fuzzy --no-separator --multi=$multi $prompt
    let value = if ($selection | is-not-empty) {
        $selection
    } else if ($default | is-not-empty) {
        $default
    } else { return }

    if $action != null {
        do $action $value
    } else {
        $value
    }
}

@category env
def --env confirm [prompt: string = "Are you sure? [y/n]: "] {
    print -n $"(ansi yellow)($prompt)(ansi reset)"
    loop {
        let event = (input listen --types [key])
        if $event.key_type == "char" {
            let key = $event.code | str downcase
            if $key == "y" {
                print $event.code
                return true
            } else if $key == "n" {
                print $event.code
                return false
            }
            if ($event.modifiers | is-not-empty) {
                return false
            }
        } else {
            print ""
            return false
        }
    }
}

@category env
def --env cmds [] {
    help commands
    | where command_type == "custom" and category != ""
    | input list --fuzzy --no-separator
}

@category env
def --env nuscript-path [name: string, --autoload(-a)] {
    if $autoload {
        ($nu.user-autoload-dirs | first | path join $name)
    } else {
        ($nu.default-config-dir | path join $name)
    }
}

let env_configs = {

    # Optional tag because in some environment these are directly tracked
    # through nix config.
    "configs/bashrc": {dest: ".bashrc", optional: true}
    "configs/vimrc": {dest: ".vimrc", optional: true}
    "configs/gitconfig": {dest: ".gitconfig", optional: true}
    "configs/tmux.conf": {dest: ".tmux.conf", optional: true}

    # Nushell configs
    "shell/config.nu": {
        dest: (nuscript-path "config.nu")
    }
    "shell/env.nu": {
        dest: (nuscript-path "env.nu")
    }
    "shell/dev.nu": {
        dest: (nuscript-path -a "dev.nu")
    }
    "shell/utils.nu": {
        dest: (nuscript-path -a "utils.nu")
    }
    "shell/git.nu": {
        dest: (nuscript-path -a "git.nu")
    }
    "shell/k8s.nu": {
        dest: (nuscript-path -a "k8s.nu")
    }
    "shell/theme.nu": {
        dest: (nuscript-path -a "theme.nu")
    }

    # Editor configs
    "configs/helix/config.toml": {dest: ".config/helix/config.toml"}
    "configs/nvim": {dest: ".config/nvim"}
    "configs/zed/settings.json": {dest: ".config/zed/settings.json"}
    "configs/zed/keymap.json": {dest: ".config/zed/keymap.json"}

    # Terminal config
    "configs/ghostty/config": {dest: ".config/ghostty/config"}

    # TODO: Seperate out darwin vs linux stuff.
    # "configs/aerospace.toml":  { dest: ".aerospace.toml", optional: true },
    # "configs/niri/config.kdl": { dest: ".config/niri/config.kdl", optional: true },
}

# Initializes any user autloads required for nushell
@category "env"
def init-nushell-autoloads [] {
    let autoload_dir = $nu.user-autoload-dirs | first

    if (which zoxide | is-not-empty) {
        zoxide init --cmd cd nushell | save -f ($autoload_dir | path join "_zoxide.nu")
    }

    if (which fzf | is-not-empty) {
        fzf --nushell | save -f ($autoload_dir | path join "_fzf.nu")
    }
}

# Sync environment config to user home.
@category "env"
def sync-env-configs [
  --all (-a)      # Include configs marked as optional
  --backup (-b)   # Backup existing files to .bak
  --dry-run (-d)  # Display actions without actually modifying the filesystem
] {
    use std/log

    let $env_dir = $env.ENV_DIR
    let $home_dir = $env.HOME

    if $dry_run {
        print $"(ansi yellow_italic)--- DRY RUN MODE: No changes will be made ---\n(ansi reset)"
    }

    let configs_list = (
    $env_configs
    | transpose src meta
    | each { |entry|
      let config_out = {optional: false} | merge $entry.meta
      mut out = {
        src: ($env_dir | path join $entry.src | path expand),
        dest: ($home_dir | path join $config_out.dest | path expand --no-symlink),
        skip: (not $all and ($config_out.optional == true)),
        error: ""
      }

      if not ($out.src | path exists) {
        $out.error = $"Source file missing: ($out.src)"
      } else if ($out.dest | path exists) {
        if (($out.dest | path type) == "symlink") and (($out.dest | path expand) == $out.src) {
          log info $"Config file already exist with correct symlink, will be skipped: ($out.src)"
          $out.skip = true
        } else if (not $backup) {
          $out.error = $"Destination file already exist: ($out.dest) \(Use -b, --backup\)"
        }
      }

      $out
    }
  )

    let $invalid_configs = $configs_list | where not $it.skip and $it.error != ""
    if ($invalid_configs | is-not-empty) {
        log critical "Unable to sync configs"
        ($invalid_configs | each {|entry| log error $entry.error })
        return
    }

    def format-path [path: string] {
        $path | str replace $home_dir ~
    }
    $configs_list
    | where $it.skip == false
    | each { |entry|
    let log_prefix = if $dry_run { $"(ansi yellow)[DRY] (ansi reset)" } else { "" }

    let dest_dir = $entry.dest | path dirname
    if not ($dest_dir | path exists) {
      log info $"($log_prefix) Ensuring directory: ($dest_dir)"
      if not $dry_run {
        mkdir ($entry.dest | path dirname)
      }
    }

    if ($entry.dest | path exists) and $backup {
      let backup_file = $"($entry.dest).bak"

      log info $"($log_prefix)(ansi blue)Backing up:(ansi reset) (format-path $entry.dest) -> (format-path $backup_file)"
      if not $dry_run {
        mv $entry.dest $backup_file
      }
    }

    log info $"($log_prefix)(ansi green)Linking:(ansi reset) (format-path $entry.src) -> (format-path $entry.dest)"
    if not $dry_run {
      ln -s $entry.src $entry.dest
    }
  }

    print $"\n(ansi green)Environment configs sync complete(ansi reset)"
    return
}

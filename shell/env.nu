$env.ENV_DIR = "~/.env/"

const env_configs = {
    "configs/bashrc":    { dest: ".bashrc", optional: true },
    "configs/vimrc":     { dest: ".vimrc", optional: true },
    "configs/gitconfig": { dest: ".gitconfig", optional: true }
    "configs/tmux.conf": { dest: ".tmux.conf", optional: true },

    "shell/config.nu": { dest: ".config/nushell/config.nu" },
    "shell/env.nu":    { dest: ".config/nushell/env.nu" },

    "configs/helix/config.toml": { dest: ".config/helix/config.toml" },
    "configs/ghostty/config":    { dest: ".config/ghostty/config" },
    "configs/zed/settings.json": { dest: ".config/zed/settings.json" }
    "configs/zed/keymap.json":   { dest: ".config/zed/keymap.json" }

    # TODO: Seperate out darwin vs linux stuff.
    # "configs/aerospace.toml":  { dest: ".aerospace.toml", optional: true },
    # "configs/niri/config.kdl": { dest: ".config/niri/config.kdl", optional: true },
}

# Initializes any user autloads required for nushell
@category "env"
def init-nushell-autoloads [] {
  let autoload_dir = ($nu.user-autoload-dirs | first)
  let theme_file = ($autoload_dir | path join "theme.nu")

  mkdir $autoload_dir

  http get https://raw.githubusercontent.com/catppuccin/nushell/refs/heads/main/themes/catppuccin_frappe.nu
  | save -f ($autoload_dir | path join "theme.nu")

  if (which zoxide | is-not-empty) {
    zoxide init nushell | save -f ($autoload_dir | path join "zoxide.nu")
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
      let config_out = ({optional: false} | merge $entry.meta)
      {
        src: ($env_dir | path join $entry.src | path expand),
        dest: ($home_dir | path join $config_out.dest | path expand),
        optional: $config_out.optional
      }
    }
    | where $all or ($it.optional == false)
  )

  let missing_sources = ($configs_list | where not ($it.src | path exists))
  if ($missing_sources | is-not-empty) {
    log critical "Missing source files"
    log error $"Source files not found: ($missing_sources.src | str join ', ')"
    return
  }

  let conflicts = ($configs_list | where ($it.dest | path exists))
  if (not $backup and ($conflicts | is-not-empty)) {
    log critical "Destination files already exist"
    log error "Use --backup (-b) to overwrite and create .bak files"
    return
  }

  let conflicts_symlinks = ($conflicts | where ($it.dest | path type) == "symlink")
  if ($conflicts_symlinks | is-not-empty) {
    log critical "Destination is already a symlink"
    log error $"Remove these links manually: ($conflicts_symlinks.dest | str join ', ')"
    return
  }

  def format-path [path: string] { $path | str replace $home_dir ~ }
  $configs_list | each { |entry|
    let log_prefix = if $dry_run { $"(ansi yellow)[DRY] (ansi reset)" } else { "" }

    let dest_dir = ($entry.dest | path dirname)
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

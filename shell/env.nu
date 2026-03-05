$env.ENV_DIR = ($env.HOME | path join ".env")
$env.ENV_LOCAL = ($env.ENV_DIR | path join "local")

@category "env"
def showcmds [] {
  help commands | where command_type == "custom" and category != ""
}

@category "env"
def nuscript-path [
  name: string
  --autoload (-a)
] {
  if $autoload {
    ($nu.user-autoload-dirs | path join $name)
  } else {
    ($nu.default-config-dir | path join $name)
  }
}

let env_configs = {
    "configs/bashrc":    { dest: ".bashrc", optional: true },
    "configs/vimrc":     { dest: ".vimrc", optional: true },
    "configs/gitconfig": { dest: ".gitconfig", optional: true }
    "configs/tmux.conf": { dest: ".tmux.conf", optional: true },

    "shell/config.nu": { dest: (nuscript-path "config.nu") },
    "shell/env.nu":    { dest: (nuscript-path "env.nu") },
    "shell/dev.nu":    { dest: (nuscript-path -a "dev.nu") },
    "shell/aliases.nu":    { dest: (nuscript-path -a "aliases.nu") },

    "configs/helix/config.toml": { dest: ".config/helix/config.toml" },
    "configs/ghostty/config":    { dest: ".config/ghostty/config" },
    "configs/zed/settings.json": { dest: ".config/zed/settings.json" }
    "configs/zed/keymap.json":   { dest: ".config/zed/keymap.json" }

    # TODO: Seperate out darwin vs linux stuff.
    # "configs/aerospace.toml":  { dest: ".aerospace.toml", optional: true },
    # "configs/niri/config.kdl": { dest: ".config/niri/config.kdl", optional: true },
}

@category "env"
def note [] {
  let notes_dir = ($env.ENV_LOCAL | path join "scratch")
  if not ($notes_dir | path exists) {
    mkdir $notes_dir
  }

  let day = (date now | format date "%Y-%b-%d" | str downcase)
  vim ($notes_dir | path join $"($day).md")
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

  let $invalid_configs = ($configs_list | where not $it.skip and $it.error != "")
  if ($invalid_configs | is-not-empty) {
    log critical "Unable to sync configs"
    ($invalid_configs | each { |entry| log error $entry.error })
    return
  }

  def format-path [path: string] { $path | str replace $home_dir ~ }
  $configs_list
  | where $it.skip == false
  | each { |entry|
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

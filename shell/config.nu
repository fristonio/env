# Nushell base configuration
#
# To get detailed list of all available settings:
# config nu --doc | nu-highlight | less -R
$env.config.history.file_format = "sqlite"
$env.config.history.max_size = 1_000_000

$env.config.show_banner = "none"

$env.config.edit_mode = "vi"
$env.config.buffer_editor = "vim"
$env.config.cursor_shape.vi_normal = "block"
$env.config.cursor_shape.vi_insert = "line"

$env.config.completions.algorithm = "fuzzy"
$env.config.completions.sort = "smart"
$env.config.completions.case_sensitive = false
$env.config.completions.use_ls_colors = false

$env.config.footer_mode = "auto"
$env.config.ls.use_ls_colors = false

# Standard aliases
alias l = ls -a
alias ll = ls -la

alias gs = git status
alias gl = git log --oneline --graph --abbrev-commit --decorate

if (which eza | is-not-empty) {
  alias li = eza -l --icons
  alias tree = eza --tree
}

# Create the prompt
def create_left_prompt [] {
    let host = (sys host).hostname
    let main_prompt = $"(ansi blue)[(ansi cyan)($host) (ansi magenta)(ansi reset)(ansi blue)](ansi reset)"

    mut cmd_indicator = $"(ansi blue)$(ansi reset)"
    if ($env.LAST_EXIT_CODE != 0) {
      $cmd_indicator = $"(ansi red)$(ansi reset)"
    }

    let cwd = $"(ansi yellow)($env.PWD | str replace $env.HOME '~')(ansi reset)"

    mut branch_indicator = ((git branch --show-current | complete).stdout | str trim)
    if ($branch_indicator | is-not-empty) {
      $branch_indicator = $"(ansi blue)\( ($branch_indicator)\)(ansi reset)"
    }

    $"($main_prompt) ($cmd_indicator) ($cwd) ($branch_indicator)\n"
}

def create_right_prompt [] {
  let current_time = (date now | format date "%H:%M:%S %p")
  $"(ansi magenta)  (ansi blue)[(ansi green)($current_time)(ansi blue)](ansi reset)"
}

$env.PROMPT_COMMAND = { || create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = { || create_right_prompt }

$env.PROMPT_INDICATOR = $"(ansi cyan)ᗆ (ansi reset)"
$env.PROMPT_INDICATOR_VI_INSERT = $"(ansi cyan)ᗆ (ansi reset)"
$env.PROMPT_INDICATOR_VI_NORMAL = ": "
$env.PROMPT_MULTILINE_INDICATOR = "::: "

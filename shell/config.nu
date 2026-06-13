# Nushell base configuration
#
# To get detailed list of all available settings:
# config nu --doc | nu-highlight | less -R
$env.config.history.file_format = "sqlite"
$env.config.history.max_size = 1_000_000

$env.config.show_banner = "none"

$env.config.edit_mode = "vi"
$env.config.buffer_editor = $env.EDITOR
$env.config.cursor_shape.vi_normal = "block"
$env.config.cursor_shape.vi_insert = "line"

$env.config.completions.algorithm = "fuzzy"
$env.config.completions.sort = "smart"
$env.config.completions.case_sensitive = false
$env.config.completions.use_ls_colors = false

$env.config.footer_mode = "auto"
$env.config.ls.use_ls_colors = false

$env.config.keybindings = ($env.config.keybindings | append [
  ## Configure Vim insert mode keybindings. Match with regular terminal line edit keybinds.

  {
    name: vi_move_to_line_end
    modifier: control
    keycode: char_e
    mode: [vi_insert, vi_normal]
    event: { edit: movetolineend }
  }
  {
    name: vi_move_left
    modifier: control
    keycode: char_b
    mode: vi_insert
    event: { edit: moveleft }
  }
  {
    name: vi_move_right
    modifier: control
    keycode: char_f
    mode: vi_insert
    event: { edit: moveright }
  }
  {
    name: vi_move_word_left
    modifier: alt
    keycode: char_b
    mode: vi_insert
    event: { edit: movewordleft }
  }
  {
    name: vi_move_word_right
    modifier: alt
    keycode: char_f
    mode: vi_insert
    event: { edit: movewordright }
  }
  {
    name: vi_kill_line
    modifier: control
    keycode: char_k
    mode: vi_insert
    event: { edit: cuttolineend }
  }
  {
    name: vi_unix_line_discard
    modifier: control
    keycode: char_u
    mode: vi_insert
    event: { edit: cutfromlinestart }
  }
  {
    name: vi_backward_kill_word
    modifier: control
    keycode: char_w
    mode: vi_insert
    event: { edit: backspaceword }
  }
  {
    name: emacs_yank
    modifier: control
    keycode: char_y
    mode: vi_insert
    event: { edit: pastecutbufferafter }
  }
])

# Create the prompt
def create_left_prompt [] {
    # let host = (sys host).hostname
    let host = whoami
    let main_prompt = $"(ansi blue)[(ansi cyan)($host) (ansi magenta)(ansi reset)(ansi blue)](ansi reset)"

    mut cmd_indicator = $"(ansi blue)$(ansi reset)"
    if $env.LAST_EXIT_CODE != 0 {
        $cmd_indicator = $"(ansi red)$(ansi reset)"
    }

    let cwd = $"(ansi yellow)($env.PWD | str replace $env.HOME '~')(ansi reset)"

    mut branch_indicator = (git branch --show-current | complete).stdout | str trim
    if ($branch_indicator | is-not-empty) {
        $branch_indicator = $"(ansi blue)\( ($branch_indicator)\)(ansi reset)"
    }

    $"($main_prompt) ($cmd_indicator) ($cwd) ($branch_indicator)\n"
}

def create_right_prompt [] {
    let current_time = date now | format date "%H:%M:%S %p"
    $"(ansi magenta)  (ansi blue)[(ansi green)($current_time)(ansi blue)](ansi reset)"
}

$env.PROMPT_COMMAND = {|| create_left_prompt }
# $env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }
$env.PROMPT_COMMAND_RIGHT = {||

}

$env.PROMPT_INDICATOR = $"(ansi cyan)ᗆ (ansi reset)"
$env.PROMPT_INDICATOR_VI_INSERT = $"(ansi cyan)ᗆ (ansi reset)"
$env.PROMPT_INDICATOR_VI_NORMAL = ": "
$env.PROMPT_MULTILINE_INDICATOR = "::: "

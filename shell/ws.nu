$env.WS_TMUX_SOCKET = "nu-server"

# Directories whose single-depth children are treated as "project" spaces by
# `list-workspaces` (see `spaces-project-dirs`).
$env.SPACES_PROJECT_DIRS = ($env.SPACES_PROJECT_DIRS? | default [
    ($env.HOME | path join "forge")
])

# Split direction for a pane in `tmux-setup-session`'s config, in tmux's own
# terms: "horizontal" divides the window left/right (tmux's -h), "vertical"
# divides it top/bottom (tmux's -v, the default when unset).
def tmux-split-flag [pane: record] {
    if ($pane | get -o split | default "vertical") == "horizontal" { "-h" } else { "-v" }
}

# Named layouts for `tmux-setup-session`'s `--preset`, in the same
# `{window_name: [pane, ...]}` shape as a config's `windows` field. `focus`
# picks whichever pane you'd want active right after attaching — tweak
# freely, there's nothing load-bearing about the choice.
let tmux_layout_presets = {
    default: {
        editor: [
            {command: "nvim", focus: true}
        ]
        main: [
            {}
            {split: "horizontal"}
            {split: "vertical"}
        ]
        scratch: [
            {}
        ]
    }
    agent: {
        agent: [
            {focus: true}
        ]
        editor: [
            {command: "nvim"}
        ]
        main: [
            {}
            {split: "horizontal"}
            {split: "vertical"}
        ]
        scratch: [
            {}
        ]
    }
}

# Build a detached tmux session named `name`. With neither `config` nor
# `--preset`, it's created bare (tmux's own default single window/pane).
# `config` (optional) declares its layout:
#   {
#       directory: ""                     # optional; defaults to $env.PWD
#       windows: {
#           window_name: [
#               {command: "nvim", focus: true}
#               {command: "lazygit", split: "horizontal"}
#           ]
#       }
#   }
# `--preset` supplies `windows` from `tmux_layout_presets` instead — ignored
# if `config.windows` is already given.
def tmux-setup-session [name: string, config?: record, --preset: string = ""] {
    let raw_directory = if $config == null { "" } else {
        $config | get -o directory | default ""
    }
    let directory = if ($raw_directory | is-empty) { $env.PWD } else {
        $raw_directory | path expand
    }

    if (^tmux -L $env.WS_TMUX_SOCKET has-session -t $name | complete).exit_code == 0 {
        print $"(ansi yellow)Session '($name)' already exists, skipping setup(ansi reset)"
        return
    }

    $env.SHELL = $nu.current-exe

    let config_windows = if $config == null { null } else {
        $config | get -o windows
    }
    let windows_config = if $config_windows != null {
        $config_windows
    } else if ($preset | is-not-empty) {
        let preset_windows = $tmux_layout_presets | get -o $preset
        if $preset_windows == null {
            error make {msg: $"Unknown preset '($preset)' — available: ($tmux_layout_presets | columns | str join ', ')"}
        }
        $preset_windows
    } else {
        null
    }

    if $windows_config == null {
        ^tmux -L $env.WS_TMUX_SOCKET new-session -d -s $name -c $directory
        print $"(ansi green)✓(ansi reset) Created session (ansi cyan)($name)(ansi reset)"
        return
    }

    let windows = $windows_config | transpose name panes
    if ($windows | is-empty) {
        error make {msg: "config.windows must have at least one window"}
    }

    mut focus_target: any = null

    for i in 0..<($windows | length) {
        let win = $windows | get $i
        let target = $"($name):($win.name)"

        if $i == 0 {
            ^tmux -L $env.WS_TMUX_SOCKET new-session -d -s $name -n $win.name -c $directory
        } else {
            ^tmux -L $env.WS_TMUX_SOCKET new-window -t $name -n $win.name -c $directory
        }

        for j in 0..<($win.panes | length) {
            let pane = $win.panes | get $j

            if $j > 0 {
                ^tmux -L $env.WS_TMUX_SOCKET split-window -t $target (tmux-split-flag $pane) -c $directory
            }

            let command = $pane | get -o command | default ""
            if ($command | is-not-empty) {
                ^tmux -L $env.WS_TMUX_SOCKET send-keys -t $target $command Enter
            }

            if ($pane | get -o focus | default false) {
                $focus_target = {window: $win.name, index: $j}
            }
        }
    }

    if $focus_target != null {
        let pane_target = $"($name):($focus_target.window).($focus_target.index)"
        ^tmux -L $env.WS_TMUX_SOCKET select-window -t $"($name):($focus_target.window)"
        ^tmux -L $env.WS_TMUX_SOCKET select-pane -t $pane_target
    }

    print $"(ansi green)✓(ansi reset) Set up session (ansi cyan)($name)(ansi reset)"
}

# Start (or attach to) a session on the ws tmux socket, running nu as the
# session's shell. With --preset, the session (if it doesn't exist yet) is
# first laid out via `tmux-setup-session` before attaching.
@category ws
@search-terms tmux workspace
def nmux [
  --name (-s): string = "", # Name of the session
  --preset (-p): string = "", # Layout preset (see `tmux_layout_presets`) to set up if the session doesn't exist yet
  ...args # Extra args for tmux command
] {
    let running_in_tmux = $env.TMUX? | is-not-empty
    if ($name | is-empty) and $running_in_tmux {
        print $"(ansi yellow)Already running in tmux session, specify '--name/-s' to create session(ansi reset)"
        return
    }

    let session_name = if ($name | is-empty) {
        namegen {|n| (^tmux -L $env.WS_TMUX_SOCKET has-session -t $n | complete).exit_code != 0 }
    } else { $name }

    if ($preset | is-not-empty) {
        tmux-setup-session $session_name --preset $preset
    }

    with-env { SHELL: $nu.current-exe } {
        ^tmux -L $env.WS_TMUX_SOCKET new -A -s $session_name ...$args
    }
}

# Workspace manager — inspect and jump between tmux sessions/panes.
alias ws = cmds "ws"

let ws_tmux_info_format = '{
  "session_id": "#{session_id}",
  "session_name": "#{session_name}",
  "session_created_at": #{session_created},
  "session_attached": #{?session_attached,true,false},
  "session_path": "#{session_path}",

  "window_id": "#{window_id}",
  "window_index": #{window_index},
  "window_name": "#{window_name}",

  "pane_id": "#{pane_id}",
  "pane_index": #{pane_index},

  "pid": #{pane_pid},
  "command": "#{pane_current_command}",
  "title": "#{pane_title}",
  "path": "#{pane_current_path}",

  "active": #{?pane_active,true,false}
}'

# Returns structured information about active TMUX panes.
@category ws
@search-terms tmux workspace
def "ws info" [] {
    let data = ^tmux -L $env.WS_TMUX_SOCKET list-panes -a -F $ws_tmux_info_format | jq -s '.' | from json

    return ($data
        | group-by session_id
        | items { |session_id, session_panes|
            let session_info = ($session_panes
                | first
                | select session_id session_name session_created_at session_attached session_path
                | rename id name created_at attached path
                | update created_at {|r| ($r.created_at * 1_000_000_000) | into datetime }
            )

            let windows = ($session_panes
                | group-by window_id
                | items { |window_id, window_panes|
                    let window_info = ($window_panes
                        | first
                        | select window_id window_index window_name
                        | rename id index name
                    )
                    let panes = ($window_panes
                        | select pane_id pane_index pid command title path active
                        | rename id index pid command title path active
                        | sort-by index
                    )

                    $window_info | insert panes $panes
                }
                | sort-by index
            )

            $session_info | insert windows $windows
        }
    )
}

# Whether the current shell is attached to the tmux server at $WS_TMUX_SOCKET
# (as opposed to some other, unrelated tmux server).
def ws-in-target [] {
    let tmux_env = $env.TMUX? | default ""
    if ($tmux_env | is-empty) {
        return false
    }
    (
        $tmux_env
        | split row ","
        | first
        | path basename
    ) == $env.WS_TMUX_SOCKET
}

def ws-current-session-id [] {
    if (ws-in-target) {
        ^tmux -L $env.WS_TMUX_SOCKET display-message -p '#{session_id}' | str trim
    } else { "" }
}

def ws-session-list [] {
    let current_session_id = ws-current-session-id
    ws info | each {|s|
        # rounded to whole seconds so it doesn't print with ms/µs/ns noise
        let age = ((date now) - $s.created_at)
        {
            id: $s.id
            name: $s.name
            windows: ($s.windows | length)
            panes: ($s.windows | each {|w| $w.panes | length } | math sum)
            age: ($age - ($age mod 1min))
            attached: $s.attached
            current: ($s.id == $current_session_id)
            path: ($s.path | str replace $env.HOME "~")
            raw_path: $s.path
        }
    }
}

def ws-pane-list [] {
    let current_session_id = ws-current-session-id
    ws info | each {|s|
        $s.windows | each {|w|
            $w.panes | each {|p|
                {
                    id: $"($s.id):($w.id):($p.id)",
                    session: $s.name
                    window: $w.name
                    title: $p.title
                    command: $p.command
                    path: ($p.path | str replace $env.HOME "~")
                    active: $p.active
                    session_attached: $s.attached
                    current: (($s.id == $current_session_id) and $p.active)
                }
            }
        } | flatten
    } | flatten
}

# List sessions, or (with --panes) one entry per pane across all sessions.
# With --interactive, browse the list in an fzf picker with actions to
# attach (enter) or delete (ctrl-d) directly, instead of a plain table dump.
# --fullscreen makes that picker take over the whole terminal instead of an
# inline block.
@category ws
@search-terms tmux workspace
def "ws list" [
    --panes(-p)
    --interactive(-i)
    --attach(-a)
    --preview
    --fullscreen
] {
    if $interactive {
        return (ws-list-interactive $panes $preview $fullscreen $attach)
    }
    if $panes { ws-pane-list } else { ws-session-list }
}

# Pre-colored (not just plain) so callers can pass `null` for this column's
# color — format-table measures/pads by visible width, ignoring the ANSI it
# carries.
def ws-state-icon [current: bool, attached: bool] {
    if $current {
        $"(ansi green)●(ansi reset)"
    } else if $attached {
        $"(ansi yellow)◐(ansi reset)"
    } else {
        $"(ansi dark_gray)○(ansi reset)"
    }
}

# Split a composite pane id ("session_id:window_id:pane_id", as built by
# ws-pane-list) into its parts.
def ws-parse-pane-id [id: string] {
    let parts = $id | split row ":"
    {
        session: ($parts | get 0)
        window: ($parts | get 1)
        pane: ($parts | get 2)
    }
}

def ws-session-columns [items: list<record>] {
    {
        headers: [
            "ID"
            "STATUS"
            "NAME"
            "AGE"
            "PATH"
            "COUNT"
        ]
        colors: [
            "dark_gray"
            null
            "cyan"
            null
            "yellow"
            "dark_gray"
        ]
        rows: ($items | each {|s| [
            $s.id
            (ws-state-icon $s.current $s.attached)
            $s.name
            (format-age $s.age)
            $s.path
            $"W:($s.windows) P:($s.panes)"
        ]})
    }
}

# Same shape as ws-session-columns, but for individual panes across all sessions.
def ws-pane-columns [items: list<record>] {
    {
        headers: [
            "ID"
            "ACTIVE"
            "COMMAND"
            "SESSION"
            "STATUS"
            "PATH"
            "TITLE"
        ]
        colors: [
            "dark_gray"
            null
            "blue"
            "magenta"
            null
            "yellow"
            "cyan"
        ]
        rows: ($items | each {|p| [
            $p.id
            (ws-state-icon $p.current $p.active)
            $p.command
            $p.session
            (ws-state-icon $p.current $p.session_attached)
            $p.path
            $p.title
        ]})
    }
}

# Tmux target (session or pane id) whose active pane content fzf's --preview
# shows, parallel to `items`.
def ws-preview-targets [items: list<record>, panes: bool] {
    if $panes {
        $items | each {|p| (ws-parse-pane-id $p.id).pane }
    } else {
        $items | each {|s| $s.id }
    }
}

# Run `rows`/`headers`/`colors` (already built by the caller, parallel to
# `items`) through the fzf-nu picker and map whatever got picked back to its
# source item.
#
# `preview_targets`, parallel to `items`, gives the tmux target (session or
# pane id) whose active pane content fzf previews when `--preview` is set.
#
# Returns one of:
#   {action: "selected", item: <record>}
#   {action: "create", name: <string>}   (only reachable when allow_create)
#   {action: "cancelled"}
def ws-resolve-pick [
    items: list<record>
    rows: list<list<any>>
    headers: list<string>
    colors: list<any>
    query: string
    allow_create: bool
    --preview-targets: list<string>
    --preview
    --preview-width: int = 0
] {
    let rendered = (render-fzf-table $rows --headers $headers --colors $colors)
    let fzf_items = (
        fzf-table-items $rendered.data $items --preview-targets (if $preview { $preview_targets } else { [] })
    )

    let preview_cmd = if $preview {
        $"tmux -L ($env.WS_TMUX_SOCKET) capture-pane -ep -t {}"
    } else { "" }

    let result = (
        fzf-nu $fzf_items --header $rendered.header --query $query --allow-create=$allow_create --preview-cmd $preview_cmd --preview-width $preview_width --min-height (if $preview { 32 } else { 0 })
    )

    if $result.action == "cancelled" {
        return {action: "cancelled"}
    }
    if $result.action == "create" {
        return {action: "create", name: $result.query}
    }
    {action: "selected", item: $result.value}
}

# Resolve a session target: an exact, unambiguous name match short-circuits
# straight to it; otherwise an fzf picker opens (pre-filled with `name` as the
# query). When `allow_create` is set and the picker query matches nothing,
# returns a "create" action instead of cancelling.
def ws-session-resolve [name: string, allow_create: bool, --preview] {
    let items = (ws-session-list)

    if ($name | is-not-empty) {
        let matches = $items | where name == $name
        if ($matches | length) == 1 {
            return {
                action: "selected"
                item: ($matches | first)
            }
        }
    }

    let cols = (ws-session-columns $items)
    let preview_targets = (ws-preview-targets $items false)

    ws-resolve-pick $items $cols.rows $cols.headers $cols.colors $name $allow_create --preview-targets $preview_targets --preview=$preview
}

# Same as ws-session-resolve, but for individual panes across all sessions.
def ws-pane-resolve [name: string, allow_create: bool, --preview] {
    let items = (ws-pane-list)

    if ($name | is-not-empty) {
        let matches = $items | where session == $name
        if ($matches | length) == 1 {
            return {
                action: "selected"
                item: ($matches | first)
            }
        }
    }

    let cols = (ws-pane-columns $items)
    let preview_targets = (ws-preview-targets $items true)

    ws-resolve-pick $items $cols.rows $cols.headers $cols.colors $name $allow_create --preview-targets $preview_targets --preview=$preview --preview-width 40
}

def ws-list-interactive [
    panes: bool
    preview: bool
    fullscreen: bool
    attach: bool
] {
    loop {
        let items = if $panes { ws-pane-list } else { ws-session-list }
        if ($items | is-empty) {
            print $"(ansi yellow)No (if $panes { "panes" } else { "sessions" }) found(ansi reset)"
            return
        }

        let cols = if $panes { ws-pane-columns $items } else { ws-session-columns $items }
        let rendered = (
            render-fzf-table $cols.rows --headers $cols.headers --colors $cols.colors
        )

        let preview_targets = if $preview { ws-preview-targets $items $panes } else { [] }
        let fzf_items = (fzf-table-items $rendered.data $items --preview-targets $preview_targets)

        let preview_cmd = if $preview {
            $"tmux -L ($env.WS_TMUX_SOCKET) capture-pane -ep -t {}"
        } else { "" }

        let attach_action = {|item|
            if $item == null { return "noop" }
            if $panes { ws-pane-goto $item } else { ws-session-goto $item.name }
            "attach"
        }

        let delete_action = {|item|
            if $item == null { return "noop" }
            if $panes {
                let label = $"Pane (ansi cyan)($item.id)(ansi reset) in session (ansi cyan)($item.session)(ansi reset)"
                (ws-confirm-and-delete
                    $item
                    $label
                    {|| ^tmux -L $env.WS_TMUX_SOCKET kill-pane -t (ws-parse-pane-id $item.id).pane }
                )
            } else {
                let label = $"Session (ansi cyan)($item.name)(ansi reset)"
                (ws-confirm-and-delete
                    $item
                    $label
                    {|| ^tmux -L $env.WS_TMUX_SOCKET kill-session -t $item.name }
                )
            }
            "delete"
        }

        mut actions = [
            {key: "ctrl-d", label: "delete", action: $delete_action}
        ]
        if not $attach {
            $actions ++= [
                {key: "ctrl-i", label: "attach", action: $attach_action}
            ]
        }

        let result = (
            fzf-nu $fzf_items --header $rendered.header
              --preview-cmd $preview_cmd
              --preview-width (if $panes { 40 } else { 0 })
              --select-label "attach"
              --min-height (if $preview { 20 } else { 0 })
              --fullscreen=$fullscreen
              --actions $actions
        )

        if $result.action == "cancelled" { return }
        let outcome = $result.value
        if $attach {
            do $attach_action $outcome
            return
        }

        # delete/noop loop back to refresh the list; attach has already
        # happened as a side effect inside the action closure.
        if $outcome == "delete" or $outcome == "noop" {
            continue
        }
        if $outcome == "attach" {
            return
        }

        # Plain enter: an actioned outcome is one of the tag strings above,
        # so anything else is the bare picked session/pane record — return
        # its full info instead of attaching.
        return (
            if $panes { $outcome } else {
                ws info | where id == $outcome.id | first
            }
        )
    }
}

# Switch the current client (inside tmux) or attach (outside tmux) to a session.
def ws-session-goto [session_name: string] {
    if (ws-in-target) {
        ^tmux -L $env.WS_TMUX_SOCKET switch-client -t $session_name
    } else {
        ^tmux -L $env.WS_TMUX_SOCKET attach -t $session_name
    }
}

# Focus a specific pane's window before going to its session.
def ws-pane-goto [item: record] {
    let parts = (ws-parse-pane-id $item.id)
    ^tmux -L $env.WS_TMUX_SOCKET select-window -t $parts.window
    ^tmux -L $env.WS_TMUX_SOCKET select-pane -t $parts.pane
    ws-session-goto $item.session
}

# Create a new detached session (named `query`, or a generated name if empty)
# and go to it. Used by `ws switch` when nothing matched.
def ws-switch-create [query: string] {
    let new_name = if ($query | is-empty) {
        namegen {|n| (^tmux -L $env.WS_TMUX_SOCKET has-session -t $n | complete).exit_code != 0 }
    } else { $query }

    tmux-setup-session $new_name
    ws-session-goto $new_name
}

# Confirm (only if `item` is the one you're currently in) then run `kill`.
def ws-confirm-and-delete [item: record, label: string, kill: closure] {
    let prompt = if $item.current {
        $"($label) (ansi yellow)is currently active. Are you sure? [y/n]: (ansi reset)"
    } else {
        $"(ansi yellow)Delete ($label)(ansi yellow)? [y/n]: (ansi reset)"
    }
    if not (confirm $prompt) {
        return
    }
    do $kill
    print $"(ansi green)✓(ansi reset) Deleted ($label)"
}

def ws-session-attach [name: string, --preview] {
    let resolved = ws-session-resolve $name false --preview=$preview
    if $resolved.action == "cancelled" {
        print $"(ansi yellow)No session selected to attach(ansi reset)"
        return
    }
    ws-session-goto $resolved.item.name
}

def ws-pane-attach [name: string, --preview] {
    let resolved = ws-pane-resolve $name false --preview=$preview
    if $resolved.action == "cancelled" {
        print $"(ansi yellow)No pane selected to attach(ansi reset)"
        return
    }
    ws-pane-goto $resolved.item
}

# Attach to a session, picking it via fzf if `name` is omitted or ambiguous.
@category ws
@search-terms tmux workspace
def "ws attach" [name?: string, --panes(-p), --preview] {
    if $panes {
        ws-pane-attach ($name | default "") --preview=$preview
    } else {
        ws-session-attach ($name | default "") --preview=$preview
    }
}

def ws-session-delete [name: string, --preview] {
    let resolved = ws-session-resolve $name false --preview=$preview
    if $resolved.action == "cancelled" {
        print $"(ansi yellow)No session selected to delete(ansi reset)"
        return
    }
    let item = $resolved.item
    let label = $"session (ansi cyan)($item.name)(ansi reset)"
    (ws-confirm-and-delete
        $item
        $label
        {|| ^tmux -L $env.WS_TMUX_SOCKET kill-session -t $item.name }
    )
}

def ws-pane-delete [name: string, --preview] {
    let resolved = ws-pane-resolve $name false --preview=$preview
    if $resolved.action == "cancelled" {
        print $"(ansi yellow)No pane selected to delete(ansi reset)"
        return
    }
    let item = $resolved.item
    let label = $"pane (ansi cyan)($item.id)(ansi reset) in session (ansi cyan)($item.session)(ansi reset)"
    (ws-confirm-and-delete
        $item
        $label
        {|| ^tmux -L $env.WS_TMUX_SOCKET kill-pane -t (ws-parse-pane-id $item.id).pane }
    )
}

# Delete a session (or, with --panes, just the picked pane), picking it via
# fzf if `name` is omitted or ambiguous. Confirms before deleting the pane/
# session you're currently in.
@category ws
@search-terms tmux workspace
def "ws delete" [name?: string, --panes(-p), --preview] {
    if $panes { ws-pane-delete ($name | default "") --preview=$preview } else { ws-session-delete ($name | default "") --preview=$preview }
}

def ws-session-switch [name: string, --preview] {
    let resolved = ws-session-resolve $name true --preview=$preview
    if $resolved.action == "cancelled" {
        print $"(ansi yellow)No session selected(ansi reset)"
        return
    }
    if $resolved.action == "create" {
        ws-switch-create $resolved.name
        return
    }
    ws-session-goto $resolved.item.name
}

def ws-pane-switch [name: string, --preview] {
    let resolved = ws-pane-resolve $name true --preview=$preview
    if $resolved.action == "cancelled" {
        print $"(ansi yellow)No pane selected(ansi reset)"
        return
    }
    if $resolved.action == "create" {
        ws-switch-create $resolved.name
        return
    }
    ws-pane-goto $resolved.item
}

# Like `ws attach`, but creates a new session when `name` (or the fzf query,
# if no match) doesn't resolve to an existing one.
@category ws
@search-terms tmux workspace
def "ws switch" [name?: string, --panes(-p), --preview] {
    if $panes {
        ws-pane-switch ($name | default "") --preview=$preview
    } else {
        ws-session-switch ($name | default "") --preview=$preview
    }
}

let spaces_icons = {
    home: {icon: "", color: "red"}
    repo: {icon: "", color: "cyan"}
    pr: {icon: "", color: "magenta"}
    scratch: {icon: "", color: "yellow"}
    worktree: {icon: "", color: "green"}
    project: {icon: "", color: "blue"}
    dir: {icon: "", color: "light_gray"}
}
def spaces-icon [space: record] {
    let kind = if ($space.path | path expand) == ($env.ENV_DIR | path expand) { "home" } else { $space.type }
    let entry = $spaces_icons | get -o $kind | default $spaces_icons.dir

    $"(ansi $entry.color)($entry.icon)(ansi reset)"
}

# tmux sessions (from ws-session-list) rooted at `path`, compared on the
# expanded absolute path so "~"-shortened session paths still match.
def ws-sessions-for-path [sessions: list<record>, path: string] {
    let target = $path | path expand
    $sessions
    | where {|s| ($s.raw_path | path expand) == $target }
    | select id name attached current windows panes
}

# Every discoverable workspace: bare repos, branch/PR worktrees, scratch dirs,
# known project roots, and zoxide history — deduped in that preference order,
# each paired with the tmux sessions (if any) rooted at its path.
# Sorted, most to least relevant:
#   1. has a current session      (any type)
#   2. has an attached session    (any type)
#   3. has a (detached) session   (any type)
#   ---
#   4. repos
#   5. worktrees (incl. PR checkouts)
#   6. projects
#   7. scratches
#   ---
#   8. exclusive zoxide dirs
# Ties within 4-8 break by zoxide's own (frecency) order.
def list-workspaces [--dir-limit: int = 16] {
    let sessions = ws-session-list

    let repos = wt-repo-list
    let repo_spaces = $repos | each {|r| {
        path: $r.path
        type: "repo", 
        sessions: (ws-sessions-for-path $sessions $r.path)
    }}

    let worktrees = $repos | each {|r| git-wt-checkouts $r.path } | flatten
    let pr_prefix = $"refs/heads/($env.WT_PULL_REQUEST_PREFIX)/"
    let is_pr = {|w|
        ($w.branch? | default "") | str starts-with $pr_prefix
    }

    let pr_spaces = $worktrees | where {|w| do $is_pr $w } | each {|w| {
        path: $w.worktree
        type: "pr", 
        sessions: (ws-sessions-for-path $sessions $w.worktree)
    }}

    let scratch_spaces = (
        $repos
        | each {|r|
            let scratch_dir = $r.path | path join "scratch"
            if ($scratch_dir | path exists) {
                ls $scratch_dir | where type == dir | each {|d| {
                    path: $d.name
                    type: "scratch", 
                    sessions: (ws-sessions-for-path $sessions $d.name)
                }}
            } else { [] }
        }
        | flatten
    )

    let worktree_spaces = $worktrees | where {|w| not (do $is_pr $w) } | each {|w| {
        path: $w.worktree
        type: "worktree", 
        sessions: (ws-sessions-for-path $sessions $w.worktree)
    }}

    let project_spaces = (
        $env.SPACES_PROJECT_DIRS
        | where {|d| $d | path exists }
        | each {|d| ls $d | where type == dir | each {|c| {
            path: $c.name
            type: "project", 
            sessions: (ws-sessions-for-path $sessions $c.name)
        }} }
        | flatten
    )

    let known_paths = (
        [$repo_spaces, $pr_spaces, $scratch_spaces, $worktree_spaces, $project_spaces]
        | flatten
        | each {|s| $s.path | path expand }
    )

    # `zoxide query -l` is already frecency-sorted (highest first); reuse the
    # same run both to build the "exclusive dirs" tier and, via `zoxide_rank`
    # below, to break ties within every other tier by that same order.
    let zoxide_lines = if (which zoxide | is-not-empty) {
        ^zoxide query -l | lines
    } else { [] }
    let zoxide_rank = (
        $zoxide_lines
        | enumerate
        | each {|it| {path: ($it.item | path expand), rank: $it.index} }
    )

    let dir_spaces = (
        $zoxide_lines
        | where {|p| ($p | path expand) not-in $known_paths }
        | first $dir_limit
        | each {|p| {
            path: $p
            type: "dir", 
            sessions: (ws-sessions-for-path $sessions $p)
        }}
    )

    let rank_of = {|path|
        let hit = $zoxide_rank | where path == ($path | path expand) | first
        if $hit == null { 999999 } else { $hit.rank }
    }

    let type_rank = {|t| match $t {
        repo => 0
        worktree => 1
        pr => 1
        project => 2
        scratch => 3
        _ => 4
    } }

    let session_rank = {|s|
        if ($s.sessions | any {|x| $x.current }) {
            0
        } else if ($s.sessions | any {|x| $x.attached }) {
            1
        } else if ($s.sessions | is-not-empty) {
            2
        } else {
            3
        }
    }

    (
        [$repo_spaces, $pr_spaces, $worktree_spaces, $project_spaces, $scratch_spaces, $dir_spaces]
        | flatten
        | each {|s| $s | insert sort_key (
            (do $session_rank $s) * 10_000_000 + (do $type_rank $s.type) * 1_000_000 + (do $rank_of $s.path)
        )}
        | sort-by sort_key
        | reject sort_key
    )
}

# Attach to `space`'s tmux session: the one existing session if there's
# exactly one, a picker if there are several, or a freshly created session
# (rooted at the space's path) if there are none.
def space-attach [space: record, --fullscreen(-f), --preset(-p): string = ""] {
    if ($space.sessions | length) == 1 {
        ws-session-goto ($space.sessions | first | get name)
        return
    }

    if ($space.sessions | length) > 1 {
        let cols = {
            headers: ["NAME" "STATUS" "COUNT"]
            colors: [
                "cyan"
                null
                "dark_gray"
            ]
            rows: (
                $space.sessions
                | each {|s| [
                    $s.name
                    (ws-state-icon $s.current $s.attached)
                    $"W:($s.windows) P:($s.panes)"
                ]}
            )
        }
        let rendered = (
            render-fzf-table $cols.rows --headers $cols.headers --colors $cols.colors
        )
        let fzf_items = (fzf-table-items $rendered.data $space.sessions)
        let result = (
            fzf-nu $fzf_items --fullscreen=$fullscreen --header $rendered.header --select-label "attach"
        )
        if $result.action != "selected" or $result.value == null {
            return
        }
        ws-session-goto $result.value.name
        return
    }

    let new_name = namegen {|n| (^tmux -L $env.WS_TMUX_SOCKET has-session -t $n | complete).exit_code != 0 }
    tmux-setup-session $new_name {directory: $space.path} --preset $preset
    ws-session-goto $new_name
}

# Interactive space manager over `list-workspaces`: repos, worktrees, PR
# checkouts, scratch dirs, known projects, and zoxide history in one picker.
@category ws
@search-terms tmux workspace git project zoxide
def --env space [--attach(-a), --fullscreen(-f), --preset(-p): string = ""] {
    let items = list-workspaces
    if ($items | is-empty) {
        print $"(ansi yellow)No spaces found(ansi reset)"
        return
    }

    let cols = {
        headers: ["" "SESSIONS" "PATH"]
        colors: [
            null
            null
            null
        ]
        rows: ($items | each {|s| [
            (spaces-icon $s)
            (
              if $s.sessions == null {
                $'(ansi dark_gray)<none>(ansi reset)'
              } else {
                $s.sessions | each { $'(ws-state-icon $in.current $in.attached) (ansi magenta)($in.name)(ansi reset)' } | str join ' '
              }
            )
            ($s.path | str replace $env.HOME "~")
        ]})
    }
    let rendered = (
        render-fzf-table $cols.rows --headers $cols.headers --colors $cols.colors
    )
    let fzf_items = (fzf-table-items $rendered.data $items)

    let result = if $attach {
        fzf-nu $fzf_items --fullscreen --header $rendered.header --select-label "attach"
    } else {
        let attach_action = {|item|
            if $item == null { return "noop" }
            space-attach $item --preset $preset
            "attach"
        }
        fzf-nu $fzf_items --header $rendered.header --select-label "cd" --actions [
            {key: "ctrl-i", label: "attach", action: $attach_action}
        ]
    }

    if $result.action == "cancelled" { return }

    let outcome = $result.value
    if $attach {
        space-attach $outcome --preset $preset
        return
    }
    if $outcome == "attach" or $outcome == "noop" { return }
    cd $outcome.path
}

alias "space attach" = space --attach

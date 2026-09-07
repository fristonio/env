# Grapheme length ignoring ANSI escape sequences, so pre-colored cell values
# (e.g. a glyph already wrapped in `ansi green ... ansi reset`) measure by
# what's actually visible on screen rather than their raw byte length.
def visible-length [text: string] {
    ($text | ansi strip | str length -g)
}

def truncate-string [text: string, width: int] {

    # "…" renders double-width in some terminals despite being a single
    # grapheme, which throws off column alignment; "." is unambiguously
    # single-width everywhere.
    if (visible-length $text) <= $width {
        $text
    } else if $width <= 1 {
        "."
    } else {
        # Truncating mid-string would risk slicing through an ANSI escape
        # sequence, so fall back to stripping color before cutting — only
        # reachable for a cell that's both pre-colored *and* longer than its
        # column's cap, which callers avoid in practice.
        (($text | ansi strip) | str substring -g 0..($width - 2)) + "."
    }
}

# Number of columns implied by `rows`/`headers` — 0 if both are empty.
def table-column-count [rows: list<list<any>>, headers: list<string>]: nothing -> int {
    if ($headers | is-not-empty) {
        $headers | length
    } else if ($rows | is-not-empty) {
        $rows | first | length
    } else {
        0
    }
}

# Each column's natural width: the longest cell in it by *visible* width,
# header included, uncapped.
def natural-column-widths [rows: list<list<any>>, headers: list<string>]: nothing -> list<int> {
    let ncols = table-column-count $rows $headers
    0..<$ncols | each {|i|
        let lens = $rows | each {|r| visible-length ($r | get $i | into string) }
        let header_len = if ($headers | is-not-empty) { visible-length ($headers | get $i) } else { 0 }
        [$header_len] | append $lens | math max
    }
}

# Render `rows` (each a list of cell values, plain or already ANSI-colored)
# as a column-aligned table string, ready to feed straight into fzf. Column
# widths are each column's natural width (see `natural-column-widths`),
# capped per-column at `--max-length` (parallel to the columns; omit an
# entry, or the whole list, to leave that column uncapped); longer cells are
# truncated with an ellipsis.
#
# `--colors` is optional (omit it, or the whole table stays uncolored); when
# given, it's parallel to the columns: `colors.i` is an `ansi`-recognized
# color name (e.g. "cyan") that column's already-truncated text gets wrapped
# in. Use `null` for a column that should stay as-is — either genuinely
# uncolored, or already pre-colored by the caller (e.g. a status glyph
# picking its own color per row).
def format-table [
    rows: list<list<any>>
    --headers: list<string>
    --colors: list<any>
    --max-length: list<int> = []
    --separator: string = " "
] {
    let ncols = table-column-count $rows $headers

    if $ncols == 0 {
        return ""
    }

    let naturals = natural-column-widths $rows $headers
    let widths = (0..<$ncols | each {|i|
        let natural = $naturals | get $i
        let cap = $max_length | get -o $i
        if $cap != null and $natural > $cap { $cap } else { $natural }
    })

    let render_row = {|row, is_header|
        0..<$ncols | each {|i|
            let width = $widths | get $i
            let truncated = truncate-string ($row | get $i | into string) $width
            # no color at all for the header, or for this column -> as-is
            let color = if $is_header or ($colors == null) { null } else { $colors | get -o $i }
            let colored = if $color == null { $truncated } else { $"(ansi $color)($truncated)(ansi reset)" }
            # pad on the pre-formatter (but possibly already-colored) visible
            # length so ansi codes never throw off alignment
            let pad = $width - (visible-length $truncated)
            $colored + (if $pad > 0 { "" | fill -w $pad } else { "" })
        } | str join $separator
    }

    let header_line = if ($headers | is-not-empty) {
        [
            (do $render_row $headers true)
        ]
    } else { [] }
    let data_lines = $rows | each {|r| do $render_row $r false }

    ($header_line | append $data_lines) | str join "\n"
}

def format-age [dur: duration] {
    if $dur < 1min {
        $"(($dur / 1sec) | math floor)s"
    } else if $dur < 1hr {
        $"(($dur / 1min) | math floor)m"
    } else if $dur < 1day {
        $"(($dur / 1hr) | math floor)h"
    } else {
        $"(($dur / 1day) | math floor)d"
    }
}

# Per-column caps that fit `naturals` into `budget`: columns whose natural
# width is already at or under their fair (budget / remaining-columns) share
# keep it in full; the leftover from those rolls forward to the columns that
# actually need it, which then split whatever's left evenly. Processing
# narrowest-first means once one column doesn't fit its fair share, no wider
# one will either — so everything from there on is capped as "wide".
def fair-share-widths [naturals: list<int>, budget: int]: nothing -> list<int> {
    let n = $naturals | length
    if $n == 0 {
        return []
    }

    let order = (
        $naturals
        | enumerate
        | sort-by item
        | get index
    )

    mut widths = $naturals | each {|_| 0}
    mut remaining = $budget
    mut remaining_cols = $n
    mut wide_start = $n

    for pos in 0..<$n {
        let idx = $order | get $pos
        let natural = $naturals | get $idx
        let share = ($remaining / $remaining_cols) | into int
        if $natural <= $share {
            $widths = ($widths | update $idx $natural)
            $remaining -= $natural
            $remaining_cols -= 1
        } else {
            $wide_start = $pos
            break
        }
    }

    if $wide_start < $n {
        let wide_indices = $order | skip $wide_start
        let wide_share = ([
            (($remaining / ($wide_indices | length)) | into int)
            1
        ] | math max)
        for idx in $wide_indices {
            $widths = ($widths | update $idx $wide_share)
        }
    }

    $widths
}

# Render `rows` as a format-table sized to the real terminal width (so it
# never wraps), then split it into its sticky header line and per-item data
# lines — the shape fzf-nu callers need to turn a table into picker items.
def render-fzf-table [rows: list<list<any>>, --headers: list<string>, --colors: list<any>]: nothing -> record {
    # Budget column width off the real terminal width so long values can't
    # push a row wider than the screen (which wraps it and wrecks alignment).
    # Narrow columns (id, state, age, ...) get their natural width and never
    # claim more than that; `fair-share-widths` rolls what they don't use
    # forward to columns (path, ...) that actually need the room.
    let separator = "   "
    let ncols = $headers | length
    let overhead = 4 + (($ncols - 1) * ($separator | str length -g))
    let budget = ([
        ((term size).columns - $overhead)
        (4 * $ncols)
    ] | math max)
    let naturals = (natural-column-widths $rows $headers)
    let max_length = (fair-share-widths $naturals $budget)

    let table = (
        format-table $rows --headers $headers --colors $colors --max-length $max_length --separator $separator
    )
    let lines = $table | lines
    {
        header: ($lines | first)
        data: ($lines | skip 1)
    }
}

# Zip `data_lines` (rendered row text, e.g. from render-fzf-table) with
# `values` (the source record each line came from) into the
# {text, value, preview_arg} shape fzf-nu expects as its `items`.
def fzf-table-items [data_lines: list<string>, values: list<any>, --preview-targets: list<string>]: nothing -> list<record> {
    $data_lines | enumerate | each {|it| {
        text: $it.item
        value: ($values | get $it.index)
        preview_arg: (if ($preview_targets | is-not-empty) { $preview_targets | get $it.index } else { "" })
    }}
}

# Generic fzf picker. Each item in `items` is a record with:
#   text          — display string shown in the list (ansi allowed)
#   value         — arbitrary data returned when the item is picked
#   preview_arg   — optional string fed to `--preview-cmd` in place of `{}`
#
# Returns one of:
#   {action: "selected", value: <item.value>}
#   {action: "create", query: <string>}   (only reachable with --allow-create)
#   {action: "cancelled"}
#
# `--header` is static, non-selectable text shown above the list (fzf's
# `--header`). `--allow-create` prints the typed query (fzf's `--print-query`)
# and surfaces it as a "create" action when nothing got selected. `--actions`
# maps extra keypresses (fzf's `--expect`) to a closure invoked with the
# picked item's `value`; its return value becomes the "selected" value. Each
# action's `label` (falling back to its key) and `--select-label` (describing
# plain Enter) are used to auto-build a keybind hint footer — callers no
# longer need to hand-roll one into `--header`. `--min-height` (fzf's
# `--min-height`) puts a floor under fzf's adaptive `--height` so a preview
# pane doesn't get squeezed down to nothing when the list is short.
# `--fullscreen` skips `--height`/`--min-height` altogether so fzf takes over
# the whole terminal instead of an inline block. `--preview-width` overrides
# the preview pane's share of the window (fzf's own default is 50); ignored
# without `--preview-cmd`.
def fzf-nu [
    items: list<record>
    --preview-cmd: string
    --preview-width: int = 0
    --header: string
    --query: string = ""
    --allow-create
    --actions: list<record<key: string, label: string, action: closure>>
    --select-label: string = "select"
    --min-height: int = 0
    --fullscreen
]: nothing -> record {
    if ($items | is-empty) and not $allow_create {
        return {action: "cancelled"}
    }

    let fzf_input = ($items
        | enumerate
        | each {|it| $"($it.index)\t($it.item.text)\t($it.item | get -o preview_arg | default "")" }
        | str join "\n"
    )

    let expect_keys = if ($actions | is-not-empty) {
        $actions | get key | str join ","
    } else { "" }

    let footer = if ($actions | is-not-empty) {
        let separator = "   "
        let hints = (
            [{key: "enter", label: $select_label}]
            | append ($actions | each {|a| {key: $a.key, label: ($a | get -o label | default $a.key)}})
            | each {|h| $"[($h.key)] ($h.label)" }
            | append "[esc] quit"
            | str join $separator
        )
        $"(ansi dark_gray)($hints)(ansi reset)"
    } else { "" }

    # fzf only honors --min-height against a plain percentage height — the
    # adaptive "~" prefix (shrink-to-fit item count) silently ignores it — so
    # drop the "~" whenever a floor is actually requested. --fullscreen skips
    # --height entirely, which is how fzf's own fullscreen mode is triggered.
    let height = if $min_height > 0 { "60%" } else { "~60%" }

    mut fzf_args = [
        "--ansi"
        "--layout" "reverse"
        "--delimiter" "\t"
        "--with-nth" "2"
        "--query" $query
    ]
    if not $fullscreen { $fzf_args ++= ["--height" $height] }
    if ($header | is-not-empty) { $fzf_args ++= ["--header" $header] }
    if ($footer | is-not-empty) { $fzf_args ++= ["--footer" $footer] }
    if $min_height > 0 and not $fullscreen {
        $fzf_args ++= [
            "--min-height" ($min_height | into string)
        ]
    }
    if ($preview_cmd | is-not-empty) {
        let cmd = if ($preview_cmd | str contains "{}") {
            $preview_cmd | str replace -a "{}" "{3}"
        } else { $preview_cmd }

        $fzf_args ++= [
            "--preview" $cmd
            "--border" "rounded"
            "--bind" "ctrl-f:preview-page-down,ctrl-b:preview-page-up"
        ]
        if $preview_width > 0 {
            $fzf_args ++= ["--preview-window" $"right,($preview_width)%"]
        }
    }
    if ($expect_keys | is-not-empty) { $fzf_args ++= ["--expect" $expect_keys] }
    if $allow_create { $fzf_args ++= ["--print-query"] }

    let result = $fzf_input | ^fzf ...$fzf_args | complete

    if $result.exit_code == 130 or ($result.stdout | is-empty) {
        return {action: "cancelled"}
    }

    # `lines` (unlike `str trim -r | lines`) drops only the single trailing
    # newline fzf always appends, without collapsing a genuinely empty
    # selection line (no match) into a missing one.
    let out_lines = $result.stdout | lines
    let query_line = if $allow_create {
        $out_lines | get -o 0 | default ""
    } else { "" }
    let rest = if $allow_create {
        $out_lines | skip 1
    } else { $out_lines }

    let key_pressed = if ($expect_keys | is-not-empty) {
        $rest | get -o 0 | default ""
    } else { "" }
    let selection_line = if ($expect_keys | is-not-empty) {
        $rest | get -o 1 | default ""
    } else {
        $rest | get -o 0 | default ""
    }

    let idx = if ($selection_line | str trim | is-not-empty) {
        $selection_line | split row "\t" | get 0 | into int
    } else { null }
    let value = if $idx != null { ($items | get $idx | get value) } else { null }

    # An expect-key always wins, even if nothing was selected/matched — a
    # cancelled/create outcome only applies when no key was pressed.
    if ($key_pressed | is-not-empty) {
        let matched = $actions | where key == $key_pressed | first
        return {
            action: "selected"
            value: (do $matched.action $value)
        }
    }

    if $idx == null {
        if $allow_create and ($query_line | is-not-empty) {
            return {action: "create", query: $query_line}
        }
        return {action: "cancelled"}
    }

    {action: "selected", value: $value}
}

@category utils
def namegen [checker?: closure] {
    let adjectives = [
        "cosmic"
        "crisp"
        "bold"
        "silent"
        "radiant"
        "vivid"
        "glitch"
        "atomic"
        "stellar"
        "hyper"
        "cyber"
        "shadow"
        "fossil"
        "phantom"
        "frozen"
        "latent"
        "primal"
        "kinetic"
        "solar"
        "lunar"
        "spectral"
        "hybrid"
        "static"
        "binary"
        "fluid"
        "vortex"
        "sonic"
        "amber"
    ]

    let nouns = [
        "breeze"
        "forge"
        "matrix"
        "beacon"
        "summit"
        "vortex"
        "nexus"
        "pulse"
        "vector"
        "orbit"
        "echo"
        "vertex"
        "spark"
        "quasar"
        "glitch"
        "pixel"
        "syntax"
        "kernel"
        "cipher"
        "beacon"
        "proxy"
        "canopy"
        "tether"
        "prism"
        "glacier"
        "mirage"
        "horizon"
        "spire"
    ]

    loop {
        let adj = $adjectives | get (random int ..(($adjectives | length) - 1))
        let noun = $nouns | get (random int ..(($nouns | length) - 1))
        let candidate = $"($adj)-($noun)"

        if ($checker == null) or ((do $checker $candidate) | into bool) {
            return $candidate
        }
    }
}

# Catppuccin frappe theme: https://github.com/catppuccin/nushell/blob/main/themes/catppuccin_frappe.nu
# Contains patches for menus.
let theme = {
    rosewater: "#f2d5cf"
    flamingo: "#eebebe"
    pink: "#f4b8e4"
    mauve: "#ca9ee6"
    red: "#e78284"
    maroon: "#ea999c"
    peach: "#ef9f76"
    yellow: "#e5c890"
    green: "#a6d189"
    teal: "#81c8be"
    sky: "#99d1db"
    sapphire: "#85c1dc"
    blue: "#8caaee"
    lavender: "#babbf1"
    text: "#c6d0f5"
    subtext1: "#b5bfe2"
    subtext0: "#a5adce"
    overlay2: "#949cbb"
    overlay1: "#838ba7"
    overlay0: "#737994"
    surface2: "#626880"
    surface1: "#51576d"
    surface0: "#414559"
    base: "#303446"
    mantle: "#292c3c"
    crust: "#232634"
}

let scheme = {
    recognized_command: $theme.blue
    unrecognized_command: $theme.text
    constant: $theme.peach
    punctuation: $theme.overlay2
    operator: $theme.sky
    string: $theme.green
    virtual_text: $theme.surface2
    variable: {fg: $theme.flamingo, attr: i}
    filepath: $theme.yellow
}

let menu_style = {
    text: $theme.subtext1
    selected_text: {fg: $theme.mauve, bg: $theme.surface0, attr: b}
    description_text: $theme.overlay1
    match_text: {fg: $theme.peach, attr: b}
    selected_match_text: {fg: $theme.mauve, attr: ui}
}

$env.config.color_config = {
    separator: {fg: $theme.surface2, attr: b}
    leading_trailing_space_bg: {fg: $theme.lavender, attr: u}
    header: {fg: $theme.text, attr: b}
    row_index: $scheme.virtual_text
    record: $theme.text
    list: $theme.text
    hints: $scheme.virtual_text
    search_result: {fg: $theme.base, bg: $theme.yellow}
    shape_closure: $theme.teal
    closure: $theme.teal
    shape_flag: {fg: $theme.maroon, attr: i}
    shape_matching_brackets: {attr: u}
    shape_garbage: $theme.red
    shape_keyword: $theme.mauve
    shape_match_pattern: $theme.green
    shape_signature: $theme.teal
    shape_table: $scheme.punctuation
    cell-path: $scheme.punctuation
    shape_list: $scheme.punctuation
    shape_record: $scheme.punctuation
    shape_vardecl: $scheme.variable
    shape_variable: $scheme.variable
    empty: {attr: n}
    filesize: {|| if $in < 1kb {
        $theme.teal
    } else if $in < 10kb {
        $theme.green
    } else if $in < 100kb {
        $theme.yellow
    } else if $in < 10mb {
        $theme.peach
    } else if $in < 100mb {
        $theme.maroon
    } else if $in < 1gb {
        $theme.red
    } else {
        $theme.mauve
    } }
    duration: {|| if $in < 1day {
        $theme.teal
    } else if $in < 1wk {
        $theme.green
    } else if $in < 4wk {
        $theme.yellow
    } else if $in < 12wk {
        $theme.peach
    } else if $in < 24wk {
        $theme.maroon
    } else if $in < 52wk {
        $theme.red
    } else {
        $theme.mauve
    } }
    datetime: {|| (date now) - $in
    | if $in < 1day {
        $theme.teal
    } else if $in < 1wk {
        $theme.green
    } else if $in < 4wk {
        $theme.yellow
    } else if $in < 12wk {
        $theme.peach
    } else if $in < 24wk {
        $theme.maroon
    } else if $in < 52wk {
        $theme.red
    } else {
        $theme.mauve
    } }
    shape_external: $scheme.unrecognized_command
    shape_internalcall: $scheme.recognized_command
    shape_external_resolved: $scheme.recognized_command
    shape_block: $scheme.recognized_command
    block: $scheme.recognized_command
    shape_custom: $theme.pink
    custom: $theme.pink
    background: $theme.base
    foreground: $theme.text
    cursor: {bg: $theme.rosewater, fg: $theme.base}
    shape_range: $scheme.operator
    range: $scheme.operator
    shape_pipe: $scheme.operator
    shape_operator: $scheme.operator
    shape_redirection: $scheme.operator
    glob: $scheme.filepath
    shape_directory: $scheme.filepath
    shape_filepath: $scheme.filepath
    shape_glob_interpolation: $scheme.filepath
    shape_globpattern: $scheme.filepath
    shape_int: $scheme.constant
    int: $scheme.constant
    bool: $scheme.constant
    float: $scheme.constant
    nothing: $scheme.constant
    binary: $scheme.constant
    shape_nothing: $scheme.constant
    shape_bool: $scheme.constant
    shape_float: $scheme.constant
    shape_binary: $scheme.constant
    shape_datetime: $scheme.constant
    shape_literal: $scheme.constant
    string: $scheme.string
    shape_string: $scheme.string
    shape_string_interpolation: $theme.flamingo
    shape_raw_string: $scheme.string
    shape_externalarg: $scheme.string
}
$env.config.highlight_resolved_externals = true
$env.config.explore = {
    status_bar_background: {fg: $theme.text, bg: $theme.mantle}
    command_bar_text: {fg: $theme.text}
    highlight: {fg: $theme.base, bg: $theme.yellow}
    status: {error: $theme.red, warn: $theme.yellow, info: $theme.blue}
    selected_cell: {bg: $theme.blue, fg: $theme.base}
}

# Configure menus
# Default menus: https://www.nushell.sh/book/line_editor.html#menus
$env.config.menus ++= [
    {
        name: help_menu
        only_buffer_difference: true # Search is done on the text written after activating the menu
        marker: "? " # Indicator that appears with the menu is active
        type: {
            layout: description # Type of menu
            columns: 4 # Number of columns where the options are displayed
            col_width: 20 # Optional value. If missing all the screen width is used to calculate column width
            col_padding: 2 # Padding between columns
            selection_rows: 4 # Number of rows allowed to display found options
            description_rows: 10 # Number of rows allowed to display command description
        }
        style: $menu_style
    }
    {
        name: completion_menu
        only_buffer_difference: false # Search is done on the text written after activating the menu
        marker: "| " # Indicator that appears with the menu is active
        type: {
            layout: columnar # Type of menu
            columns: 4 # Number of columns where the options are displayed
            col_width: 20 # Optional value. If missing all the screen width is used to calculate column width
            col_padding: 2 # Padding between columns
        }
        style: $menu_style
    }
    {
        name: history_menu
        only_buffer_difference: true # Search is done on the text written after activating the menu
        marker: "? " # Indicator that appears with the menu is active
        type: {layout: list, page_size: 10}
        style: $menu_style
    }
]

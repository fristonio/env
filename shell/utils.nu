@category utils
def note [] {
    mut notes_dir = ""
    if ($env | get -o NOTES_DIR) != null and ($env.NOTES_DIR | path exists) {
        $notes_dir = $env.NOTES_DIR
    } else {
        $notes_dir = ($env.ENV_LOCAL | path join "scratch")
        if not ($notes_dir | path exists) {
            mkdir $notes_dir
        }
    }

    let month = date now | format date "%Y-%B" | str downcase
    ^$env.EDITOR ($notes_dir | path join $"($month).md")
}

@category utils
@search-terms tmux
def nmux [
  --name (-s): string = "", # Name of the session
  ...args # Extra args for tmux command
] {
    let running_in_tmux = $env.TMUX? | is-not-empty
    if ($name | is-empty) and $running_in_tmux {
        print $"(ansi yellow)Already running in tmux session, specify '--name/-s' to create session(ansi reset)"
        return
    }

    let session_name = if ($name | is-empty) {
        namegen {|n| (^tmux -L nu-server has-session -t $n | complete).exit_code != 0 }
    } else { $name }

    with-env { SHELL: (which nu) } {
        ^tmux -L nu-server new -A -s $session_name ...$args
    }
}

@category utils
@search-terms tmux
def "tm list" [] {
    let current_session = if ($env.TMUX? | is-not-empty) {
        (^tmux display-message -p '#S' | complete).stdout | str trim
    }

    let session_format = "#{session_id}|#{session_name}|#{session_windows}|#{pane_current_command}|#{t:session_created}|#{?session_attached,1,0}|#{session_path}"
    ^tmux -L nu-server list-sessions -F $session_format
    | lines
    | where {|l| $l | is-not-empty }
    | each { |line|
      let out = $line | split row "|"
      let name = $out | get 1

      mut details = {
        id: ($out | get 0)
        name: $name
        windows: ($out | get 2)
        command: ($out | get 3)
        age: ((date now) - ($out | get 4 | into datetime) | into string | split words | first)
        attached: (($out | get 5) == "1")
        path: ($out | get 6 | str replace $env.HOME "~")
        current: ""
      }

      if ($name == $current_session) { $details.current = $"(ansi yellow)(ansi reset)" }
      $details
    }
}

@category utils
@search-terms tmux
def "tm attach" [] {
    tm list | pick { |session| 
      if ($session | is-empty) {
        print $"(ansi yellow)No session selected to attach(ansi reset)"
        return
      }
      
      if ($env.TMUX? | is-not-empty) {
        ^tmux -L nu-server switch-client -t $session.name
      } else {
        ^tmux -L nu-server attach -t $session.name
      } 
    }
}

@category utils
@search-terms tmux
def "tm delete" [] {
    tm list | pick { |session| 
      if ($session | is-empty) {
        print $"(ansi yellow)No session selected to delete(ansi reset)"
        return
      }
      
      if ($env.TMUX? | is-not-empty) and ($session.current | is-not-empty) {
        if (confirm "Session to delete is currently active, are you sure[Y/N]: ") {
          ^tmux -L nu-server kill-session -t $session.name
        }
      } else {
        ^tmux -L nu-server kill-session -t $session.name
      } 
    }
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

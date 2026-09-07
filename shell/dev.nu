use std/log

@category dev
def note [] {
    mut notes_dir = ""
    if ($env | get -o NOTES_DIR) != null and ($env.NOTES_DIR | path exists) {
        $notes_dir = $env.NOTES_DIR
    } else {
        $notes_dir = ($env.HOME | path join "notes")
        if not ($notes_dir | path exists) {
            mkdir $notes_dir
        }
    }

    let month = date now | format date "%Y-%B" | str lowercase
    ^$env.EDITOR ($notes_dir | path join $"($month).md")
}

@category dev
def --wrapped vmshell [--shell(-s): string = "nu", ...args] {
    limactl shell --workdir /home/lima --shell $shell ...$args
}

@category dev
def setup-vm [name: string = "dev"] {
    let lima_template = $env.ENV_DIR | path join "configs/lima/template.yaml"
    let vmstate = (limactl list -f json
    | jq --arg vmname $name -r '. | select(.name == $vmname).status')

    match $vmstate {
        "" => {
            log info $"Creating VM: ($name) [Template: ($lima_template)]"
            limactl create --name $name $lima_template
            limactl start $name
        }
        "Running" => {
            log info "VM already running"
        }
        "Stopped" => {
            log info $"Starting VM: ($name)"
            limactl start $name
        }
        _ => {
            log critical $"Invalid VM state: ($vmstate)"
            return
        }
    }

    vmshell $name
}

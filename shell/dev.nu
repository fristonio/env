use std/log

@category "dev"
def setup-vm [name: string = "dev"] {
  let lima_template = ($env.ENV_DIR | path join "configs/lima/template.yaml")
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

  try {
    limactl shell $name nix --version
  } catch {
    limactl shell $name bash -c "sudo apt -y update && sudo apt install -y make curl"
    limactl shell $name make -C $env.ENV_DIR init-nix

    limactl shell $name bash -c "curl -fsSL https://test.docker.com | sudo sh"
    limactl shell $name bash -c "sudo usermod \$USER --append --group docker"
    limactl restart $name

    limactl shell $name make -C $env.ENV_DIR configs
  }

  let flake_name = $"lima-vm-(uname | get machine)"
  let flake_path = $"($env.ENV_DIR)#($flake_name)"
  log info $"Setting up home configuration for: ($flake_name)"
  try {
    limactl shell $name home-manager --version
    (limactl shell $name home-manager switch -b bak --flake $flake_path)
  } catch {
    limactl shell $name nix run home-manager/release-25.11 -- switch -b backup --flake $flake_path
  }
}

if (which kubectl | is-not-empty) {
  alias k = kubectl
  alias ksys = kubectl -n kube-system
  alias kexec = kubectl exec -it
  alias ksysexec = kubectl -n kube-system exec -it
}

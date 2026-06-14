$env.KUBE_NS = "default"

def --env kns [namespace?: string] {
    if ($namespace | is-empty) or ($namespace == $env.KUBE_NS) {
        return $env.KUBE_NS
    }

    print $"(ansi yellow)Updating KUBE_NS:(ansi reset) ($env.KUBE_NS) -> (ansi blue)($namespace)(ansi reset)"
    $env.KUBE_NS = $namespace
}

alias k = kubectl -n $env.KUBE_NS
alias ksys = kubectl -n kube-system

# TODO: Migrate to custom commands
#
# alias ksysexec = kubectl -n kube-system exec -it
# alias klogs = kubectl logs
# alias ksyslogs = kubectl -n kube-system logs
# alias kpods = kubectl get pods -o wide
# alias ksyspods = kubectl -n kube-system get pods -o wide


$env.KUBE_NS = "default"

def --env kns [namespace?: string] {
    if ($namespace | is-empty) or ($namespace == $env.KUBE_NS) {
        return $env.KUBE_NS
    }

    print $"(ansi yellow)Updating KUBE_NS:(ansi reset) ($env.KUBE_NS) -> (ansi blue)($namespace)(ansi reset)"
    $env.KUBE_NS = $namespace
    return $env.KUBE_NS
}

def --env _kubectl_ns_arg [--namespace(-n): string, --all(-a)] {
    if ($namespace | is-not-empty) {
        return ["-n", $namespace]
    } else if $all {
        return ["-A"]
    }
    return [
        "-n", (kns)
    ]
}

alias k = kubectl -n $env.KUBE_NS
alias ksys = kubectl -n kube-system

def kpods [
    --namespace(-n): string
    --all(-a)
    --interactive(-i)
    --multi(-m)
] {
    let ns = _kubectl_ns_arg --namespace $namespace --all=$all

    let pods_list = ^kubectl get pods ...$ns -o wide | from ssv --aligned-columns
    if not $interactive {
        return $pods_list
    }

    $pods_list
    | upsert NAMESPACE { $in | default $namespace }
    | pick { |pods|
        $pods | each {|pod|  ^kubectl get pod -n $pod.NAMESPACE $pod.NAME -o json | from json }
    } --prompt "Select pods to get K8s objects for" --multi=$multi
}
alias ksyspods = kpods --namespace kube-system

def kexec [cmd: string = "bash", --namespace(-n): string, --all(-a)] {
    let pod = kpods -i -n $namespace --all=$all
    if $pod == null { return }

    ^kubectl exec -it -n $pod.metadata.namespace $pod.metadata.name -- $cmd
}
alias ksysexec = kexec --namespace kube-system

def klogs [
    pod_name?: string
    --namespace(-n): string
    --all(-a)
    --follow(-f)
] {
    if ($pod_name | is-not-empty) {
        let ns = _kubectl_ns_arg --namespace $namespace --all=$all
        ^kubectl logs --n $ns -f=$follow $pod_name
        return
    }

    let pod = kpods -i -n $namespace --all=$all
    if $pod == null { return }

    if $follow {
        ^kubectl logs -f -n $pod.metadata.namespace $pod.metadata.name
    } else {
        ^kubectl logs -n $pod.metadata.namespace $pod.metadata.name
    }
}
alias ksyslogs = klogs --namespace kube-system

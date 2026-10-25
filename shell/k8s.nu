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

# Generic fzf-nu browser over any kubectl resource type.
def kres [
    resource: string # k8s resource: pod, configmap etc.
    --namespace(-n): string
    --all(-a)
] {
    let ns_args = _kubectl_ns_arg --namespace $namespace --all=$all
    let is_pod = $resource in ["pod" "pods" "po"]

    def row-ns-arg [row: record] {
        let row_ns = $row | get -o NAMESPACE | default ""
        if ($row_ns | is-not-empty) {
            ["-n" $row_ns]
        } else if $all {
            []
        } else {
            $ns_args
        }
    }

    loop {
        let raw = (^kubectl get $resource -o wide ...$ns_args | complete)
        if $raw.exit_code != 0 {
            print -e $raw.stderr
            return
        }

        let items = $raw.stdout | from ssv --aligned-columns
        if ($items | is-empty) {
            print $"(ansi yellow)No ($resource) found(ansi reset)"
            return
        }

        let headers = $items | columns
        let rows = $items | each { values }
        let rendered = (
            render-fzf-table $rows --headers $headers --colors ($headers | each {|_| null})
        )
        let fzf_items = (fzf-table-items $rendered.data $items)

        mut actions = [
            {
                key: "ctrl-y"
                label: "copy name"
                action: {|row|
                    $row.NAME | tcopy
                    print $"(ansi green)✓(ansi reset) Copied (ansi blue)($row.NAME)(ansi reset)"
                }
            }
            {
                key: "ctrl-o"
                label: "yaml"
                action: {|row|
                    let tmp = (^mktemp /tmp/kres-XXXXXX.yaml | str trim)
                    ^kubectl get $resource ...(row-ns-arg $row) $row.NAME -o yaml | save -f $tmp
                    ^$env.EDITOR $tmp
                    ^rm -f $tmp
                }
            }
            {
                key: "ctrl-x"
                label: "delete"
                action: {|row|
                    let prompt = $"(ansi yellow)Delete ($resource) (ansi cyan)($row.NAME)(ansi yellow)? [y/n]: (ansi reset)"
                    if (confirm $prompt) {
                        ^kubectl delete $resource ...(row-ns-arg $row) $row.NAME
                    }
                    return $row
                }
            }
            {
                key: "ctrl-a"
                label: "edit"
                action: {|row|
                    ^kubectl edit $resource ...(row-ns-arg $row) $row.NAME
                    return $row
                }
            }
        ]

        if $is_pod {
            $actions ++= [
                {
                    key: "ctrl-e"
                    label: "exec"
                    action: {|row|
                        ^kubectl exec -it ...(row-ns-arg $row) $row.NAME -- bash
                        return $row
                    }
                }
                {
                    key: "ctrl-l"
                    label: "logs"
                    action: {|row|
                        ^kubectl logs -f ...(row-ns-arg $row) $row.NAME | ^fzf --tac --no-sort --exact --layout reverse --header "Following logs — esc to exit"
                        return $row
                    }
                }
            ]
        }

        let result = (
            fzf-nu $fzf_items --header $rendered.header --select-label "print" --actions $actions
        )

        if $result.op == "cancel" { return }

        let action = $result | get -o action
        if $action == null { return $result.value }
        if $action in ["copy name", "delete", "yaml"] {
            continue
        }

        return
    }
}
alias ksysres = kres --namespace kube-system

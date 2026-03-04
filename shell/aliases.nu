# Standard aliases
alias l = ls -a
alias ll = ls -la

alias gs = git status
alias gl = git log --oneline --graph --abbrev-commit --decorate

alias li = eza -l --icons
alias tree = eza --tree

alias k = kubectl
alias ksys = kubectl -n kube-system
alias kexec = kubectl exec -it
alias ksysexec = kubectl -n kube-system exec -it
alias klogs = kubectl logs
alias ksyslogs = kubectl -n kube-system logs
alias kpods = kubectl get pods -o wide
alias ksyspods = kubectl -n kube-system get pods -o wide

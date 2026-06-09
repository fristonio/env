$env.WT_WS_DIR = $"($env.HOME)/ws"
$env.WT_REMOTE_ORIGIN = "origin"
$env.WT_REMOTE_UPSTREAM = "upstream"

def git-repo-url [repo: string] {
    $"git@github.com:($repo).git"
}

def git-validate-repo [repo: string] {
    git ls-remote --symref (git-repo-url repo) HEAD o+e>| ignore
}

def git-validate-bare [path: string = "."] {
    git -C $path rev-parse --is-bare-repository o+e>| ignore
}

def git-validate-worktree [path: string = "."] {
    let repo_check = git -C $path rev-parse --is-inside-work-tree | complete
    if $repo_check.exit_code != 0 {
        return (error make {msg: "Not a git repository worktree"})
    }
}

def git-wt-list [path: string = "."] {
    git -C $path worktree list --porcelain
    | str trim
    | split row -r '\r?\n\s*\r?\n'
    | each { |block|
            $block
            | lines
            | parse -r '^(?<key>\S+)(?:\s+(?<value>.*))?$'
        }
    | each {|it| $it.key | zip $it.value | into record }
}

def git-commit-info [path: string = "."] {
    let sep = "<|>"
    let git_log = git -C $path log -1 --format=$"%H($sep)%h($sep)%cI($sep)%s" | complete

    let commit_info = if $git_log.exit_code != 0 or ($git_log.stdout | is-empty) {
        {
            sha: null
            short_sha: null
            timestamp: null
            message: "No commits yet"
        }
    } else {
        let parts = $git_log.stdout | str trim | split row $sep
        {
            sha: ($parts | get 0)
            short_sha: ($parts | get 1)
            timestamp: ($parts | get 2 | into datetime)
            message: ($parts | get 3)
        }
    }
    $commit_info
}

def git-status-info [path: string = "."] {
    let parsed_status = (git -C $path status --porcelain
        | lines
        | parse -r '^(?<X>.)(?<Y>.) (?<path>.*)$'
    )

    mut info = {
        staged_added: ($parsed_status | where X == "A" | length)
        staged_modified: ($parsed_status | where X == "M" | length)
        staged_deleted: ($parsed_status | where X == "D" | length)
        staged_renamed: ($parsed_status | where X == "R" | length)
        unstaged_modified: ($parsed_status | where Y == "M" | length)
        unstaged_deleted: ($parsed_status | where Y == "D" | length)
        untracked: ($parsed_status | where X == "?" | length)
    }

    let diff_check = git -C $path diff HEAD --numstat | complete
    let change_summary = if $diff_check.exit_code != 0 or ($diff_check.stdout | is-empty) {
        {added: 0, removed: 0}
    } else {
        let parsed_diff = (
            $diff_check.stdout
            | lines
            | parse -r '^(?<added>\S+)\s+(?<removed>\S+)\s+(?<path>.*)$'
        )

        # Filter out binary files (which represent line changes as '-') before converting to integers
        let added = (
            $parsed_diff
            | each {|r| if $r.added == "-" { 0 } else { $r.added | into int } }
            | math sum
        )
        let removed = (
            $parsed_diff
            | each {|r| if $r.removed == "-" { 0 } else { $r.removed | into int } }
            | math sum
        )
        {added: $added, removed: $removed}
    }

    $info.changes = $change_summary
    $info
}

def git-branch-upstream [path: string = "."] {
    let info = git -C rev-parse --abbrev-ref --symbolic-full-name @{u} | complete
    if $info.exit_code == 0 {
        $info.stdout | str trim
    } else { null }
}

def git-branch-local [branch: string, --dir(-C): string = "."] {
    (git -C $dir rev-parse --verify --quiet $"refs/heads/($branch)" | complete).exit_code == 0
}

def git-branch-remote [branch: string, remote: string, --dir(-C): string = "."] {
    let remotes = (
        git -C $dir remote
        | lines
        | str trim
        | where {|r| $r | is-not-empty }
    )
    if $remote not-in $remotes {
        print $"Remote '($remote)' not configured for the repository"
        return false
    }

    (git -C $dir ls-remote --exit-code --heads $remote $branch | complete).exit_code == 0
}

def git-wt-info [path: string = "."] {
    git-validate-worktree $path

    let wt_path = $path | path expand
    let branch_name = (git -C $path branch --show-current)
    let upstream = git-branch-upstream $path
    let commit_info = git-commit-info $path
    let status = git-status-info $path

    {
        path: $wt_path
        branch: $branch_name
        upstream: $upstream
        commit: $commit_info
        status: $status
    }
}

def get-wt-repo-root [repo: string] {
    $"($env.WT_WS_DIR)/($repo)"
}

def get-wt-repo-path [repo?: string] {
    mut repo_path = $env.PWD
    if $repo != null {
        $repo_path = (get-wt-repo-root $repo)
    }
    $repo_path
}

def get-wt-dir-name [branch: string] {
    let branch_sh = $branch | split column "fristonio/" | last
    if ($branch_sh | is-not-empty) {
        $branch_sh
    } else {
        $branch | str replace --all "/" "."
    }
}

# Git worktree manager — manage multiple branches as parallel checkouts.
#
# Each repository lives under $WT_WS_DIR/<user>/<repo>/ as a bare clone.
# Every branch gets its own checkout directory alongside .git.
#
# Run a subcommand to get started:
def "wt" [] {
    print $"(ansi attr_bold)wt(ansi reset) — git worktree manager"
    print $"  workspace: (ansi cyan)($env.WT_WS_DIR)(ansi reset)"
    print ""
    print $"(ansi attr_bold)SUBCOMMANDS(ansi reset)"
    print $"  (ansi green)wt init(ansi reset)   <repo> [origin]                      Clone a GitHub repo as a bare worktree workspace"
    print $"  (ansi green)wt list(ansi reset)   [repo]                               List all worktrees with status and commit info"
    print $"  (ansi green)wt switch(ansi reset) <branch> [remote] [repo] [--create]  Switch to a worktree, creating it if needed"
    print $"  (ansi green)wt create(ansi reset) <branch> [base] [repo]               Create a new branch and its worktree"
    print $"  (ansi green)wt remove(ansi reset) <branch> [repo]                      Remove a worktree checkout"
    print ""
    print $"  Run (ansi attr_bold)wt <subcommand> --help(ansi reset) for detailed usage."
}

# Clone a GitHub repository as a bare-cloned worktree workspace.
#
# Creates $WT_WS_DIR/<user>/<repo>/.git as a bare clone and configures two remotes:
#   upstream — the canonical repository (repo argument)
#   origin   — your fork (origin argument), or same URL as upstream if omitted
#
# A worktree for the default branch is created automatically after cloning.
#
# Examples:
#   wt init cilium/cilium
#   wt init cilium/cilium fristonio/cilium
def "wt init" [
    repo: string    # GitHub repository to clone as upstream, in user/repo format
    origin?: string # Fork to register as origin remote, in user/repo format; defaults to upstream
] {
    let repo_path = get-wt-repo-root $repo
    let repo_git_path = $"($repo_path)/.git"
    let repo_url = git-repo-url $repo

    if ($repo_path | path exists) {
        error make {msg: $"'($repo)' already exists at ($repo_path)"}
    }

    let origin_url = if ($origin | is-empty) { $repo_url } else { git-repo-url $origin }

    print $"(ansi attr_bold)Initializing(ansi reset) (ansi cyan)($repo)(ansi reset)"

    try {
        print $"  (ansi yellow)→(ansi reset) Creating workspace at ($repo_path)"
        mkdir $repo_path

        print $"  (ansi yellow)→(ansi reset) Cloning bare repository ..."
        git clone --bare --single-branch $repo_url $repo_git_path

        let default_branch = git -C $repo_path branch --show-current | str trim
        if ($default_branch | is-empty) {
            error make {msg: $"Cannot determine default branch for ($repo)"}
        }

        print $"  (ansi yellow)→(ansi reset) Configuring remotes"
        git -C $repo_path remote rename $env.WT_REMOTE_ORIGIN $env.WT_REMOTE_UPSTREAM
        git -C $repo_path remote add $env.WT_REMOTE_ORIGIN $origin_url

        print $"  (ansi yellow)→(ansi reset) Creating default worktree for (ansi cyan)($default_branch)(ansi reset)"
        git -C $repo_path worktree add --relative-paths $default_branch $default_branch
    } catch {|err|
        if ($repo_path | path exists) { rm -rf $repo_path }
        error make {msg: $"Failed to initialize ($repo): ($err.msg)"}
    }

    print $"  (ansi green)✓(ansi reset) Initialized (ansi attr_bold)($repo)(ansi reset)"
    {
        repo: $repo
        path: $repo_path
        upstream: $repo_url
        origin: $origin_url
    }
}

# List all worktrees for a repository with status and commit info.
#
# When run from inside a worktree directory, the repo is inferred automatically.
# Returns a list of records suitable for further pipeline use.
#
# Examples:
#   wt list
#   wt list cilium/cilium
def "wt list" [
    repo?: string # Repository to list worktrees for (user/repo); inferred from CWD if omitted
] {
    let repo_path = get-wt-repo-path $repo
    git-validate-bare $repo_path

    let worktrees = (git-wt-list $repo_path
        | where {|it| ($it.worktree? | is-not-empty) and not ("bare" in $it) }
        | each {|it| git-wt-info $it.worktree })

    if ($worktrees | is-empty) {
        print $"(ansi yellow)No worktrees found in ($repo_path)(ansi reset)"
        return []
    }

    $worktrees
}

# Switch to a worktree by branch name, creating it if needed.
#
# Resolution order:
#   1. Worktree directory already exists → cd into it directly
#   2. Branch exists locally             → create worktree and cd
#   3. remote given and branch found on it → fetch, create worktree, cd
#   4. --create flag set                 → create new branch + worktree, cd
#
# Examples:
#   wt switch main
#   wt switch feat/my-feature upstream
#   wt switch feat/new-thing --create
def --env "wt switch" [
    branch: string   # Branch name to switch to
    remote?: string  # Remote to fetch the branch from if it does not exist locally
    repo?: string    # Repository to operate on (user/repo); inferred from CWD if omitted
    --create (-c)    # Create a new local branch if it does not exist anywhere
] {
    let repo_path = get-wt-repo-path $repo
    git-validate-bare $repo_path

    let wt_dir = get-wt-dir-name $branch

    if ($wt_dir | path exists) {
        print $"  (ansi yellow)→(ansi reset) Worktree already exists, switching to (ansi cyan)($branch)(ansi reset)"
        git-validate-worktree $wt_dir
        cd $wt_dir
        return
    }

    if (git-branch-local -C $repo_path $branch) {
        print $"  (ansi yellow)→(ansi reset) Branch (ansi cyan)($branch)(ansi reset) found locally, creating worktree"
        git -C $repo_path worktree add --relative-paths $wt_dir $branch
        cd $wt_dir
        return
    }

    if ($remote | is-not-empty) {
        if not (git-branch-remote -C $repo_path $branch $remote) {
            error make {msg: $"Branch '($branch)' not found on remote '($remote)'"}
        }
        print $"  (ansi yellow)→(ansi reset) Fetching (ansi cyan)($branch)(ansi reset) from ($remote)"
        git -C $repo_path fetch $remote $branch
        print $"  (ansi yellow)→(ansi reset) Creating worktree"
        git -C $repo_path worktree add --relative-paths $wt_dir $branch
        cd $wt_dir
        return
    }

    if not $create {
        error make {msg: $"Branch '($branch)' not found — pass --create to create a new branch"}
    }
    print $"  (ansi yellow)→(ansi reset) Creating new branch (ansi cyan)($branch)(ansi reset) and worktree"
    git -C $repo_path worktree add --relative-paths $wt_dir -b $branch
    cd $wt_dir
}

# Create a new branch and its worktree from a base branch.
#
# Errors if the branch already exists — use `wt switch --create` for idempotent creation.
# The base branch must exist locally; if omitted, the repo's current branch is used.
#
# Examples:
#   wt create feat/my-feature
#   wt create feat/my-feature main
#   wt create hotfix/urgent v1.19 cilium/cilium
def "wt create" [
    branch: string  # Name of the new branch to create
    base?: string   # Base branch to branch from; defaults to the repo's current branch
    repo?: string   # Repository to operate on (user/repo); inferred from CWD if omitted
] {
    let repo_path = get-wt-repo-path $repo

    if (git-branch-local -C $repo_path $branch) {
        error make {msg: $"Branch '($branch)' already exists"}
    }

    let wt_dir = get-wt-dir-name $branch
    if ($wt_dir | path exists) {
        error make {msg: $"Worktree directory '($wt_dir)' already exists"}
    }

    let base_branch = if $base != null {
        $base
    } else {
        git -C $repo_path branch --show-current | str trim
    }

    print $"  (ansi yellow)→(ansi reset) Creating branch (ansi cyan)($branch)(ansi reset) from (ansi cyan)($base_branch)(ansi reset)"
    git -C $repo_path worktree add --relative-paths $wt_dir -b $branch $base_branch
    print $"  (ansi green)✓(ansi reset) Created worktree at ($wt_dir)"

    {branch: $branch, base: $base_branch, path: $wt_dir}
}

# Remove a worktree checkout directory.
#
# Removes the worktree directory only — the branch itself is preserved.
# Git will refuse removal if the worktree has uncommitted changes.
#
# Examples:
#   wt remove feat/my-feature
#   wt remove feat/my-feature cilium/cilium
def "wt remove" [
    branch: string  # Branch whose worktree should be removed
    repo?: string   # Repository to operate on (user/repo); inferred from CWD if omitted
] {
    let repo_path = get-wt-repo-path $repo
    let wt_dir = get-wt-dir-name $branch

    if not ($wt_dir | path exists) {
        error make {msg: $"No worktree directory found for branch '($branch)'"}
    }

    print $"  (ansi yellow)→(ansi reset) Removing worktree for (ansi cyan)($branch)(ansi reset)"
    git -C $repo_path worktree remove $wt_dir
    print $"  (ansi green)✓(ansi reset) Removed ($wt_dir)"
}

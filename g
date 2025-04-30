#!/usr/bin/env nu


let THIS_PROGRAM_NAME = "g"
let CONFIG_FILE_NAME = "config.toml"

# Small utility for automating the git+gh commands in the github flow
def main [] {
  main status
}

# We can't rely on current branch names alone for operations like 'gh pr ...' (i think if the branch name has a '/' gh gets confused)
# so this function gets the PR number from the branch name so we can do 'gh pr merge X'
def get_pr_number [current_branch: string]: nothing -> int {
   gh pr list  --json headRefName,number | from json | filter {|x| $x.headRefName == $current_branch} | get number | first
}


def get_settings [] {
  $env.XDG_CONFIG_home | path join $THIS_PROGRAM_NAME | path join $CONFIG_FILE_NAME | open $in
}


def get_repo [settings: any] {
  let user = ($settings | get username)
  let git_root = (git rev-parse --show-toplevel)
  let project = $git_root | path basename

  $"($user)/($project)"
}

def "main status" [] {
  let settings = (get_settings)
  let default_branch = (get_default_branch $settings)
  let current_branch = (get_current_branch)

  if ($current_branch) == ($default_branch) {
    gh pr list
    exit 0
  }

  let pr_number = (get_pr_number $current_branch)
  let pr_info = (gh pr $pr_number view $current_branch --json number,state,isDraft,url | from json)
  let pr_number = $pr_info.number
  let pr_state = $pr_info.state
  let pr_draft = if $pr_info.isDraft == true { "draft" } else { "ready" }
  let pr_url = $pr_info.url
  print $"PR #($pr_number) is ($pr_state) and ($pr_draft): ($pr_url)"
}

def get_current_branch [] {
  git branch --show-current | str trim
}

def get_default_branch [settings: any] {
  $settings | get default-branch
}

def "main checkout" [branch: string, remote?: string, repo?: string] {
  let settings = (get_settings)
  let default_branch = ($settings | get default-branch)
  let current_branch = (get_current_branch)

  if $current_branch != $default_branch {
    print $"Not on default branch '($default_branch)'"
    return 1
  }

  let remote = ($remote | default "origin")
  

  git checkout -b $branch
  git push --set-upstream $remote $branch
}

def new_pr [ready: bool, repo?: string] {
  let settings = (get_settings)
  let repo = ($repo | default (get_repo $settings))

  if $ready {
    gh pr create --repo $repo --fill    
  } else {
    
    gh pr create --repo $repo --fill --draft
  }
}

def "main pr" [--open, --no-open, --ready, repo?: string, remote?: string] {
  let settings = (get_settings)
  let default_branch = ($settings | get default-branch)
  let current_branch = (get_current_branch)

  if $current_branch == $default_branch {
    print $"Currently on default branch '($default_branch)'. Please checkout a feature branch. Refusing to open a PR"
    return 1
  }

  let remote = ($remote | default "origin")
   
  git push --set-upstream $remote $current_branch

  let pr_url = (new_pr $ready)

  if $open {
    xdg-open $pr_url
  } else {
    if ($settings | get open-urls) {
      if $no_open {
        print $pr_url
      } else {
        xdg-open $pr_url
      }
    } else {
      print $pr_url
    }
  }}


def "main ready" [] {
  main update
  let current_branch = (get_current_branch)
  let pr_number = (get_pr_number $current_branch)
  gh pr ready $pr_number
}

def reset_to_default_branch [--delete-current, default_branch?: string] {
  let settings = (get_settings) # TODO don't need to get settings if default_branch is passed
  let default_branch = ($default_branch | default (get_default_branch $settings))
  let current_branch = (get_current_branch)

  git checkout $default_branch
  git pull 
  git branch -d $current_branch  
}

def is_dirty [] {
  try {git diff --quiet --ignore-submodules HEAD} catch {
    return true
  }
  return false
}

# Merge in-progress PR
def "main merge" [] {
  if (is_dirty) {
    print "Dirty git status, bailing"
    exit 1
  }

  main update

  let current_branch = (get_current_branch)
  let pr_number = (get_pr_number $current_branch)
  gh pr merge $pr_number --merge --delete-branch
  # No need to reset to default branch, gh utility does that for us
}

def pr_closed [pr_number: int] {
  (gh pr view $pr_number --json closed --jq '.closed') | from json
}


# Update in-progress PR
def "main update" [] {
  let current_branch = (get_current_branch)
  let pr_number = (get_pr_number $current_branch)
  if (pr_closed $pr_number) {
    print $"PR #($pr_number) for current branch '($current_branch)' has been closed, cannot update"
    exit 1
  }

  git push
}

# Delete current feature branch (if pr has been merged)
def "main clean" [] {
  let settings = (get_settings)
  let default_branch = (get_default_branch $settings)
  let current_branch = (get_current_branch)

  if $current_branch == $default_branch {
      print "Already on default branch, nothing to clean."
      exit 0
  }

  let pr_number = (get_pr_number $current_branch)

  if !(pr_closed $pr_number) {
    print $"PR #($pr_number) for current branch '($current_branch)' is still open. Refusing to delete local branch"
    exit 1
  }

  reset_to_default_branch --delete-current $default_branch
}

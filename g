#!/usr/bin/env nu


let THIS_PROGRAM_NAME = "g"
let CONFIG_FILE_NAME = "config.toml"


def main [] {
  main status
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
  let current_branch = (get_current_branch)
  let pr_info = (gh pr view $current_branch --json number,state,isDraft,url | from json)
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
  gh pr ready
}

def reset_to_default_branch [--delete-current, default_branch?: string] {
  let settings = (get_settings) # TODO don't need to get settings if default_branch is passed
  let default_branch = ($default_branch | default (get_default_branch $settings))
  let current_branch = (get_current_branch)

  git checkout $default_branch
  git pull 
  git branch -d $current_branch  
}

# Merge in-progress PR
def "main merge" [] {
  gh pr merge --merge --delete-branch
  # No need to reset to default branch, gh utility does that for us
}

def pr_closed [] {
  gh pr view --json closed --jq '.closed'
}


# Update in-progress PR
def "main update" [] {
  let current_branch = (get_current_branch)

  if (pr_closed) {
    print $"PR for current branch '($current_branch)' has been closed, cannot update"
    return 1
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
      return
  }

  if !(pr_closed) {
    print $"PR for current branch '($current_branch)' is still open. Refusing to delete local branch"
    return 1
  }

  reset_to_default_branch --delete-current $default_branch
}

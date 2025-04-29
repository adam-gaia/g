#!/usr/bin/env nu


let THIS_PROGRAM_NAME = "g"
let CONFIG_FILE_NAME = "config.toml"


def main [] {
  main info
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

def "main info" [] {
  print "TODO"
}

def get_current_branch [] {
  git branch --show-current | str trim
}

def get_default_branch [settings: any] {
  $settings | get default-branch
}

def "main checkout" [--open, --no_open, branch: string, remote?: string, repo?: string] {
  let settings = (get_settings)
  let default_branch = ($settings | get default-branch)
  let current_branch = (get_current_branch)

  if $current_branch != $default_branch {
    print $"Not on default branch '($default_branch)'"
    return 1
  }

  let remote = ($remote | default "origin")
  let repo = ($repo | default (get_repo $settings))

  git checkout -b $branch
  git push --set-upstream $remote $branch
  let pr_url = (gh pr create --repo $repo --fill --draft)

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
  }
}


def "main ready" [] {
  gh pr ready
}

def reset_to_default_branch [--delete-current, default_branch?: string] {
  let settings = (get_settings) # TODO don't need to get settings if default_branch is passed
  let default_branch = (default_branch | default (get_default_branch $settings))
  let current_branch = (get_current_branch)

  git checkout $default_branch
  git pull 
  git branch -d $current_branch  
}

def "main merge" [] {
  gh pr merge --merge --delete-branch
  reset_to_default_branch --delete-current
}



def "main clean" [] {
  let settings = (get_settings)
  let default_branch = (get_default_branch $settings)
  let current_branch = (get_current_branch)

  if $current_branch == $default_branch {
      print "Already on default branch, nothing to clean."
      return
  }

  let closed = (gh pr view --json closed --jq '.closed')
  if !closed {
    print $"PR for current branch '($current_branch)' is still open. Refusing to delete local branch"
    return 1
  }

  reset_to_default_branch --delete-current $default_branch
}

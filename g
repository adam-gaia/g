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

def "main checkout" [--open, branch: string, remote?: string, repo?: string] {
  let settings = get_settings
  let remote = ($remote | default "origin")

  let repo = ($repo | default (get_repo $settings))

  git checkout -b $branch
  git push --set-upstream $remote $branch
  let pr_url = (gh pr create --repo $repo --fill --draft)

  if $open {
    xdg-open $pr_url
  } else {
    if ($settings | get open-urls) {
      xdg-open $pr_url
    } else {
      print $pr_url
    }
  }
}


def "main ready" [] {
  gh pr ready
}


def "main merge" [] {
  gh pr merge --merge --delete-branch
}


def "main clean" [] {
  print "todo"
}

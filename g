#!/usr/bin/env nu


let THIS_PROGRAM_NAME = "g"
let CONFIG_FILE_NAME = "config.toml"


def main [] {
  main info
}



def settings [] {
  $env.XDG_CONFIG_home | path join $THIS_PROGRAM_NAME | path join $CONFIG_FILE_NAME | open $in
}


def get_repo [] {
  let user = ((settings) | get username)
  let git_root = (git rev-parse --show-toplevel)
  let project = $git_root | path basename

  $"($user)/($project)"
}

def "main info" [] {
  print "TODO"
}

def "main checkout" [open: bool, branch: string, remote?: string, repo?: string] {
  let remote = ($remote | default "origin")

  let repo = ($repo | default (get_repo))

  git checkout -b $branch
  git push --set-upstream $remote $branch
  let pr_url = (gh pr create --repo $repo --fill --draft)

  if $open {
    xdg-open $pr_url
  } else {
    print $pr_url
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

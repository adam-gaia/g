#!/usr/bin/env nu

def main [] {
  print "todo"
}


def "main checkout" [branch: string, remote?: string] {
  let remote = ($remote | default "origin")

  git checkout -b ($branch)
  git push --set-upstream ($remote) ($branch)
  let pr_url = (gh pr create --fill --draft)
  print $"pr_url"
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

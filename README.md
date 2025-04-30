# pr
Small utility for automating the git+gh commands in the [github flow](https://docs.github.com/en/get-started/using-github/github-flow)

## Usage
1. Create config file ~/.config/pr/config.toml

```console
$ cat ~/.config/pr/config.toml                                                                                                                                                                                                                29-Tue 10:44:17 PM
username = "adam-gaia"
open-urls = true
default-branch = "main"
```

2. make some changes (don't forget to commit!)
3. Create a new pull request:`pr new <title>`
4. Remove 'draft' status: `pr ready`
5. Merge the pr: 'pr merge'


## Tips & Tricks
- Note that the name 'pr' conflicts with a [similarly named tool in the coreutils](https://manpages.org/pr).
On my NixOS system, the coreutils end up on the $PATH first, so something needs to be done.
I've elected to prepend my 'pr' to the path with home-manager's `home.sessionPath`, but a simple `export PATH="/path/to/this/pr:${PATH}"` will do.


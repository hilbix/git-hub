> Early stage, all can change in future
>
> What you see here is **planning**!
> Most things are not yet implemented!

# `git hub`: `git`-extension to access GitHub-API from shell

> I was unable to find somthing suitable within 5 minutes,
> so I created something new from scratch.
>
> - Sorry, `hub` is a Matmos.
> - Other look like Moloch to me.
>
> Really, isn't there anything out there easy to use,
> nothing to learn and nothing to think about?


This is a shell tool to access the GitHub API from shell.
It needs `git`, `python` version 3 and `curl`.

The idea is, to get some of the information you want
to properly work with GitHub repos of others.

For example (why this was done) you want to access the
full network to get easy access to all clones of some
repository to gain oversight, what others changed,
such that you can max out for you what others have done.

## Install

	git clone https://github.com/hilbix/gh.git
	cd git-gh
	make install

Then run:

	git hub --global init your-GitHub-username

This populates the global `.gitconfig` with section `[git-hub]`.
Run this after update, to migrate the configuration.

Without this command, `git hub` will use its defaults,
which might change over time, unexpected by you.
Also some commands, which require to know your account, might fail.


## `git hub [options]`

- `--global` operate on the global `.gitconfig`, not the local one
- `--user name` set different GitHub username for commands


## `git hub commands`

- `git hub init [user]`
   - copy or update all settings to the local `.git/config`
   - Missing options are taken from global `.gitconfig`
   - Sets the default user to use with GitHub

- `git hub deinit`
  - inverse of `git hub init`, remove local configs.
  - prints out all settings which are deinited.

- `git hub config [key [value]`
  - sets github configuration to a value
  - without value, it retrieves the key's value
  - without the key, it dumps the full configuration
    in a format, suitable to restore it.

- `git hub config`

- `git hub user USER` fetch/update all data from user


# Notes

## Working with multiple GitHub names

If you work with a certain name in a certain repository,
use `git hub init name` to set it.

If you need to work with more than one name within the
same `git` repository, use `git hub init ''` to set
an empty name.  `git hub` then tries to detect the
username from the URL.

If this still does not work for you, use the
`git hub --user name command` variant.

Note that you can use aliases for several names:

	git config --global alias.hup hub --user user1
	git config --global alias.hut hub --user user2
	git config --global alias.hum hub --user user3

This is just normal `git` standard functionality.


## Shell completion

This is not yet implemented and it has a very low priority for me, sorry.


## Help


For now this file here is all you got.  Perhaps in future I come
around to support `git hub --help`.


# FAQ

`git hub --help` does not work

- Try `git hub help [command]`
- This is because `git` treats `git hub --help` as `git --help hub`
- I found no support for this in `git` except by installing manpages,
  which I think is plain overkill just to alias this variant properly.

License?

- This Works is placed under the terms of the Copyright Less License,
  see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

- This means, it is free as free beer, free speech, free baby

Windows?

- Works for the Linux-ABI

MacOS?

- Untested yet, but you probably need https://github.com/hilbix/macshim.git

Contact/Bug/Idea/Contribution?

- Open Issue or PR on GitHub: https://github.com/hilbix/git-hub


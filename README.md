> Early stage, all can change in future
>
> What you see here is **planning**!
> Most things are not yet implemented!

# `gh`: Access GitHub-API from shell

> I was unable to find somthing suitable within 5 minutes,
> so I created something new from scratch.

This is a shell tool to access the GitHub API from shell.
It needs `git`, `python` version 3 and `curl`.

The idea is, to get some of the information you want
to properly work with GitHub repos of others.

For example (why this was done) you want to access the
full network to get easy access to all clones of some
repository to gain oversight, what others changed,
such that you can max out for you what others have done.

## Usage

	git clone https://github.com/hilbix/gh.git
	cd gh
	make install

Then run:

	gh init --global

This initializes `$HOME/.config/gh/`


## Afterwards you can issue commands

- `gh init [--global] [configdir]`
   - sets another `gh` config directory, default: `~/.config/gh/`
   - must be run within `git` repository
   - `gh init` mostly alias for `git config --local gh.conf "$HOME/.config/gh/"`

- `gh user USER` fetch/update all data for some user


# FAQ

License?

- This Works is placed under the terms of the Copyright Less License,
  see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

- This means, it is free as free beer, free speech, free baby


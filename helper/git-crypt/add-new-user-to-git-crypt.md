# Adding a new user to [git-crypt](https://github.com/AGWA/git-crypt)

## Create/Find keybase.io user

If you don't have a user at [keybase.io](https://keybase.io) with a valid pgp key, please create on.

Verify the given user:
* Visit https://keybase.io/USERID
* OR run `keybase id USERID` 


## Add key to git-crypt

Stash any uncommited changes
`git stash`

Execute
[`./add-keybase.io-user.sh <username>`](./add-keybase.io-user.sh)

When prompted for a level of trust, enter `5` for _Ultimate_ trust
`Your decision? 5`

## [Optional] Rebase all other branches if needed

Set up:
`git checkout develop`
`git fetch -apt`
`git rebase`

For each branch do the following:
`git checkout <branch>`
`git merge develop`
`git push`

## On the users machine

Clone the repository
`git clone REPO-URL`

Unlock the repository
`git-crypt unlock`

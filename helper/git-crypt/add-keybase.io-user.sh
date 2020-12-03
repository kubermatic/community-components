#!/usr/bin/env bash
#
# Script will add GPG keys to git-crypt by the use keybase.io

if [ -z "$1" ]
then
  echo " Use:"
  echo "  ./add-keybase.io-user.sh [keybase ID] "
  echo ""
  echo " Find user trough: https://keybase.io"
  echo ""
  echo " E.g.:"
  echo "  ./add-keybase.io-user.sh exampleUser"
  exit;
fi

set -euf -o pipefail

TMPDIR=./tmphome

#function needed to ensure deletion of $TMPDIR
add_user() (
    mkdir -m 0700 $TMPDIR

    #download key from keybase.io
    curl "https://keybase.io/$1/pgp_keys.asc" > $TMPDIR/key.asc

    #Determine fingerprint
    gpg --homedir $TMPDIR --import $TMPDIR/key.asc
    FINGERPRINT=$(gpg --homedir $TMPDIR  --list-keys | grep --after-context=1 pub | sed -n 4p | sed 's/^ *//')

    echo "Fingerprint: $FINGERPRINT"
    #Import key to local store
    gpg --import $TMPDIR/key.asc

    #Checkout new branch
    git checkout -b "git-crypt/add-$1"
    #add user
    git-crypt add-gpg-user --trusted --no-commit $FINGERPRINT
    #Save User in USERS
    echo "$FINGERPRINT https://keybase.io/$1" >> USERS
    git add USERS .git-crypt/
    git commit -m "Update USERS: add https://keybase.io/$1"
    #Push the new commit to origin
    git push --set-upstream origin "git-crypt/add-$1"
)

add_user "$1"
rm -rf $TMPDIR

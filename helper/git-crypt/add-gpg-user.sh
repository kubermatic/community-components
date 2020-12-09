#!/usr/bin/env bash
#
# Alternative script based on keyserver
# HINT: didn't work well in the past, use -> add-keybase.io-user.sh script
#

if [ -z "$1" ]
then
  echo " Use:"
  echo "  ./add-gpg-user.sh [ID]"
  echo ""
  echo " E.g.:"
  echo "  ./add-gpg-user.sh example@loodse.com"
  exit;
fi

set -euf -o pipefail

#Read key from keyserver
gpg --keyserver pgp.uni-mainz.de --search-keys $1
#Trust key
gpg --yes --edit-key $1 trust quit
#Checkout new branch
git checkout -b "git-crypt/add-user-$1"
#Add user to git-crypt
FINGERPRINT="$(git-crypt add-gpg-user $1 | grep keys | sed 's=.*/==;s/\.[^.]*$//')"
#Save User in USERS
echo $FINGERPRINT $1 >> USERS
git add USERS
git commit -m "Update USERS"
#Push the new commit to origin
git push --set-upstream origin "git-crypt/add-user-$1"

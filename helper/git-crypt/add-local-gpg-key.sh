#!/usr/bin/env bash
# HINT:
# import your target GPG key before if not present
#   gpg --import key.pub.asc
# show KEY_ID
#   gpg --list-keys
#
# Alternative script based on keyserver
# HINT: didn't work well in the past, use -> add-keybase.io-user.sh script
#

if [ "$#" -lt 1 ]; then
  echo " Use:"
  echo "  ./add-gpg-user.sh KEY_ID [USER_ID]"
  echo ""
  echo " E.g.:"
  echo "  ./add-gpg-user.sh xxxx_KEY_ID_xxxx 'My User'"
  echo ""
  echo "  ./add-gpg-user.sh xxxx_KEY_ID_xxxx 'My User'"
  exit;
fi
user_id=$2
set -euf -o pipefail

if [ "$user_id" == "" ]; then
  user_id=$(gpg --with-colons --list-keys $1 | awk -F: '$1=="uid" { print $10 }' | awk '{print $1}')
fi
echo "user_id: $user_id"

FINGERPRINT=$1
echo "Fingerprint: $FINGERPRINT"
#Checkout new branch
git checkout -b "git-crypt/add-$user_id"
#add user
git-crypt add-gpg-user --trusted --no-commit $user_id
#Save User in USERS
echo "$FINGERPRINT $user_id" >> USERS
git add USERS .git-crypt/
git commit -m "Update USERS: add $user_id"
#Push the new commit to origin
git push --set-upstream origin "git-crypt/add-$user_id"


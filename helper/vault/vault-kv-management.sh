#!/usr/bin/env bash
#cd $(dirname $(realpath $0))
#FOLDER=$(pwd)
arg_1="$1"
set -euo pipefail

VAULT_ENGINE_PATH=${VAULT_ENGINE_PATH:-"cubbyhole"}
LOCAL=${LOCAL:-"secrets/"}
mkdir -p $LOCAL

put_to_kv(){
  ### check store is present, if not init
  local sec_name=$(basename $1)
  if vault kv get $VAULT_ENGINE_PATH > /dev/null 2>&1; then
    echo " -> patch" && vault kv patch $VAULT_ENGINE_PATH "$sec_name=@$1"
  else
    echo " -> put" && vault kv put $VAULT_ENGINE_PATH "$sec_name=@$1"
  fi
}
if [[ "$arg_1" == "--upload" ]]; then
    echo "==> Update in $VAULT_ENGINE_PATH:"
    echo "$LOCAL"
    for file in `find $LOCAL -maxdepth 1 -type f `; do
        echo ""
        read -n1 -p "Update '$file' ? [y,n]" doit
        case $doit in
          y|Y) put_to_kv $file;;
          *) echo "...skip" ;;
        esac
#        vault kv patch dev/seed-clusters/run-2.lab.kubermatic.io values.yaml=@run-2.lab.kubermatic.io/values.yaml

    done
    exit 0
fi

mkdir -p $LOCAL/.old
for val in `vault kv get -format=json $VAULT_ENGINE_PATH | jq '.data.data | keys[]' -r`; do
    echo "... download $val > $LOCAL/$val"
    if [ -f "$LOCAL/$val" ]; then
      cp $LOCAL/$val $LOCAL/.old/
    fi
    vault kv get -field=$val  $VAULT_ENGINE_PATH > "$LOCAL/$val"
done
## update permissions
fileexts=(
  kubeconfig
  id_rsa
  id_rsa.pub
)
for f in "${fileexts[@]}"; do
  find $LOCAL -name "*$f" -exec echo "modify to 600:" {} + -exec chmod 600 {} +
done

#source this file to start ssh-agent with defined SSH key

eval `ssh-agent`
echo "ssh-agent started!"

#load private key
FOLDER=$(dirname $BASH_SOURCE)
PK_FILE=$FOLDER/credentials/id_rsa

echo "set permissions $PK_FILE"
chmod 0600 $PK_FILE

echo "add $PK_FILE"
ssh-add $PK_FILE

#load aws service account credentials
source $FOLDER/credentials/aws_credentials.sh

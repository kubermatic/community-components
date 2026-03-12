#!/bin/bash

# Creates or updates an A or CNAME DNS record within Route53
# Usage: ./route53-modify-record.sh ACTION ZONEID DOMAIN TYPE VALUE

usage() {
	echo "Usage: $0 ACTION ZONEID DOMAIN TYPE VALUE" >&2
	echo "Examples:" >&2
	echo "  $0 DELETE /hostedzone/Z08267412VFVFOL4NEM4P johndoe.lab.kubermatic.io A 35.198.145.19" >&2
	echo "  $0 UPSERT /hostedzone/Z08267412VFVFOL4NEM4P johndoe.lab.kubermatic.io CNAME cafebabe.eu-central-1.elb.amazonaws.com" >&2
}

if [ $# -ne 5 ]; then
	usage
	exit 1
fi

set -euo pipefail

ACTION="$1"
ZONEID="$2"
DOMAIN="$3"
TYPE="$4"
VALUE="$5"

case "$ACTION" in
	UPSERT|DELETE) ;;
	*) usage; echo "ERROR: ACTION must be one of UPSERT or DELETE but '$ACTION' given" >&2; exit 1;
esac

case "$TYPE" in
	A|CNAME) ;;
	*) usage; echo "ERROR: TYPE must be one of A or CNAME but '$TYPE' given" >&2; exit 1;
esac

if [ "$TYPE" = A ] && ! echo "$VALUE" | grep -Eq '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
    echo "ERROR: Invalid IP address format: '$VALUE'" >&2
    exit 1
fi

if ! echo "$DOMAIN" | grep -Eq '^(\*\.)?[a-zA-Z0-9][a-zA-Z0-9\.-]*[a-zA-Z0-9]$'; then
    echo "ERROR: Invalid domain name format: '$DOMAIN'" >&2
    exit 1
fi

source "$(dirname "$0")/route53-login.sh"

echo "${ACTION}ing $TYPE record for $DOMAIN -> $VALUE in zone $ZONEID"

CHANGE_BATCH="$(jq -n --arg a "$ACTION" --arg d "$DOMAIN" --arg t "$TYPE" --arg v "$VALUE" \
	'{Changes:[{Action:$a,ResourceRecordSet:{Name:$d,Type:$t,TTL:300,ResourceRecords:[{Value:$v}]}}]}')"

aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONEID" \
    --change-batch "$CHANGE_BATCH" \
    --output json >/dev/null

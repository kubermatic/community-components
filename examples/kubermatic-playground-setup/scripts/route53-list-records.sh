#!/bin/bash

# Script to list DNS records in AWS Route53
# Usage: ./route53-list-records.sh <ZONEID>

if [ $# -gt 1 ]; then
	echo "Usage: $0 ZONEID" >&2
	echo "Example: $0 /hostedzone/Z08267412VFVFOL4NEM4P" >&2
	exit 1
fi

source "$(dirname "$0")/route53-login.sh"

set -euo pipefail

if [ $# -eq 0 ]; then
	echo "Listing available zones..."
	aws route53 list-hosted-zones --output json \
		| jq -re '.HostedZones[] | .Id + " " + .Name'
else
	echo "Retrieving DNS records..."
	aws route53 list-resource-record-sets --hosted-zone-id "$1" --output json \
		| jq -re '.ResourceRecordSets[] | select(.Type | IN("A", "CNAME")) | .Name + " -> " + .Type + " " + ([.ResourceRecords[]?.Value] | join(", "))'
fi

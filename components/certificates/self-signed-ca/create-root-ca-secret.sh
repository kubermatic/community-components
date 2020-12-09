#!/usr/bin/env bash
#see https://kubernetes.github.io/ingress-nginx/user-guide/tls/

KEY_FILE=$(dirname "$0")/easy-rsa-master/easyrsa3/pki/private/ca.key
CERT_FILE=$(dirname "$0")/easy-rsa-master/easyrsa3/pki/ca.crt

kubectl -n cert-manager create secret tls ca-key-pair --key ${KEY_FILE} --cert ${CERT_FILE} -o yaml --dry-run > secrect.ca.yaml

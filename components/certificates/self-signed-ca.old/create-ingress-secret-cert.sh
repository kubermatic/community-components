#!/usr/bin/env bash
#see https://kubernetes.github.io/ingress-nginx/user-guide/tls/
certname=kubermatic.test-00-otto-k1.loodse.training
KEY_FILE=$(dirname "$0")/custom-pki/pki/private/${certname}.key
CERT_FILE=$(dirname "$0")/custom-pki/pki/issued/${certname}.crt
CA_CERT_FILE=$(dirname "$0")/custom-pki/pki/ca.crt

kubectl -n default create secret tls kubermatic-tls-certificates --key ${KEY_FILE} --cert ${CERT_FILE}


cp $CA_CERT_FILE $(dirname "$0")/root-cas/
chmod 644 $CA_CERT_FILE $(dirname "$0")/root-cas/ca.crt

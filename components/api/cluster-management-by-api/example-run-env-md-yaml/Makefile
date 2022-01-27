########### SCRIPT PARAMETERS
SCRIPT_FOLDER ?= $(shell cd ../common-scripts && pwd)
CLUSTER_APPLY ?= "${SCRIPT_FOLDER}/cluster-apply.sh"
MD_APPLY ?= "${SCRIPT_FOLDER}/md-apply.sh"
CLUSTER_DELETE ?= "${SCRIPT_FOLDER}/cluster-delete.sh"
CLUSTER_DELETE_ALL ?= "${SCRIPT_FOLDER}/cluster-delete-all.sh"

#### json file names
KKP_CLUSTER_PAYLOAD=cluster.json
KKP_CLUSTER_ADDON=addon-*.json
KKP_CLUSTER_ADD_MACHINE_DEPLOYMENT=machine_deployment*.json

SHELL=/bin/bash
include ./.kkp-env.sh
export

CLUSTER_SPEC ?= "kubevirt-with-autoscaling"

#doc The makefile manage the different operations to the KKP API.
#doc Please ensure your correct configured .kkp-env.sh
#doc Therefore you can find the following operations:
#doc usage: ENV=val make TARGET
#doc

#doc [CLUSTER_SPEC=vsphere] make apply-cluster:
#doc 	applies cluster spec over the KKP API
#doc
.PHONY: apply-cluster
apply-cluster:
	cd ${CLUSTER_SPEC} && ${CLUSTER_APPLY}

#doc make apply-all-clusters:
#doc 	executes make apply-cluster on all directories at the current location of the Makefile
#doc
.PHONY: apply-all-clusters
apply-all-clusters:
	for cl in */ ; do CLUSTER_SPEC=$${cl} make apply-cluster; done

#doc CLUSTER_ID=xxxxx make apply-machine-deployment:
#doc 	applies machine deployment spec over the KKP API to a existing cluster
#doc
.PHONY: apply-machine-deployment
apply-machine-deployment:
	cd ${CLUSTER_SPEC} && ${MD_APPLY}

#doc CLUSTER_ID=xxxxx make delete-cluster:
#doc 	delete cluster with specific cluster id
#doc
.PHONY: delete-cluster
delete-cluster:
	cd ${CLUSTER_SPEC} && ${CLUSTER_DELETE}

#doc make delete-all-cluster:
#doc 	delete all clusters in specified project
#doc
.PHONY: delete-all-cluster
delete-all-cluster:
	${CLUSTER_DELETE_ALL}

#doc make help:
#doc 	print help
#doc
.PHONY: help
help: Makefile
	@sed -n 's/^#doc//p' $<




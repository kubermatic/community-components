
# Kubermatic node health checks

*date: 2019-08-18*
- The machine-controller does not delete unhealthy nodes if the machine are present at the cloud provider.
- The machine-controller will delete & recreate a cloud provider instance if it does not join the cluster within a certain amount of time.
- Also the machine-controller will create a new cloud provider instance if the node turns unhealthy (on the init process) and the actual cloud provider instance does not exist anymore.


If e.g. a worker node get in trouble and kublet doesn't respond anymore. We would detect this, but wouldn't do an action on it. Similar to [GKE node auto repair](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair)  we cloud give an end user the option to trigger automatic reprovisioning of the node. Currently he needs to delete the `machine` object by hand to trigger a new provisioning.

Kubermatic issue: 
https://github.com/kubermatic/kubermatic/issues/4101
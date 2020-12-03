# "Static" audit logging.

Edit `/etc/kubernetes/manifests/kube-apiserver.yaml` on *all masters*.

# Enable via apiserver flags

Add two flags like this:
```
[...]
spec:
  containers:
  - command:
    - kube-apiserver
    - --audit-policy-file=/etc/kubernetes/audit/policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit.log
[...]
```

- `--audit-policy-file` Specifies the file that contains the policy on what to log. This *cannot* be specified with `kubectl` and such. Create this file and define to policy, for example the following to log the metadata of all requests:

```
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
```

- `--audit-log-path` sets the log file to dump messages into. This file is created on each master nodes and contains all the logs regarding this master only. Use some log scraper and enjoy a huge pile of text :)

- Log rotation is also supported. Use the following additional flags:
  - `--audit-log-maxage` defined the maximum number of days to retain old audit log files
  - `--audit-log-maxbackup` defines the maximum number of audit log files to retain
  - `--audit-log-maxsize` defines the maximum size in megabytes of the audit log file before it gets rotated

# Mount directories

Since the apiserver is running inside a pod you need to provide volumes:

```
[...]
volumeMounts:
- mountPath: /etc/kubernetes/audit
  name: auditconf
  readOnly: true
- mountPath: /var/log/kubernetes
  name: log
  readOnly: false
[...]
volumes:
- hostPath:
    path: /etc/kubernetes/audit
    type: DirectoryOrCreate
  name: auditconf
- hostPath:
    path: /var/log/kubernetes
    type: DirectoryOrCreate
  name: log
[...]
```

Restart the kubelet (`systemctl restart kubelet`) and you should see the file being populated.

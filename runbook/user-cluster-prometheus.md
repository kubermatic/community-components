# Crash Looping Prometheus at KKP user cluster namespace

Sometimes if users run extensive workload at their cluster, it could happen that the default resource limits are not enough. So for this it's needed to potential override the default resource limits of the user cluster prometheus.

## Symptom

If you see some crashing pods:
```bash
kubectl get pods -A | grep -iv running
```
```
NAMESPACE                  NAME                      READY   STATUS             RESTARTS   AGE
cluster-7tpxzbd65g         prometheus-0              0/1     CrashLoopBackOff   50         6d16
```
Describe the pod to get more information:
```
kubectl describe pod -n cluster-7tpxzbd65g prometheus-0
```
Mostly you will see some error like `OOMKilled` at the `prometheus` container:
```
Controlled By:  StatefulSet/prometheus
Containers:
  prometheus:
    Container ID:  containerd://8db782b1d42d5640226ba931644855ca5cad8b135c70804cc31380250ae86048
    Image:         quay.io/prometheus/prometheus:v2.25.0
    Image ID:      quay.io/prometheus/prometheus@sha256:fd8b3c4c7ced91cbe96aa8a8dd4d02aa5aff7aefdaf0e579486127745c758c27
    Port:          9090/TCP
    Host Port:     0/TCP
    Args:
      --config.file=/etc/prometheus/config/prometheus.yaml
      --storage.tsdb.path=/var/prometheus/data
      --storage.tsdb.min-block-duration=15m
      --storage.tsdb.max-block-duration=30m
      --storage.tsdb.retention.time=1h
      --web.enable-lifecycle
      --storage.tsdb.no-lockfile
      --web.route-prefix=/
    State:          Running
      Started:      Wed, 14 Jul 2021 17:12:50 +0200
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Wed, 14 Jul 2021 17:06:20 +0200
      Finished:     Wed, 14 Jul 2021 17:07:46 +0200
    Ready:          False
    Restart Count:  51
    Limits:
      cpu:     100m
      memory:  1Gi
    Requests:
      cpu:        50m
      memory:     256Mi
```
So `OOMKilled` indicates that assigned memory limit of `1Gi` is not efficient enough in this case. If you take a look at the `StatefulSet` object you also see that resource limits are maybe set to low: 
```
kubectl get sts prometheus -o yaml | kexp
```
Note: [`kexp`](https://github.com/kubermatic/fubectl/blob/master/fubectl.source#L104) is a command of [fubectl](https://github.com/kubermatic/fubectl) to extract the temporary status values of the object.
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app: prometheus
    cluster: 7tpxzbd65g
  name: prometheus
  namespace: cluster-7tpxzbd65g
spec:
  podManagementPolicy: OrderedReady
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: prometheus
      cluster: 7tpxzbd65g
  serviceName: ""
  template:
    metadata:
      creationTimestamp: null
      labels:
        apiserver-etcd-client-certificate-secret-revision: "22622916"
        app: prometheus
        cluster: 7tpxzbd65g
        prometheus-apiserver-certificate-secret-revision: "22624023"
        prometheus-configmap-revision: "22624024"
    spec:
      containers:
      - args:
        - --config.file=/etc/prometheus/config/prometheus.yaml
        - --storage.tsdb.path=/var/prometheus/data
        - --storage.tsdb.min-block-duration=15m
        - --storage.tsdb.max-block-duration=30m
        - --storage.tsdb.retention.time=1h
        - --web.enable-lifecycle
        - --storage.tsdb.no-lockfile
        - --web.route-prefix=/
        image: quay.io/prometheus/prometheus:v2.25.0
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 10
          httpGet:
            path: /-/healthy
            port: web
            scheme: HTTP
          initialDelaySeconds: 30
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 3
        name: prometheus
        ports:
        - containerPort: 9090
          name: web
          protocol: TCP
        readinessProbe:
          failureThreshold: 6
          httpGet:
            path: /-/ready
            port: web
            scheme: HTTP
          initialDelaySeconds: 5
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 3
        resources:
          limits:
            cpu: 100m
            memory: 1Gi
          requests:
            cpu: 50m
            memory: 256Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /etc/prometheus/config
          name: config
          readOnly: true
        - mountPath: /var/prometheus/data
          name: data
        - mountPath: /etc/etcd/pki/client
          name: apiserver-etcd-client-certificate
          readOnly: true
        - mountPath: /etc/kubernetes
          name: prometheus-apiserver-certificate
          readOnly: true
      dnsPolicy: ClusterFirst
      imagePullSecrets:
      - name: dockercfg
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext:
        fsGroup: 2000
        runAsNonRoot: true
        runAsUser: 1000
      serviceAccount: prometheus
      serviceAccountName: prometheus
      terminationGracePeriodSeconds: 0
      volumes:
      - configMap:
          defaultMode: 420
          name: prometheus
        name: config
      - name: data
      - name: apiserver-etcd-client-certificate
        secret:
          defaultMode: 420
          secretName: apiserver-etcd-client-certificate
      - name: prometheus-apiserver-certificate
        secret:
          defaultMode: 420
          secretName: prometheus-apiserver-certificate
  updateStrategy:
    type: RollingUpdate
```
## Solution for a single Cluster

As the Kubermatic cluster controller is managing the `StatefulSet` object, it's not possible to override the resource limits directly in the `StatefulSet` object. it would be possible you set the `spec.pause=true`, but this breaks the update and control behaviour of KKP, as `pause` means, to disable the cluster controller at all.

A better and constant solution is to overwrite the value at the `spec.componentsOverride` field, similar as described for e.g. `etcd` in the official [KKP documentation - Scaling the Control Plane](https://docs.kubermatic.com/kubermatic/master/tutorials_howtos/operation/control_plane/scaling_the_control_plane/#setting-custom-overrides).
```
kubectl edit cluster xxxx
```
```yaml
apiVersion: kubermatic.k8s.io/v1
kind: Cluster
metadata:
  name: xxxxx
spec:
  componentsOverride:
    ####################### <<<<<<<< update
    prometheus: 
      resources:
        limits:
          cpu: 300m
          memory: 3Gi
        requests:
          cpu: 150m
          memory: 750Mi
  ####################### <<<<<<<< update
```
After the edit, the cluster reconciliation should automatically patch the `StatefulSet` and trigger a rolling deployment of the `prometheus` pods:
```bash
kubectl get sts prometheus -o yaml | kexp
```
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app: prometheus
    cluster: 7tpxzbd65g
  name: prometheus
  namespace: cluster-7tpxzbd65g
spec:
  podManagementPolicy: OrderedReady
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: prometheus
      cluster: 7tpxzbd65g
  serviceName: ""
  template:
    metadata:
      creationTimestamp: null
      labels:
        apiserver-etcd-client-certificate-secret-revision: "22622916"
        app: prometheus
        cluster: 7tpxzbd65g
        prometheus-apiserver-certificate-secret-revision: "22624023"
        prometheus-configmap-revision: "22624024"
    spec:
      containers:
      - args:
        - --config.file=/etc/prometheus/config/prometheus.yaml
        - --storage.tsdb.path=/var/prometheus/data
        - --storage.tsdb.min-block-duration=15m
        - --storage.tsdb.max-block-duration=30m
        - --storage.tsdb.retention.time=1h
        - --web.enable-lifecycle
        - --storage.tsdb.no-lockfile
        - --web.route-prefix=/
        image: quay.io/prometheus/prometheus:v2.25.0
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 10
          httpGet:
            path: /-/healthy
            port: web
            scheme: HTTP
          initialDelaySeconds: 30
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 3
        name: prometheus
        ports:
        - containerPort: 9090
          name: web
          protocol: TCP
        readinessProbe:
          failureThreshold: 6
          httpGet:
            path: /-/ready
            port: web
            scheme: HTTP
          initialDelaySeconds: 5
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 3
        resources:
          limits:
            cpu: 300m
            memory: 3Gi
          requests:
            cpu: 150m
            memory: 750Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /etc/prometheus/config
          name: config
          readOnly: true
        - mountPath: /var/prometheus/data
          name: data
        - mountPath: /etc/etcd/pki/client
          name: apiserver-etcd-client-certificate
          readOnly: true
        - mountPath: /etc/kubernetes
          name: prometheus-apiserver-certificate
          readOnly: true
      dnsPolicy: ClusterFirst
      imagePullSecrets:
      - name: dockercfg
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext:
        fsGroup: 2000
        runAsNonRoot: true
        runAsUser: 1000
      serviceAccount: prometheus
      serviceAccountName: prometheus
      terminationGracePeriodSeconds: 0
      volumes:
      - configMap:
          defaultMode: 420
          name: prometheus
        name: config
      - name: data
      - name: apiserver-etcd-client-certificate
        secret:
          defaultMode: 420
          secretName: apiserver-etcd-client-certificate
      - name: prometheus-apiserver-certificate
        secret:
          defaultMode: 420
          secretName: prometheus-apiserver-certificate
  updateStrategy:
    type: RollingUpdate
```
Check again if the pod is crashing:
```bash
kubectl get pods -n -cluster-7tpxzbd65g | grep -iv running
```
```
NAME                      READY   STATUS             RESTARTS   AGE
prometheus-0              0/1     CrashLoopBackOff   60         6d16
```
As the `StatefulSet` contains the updated resource limits, sometimes you need to delete the crashing pod, to ensure that change is happen also to the pod level:
```bash
kubectl delete pod -n -cluster-7tpxzbd65g prometheus-0 
```
After the deletion, the `StatefulSet` controller schedules a new instance with the updated resource limits, what's should come up in the `Running` state:
```bash
kubectl get pod -n cluster-7tpxzbd65g -l app=prometheus
```
```
NAME           READY   STATUS    RESTARTS   AGE
prometheus-0   1/1     Running   0          116s
```

## General Defaulting of User Cluster Prometheus Resources

Currently, it's not implemented. So unfortunately right now the limits needs to get patched at every cluster.
See GitHub Reference issue: https://github.com/kubermatic/kubermatic/issues/5998



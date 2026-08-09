# Kubermatic Virtualization Tooling Container

based on [kubeone-tooling-container](https://github.com/kubermatic/community-components/tree/master/container/kubeone-tool-container)

**REPO: [`quay.io/kubermatic/kubermatic-virtualization-tooling`](https://quay.io/repository/kubermatic/kubermatic-virtualization-tooling)** 


## Prerequisites

Before building the container, you need to create a Quay.io authentication file:

```bash
mkdir -p .local
# Create docker-auth.json with your Quay.io credentials
cat > .local/docker-auth.json <<EOF
{
  "auths": {
    "quay.io": {
      "auth": "<base64-encoded-username:password>"
    }
  }
}
EOF
```

## Usage
1) Use Makefile Targets

2) Docker
```bash
docker run -it --user 0 --rm --name kubev --detach \
                -v /MY_LOCAL_PATH:/home/kubermatic/mnt \
                quay.io/kubermatic/kubermatic-virtualization-tooling \
                bash
```

Then you should be able to use `docker exec -it kubev bash`:
```bash
 _  __     _           ___                       _   _ ____    _ 
| |/ /   _| |__   ___ / _ \ _ __   ___          / | / |___ \  / |
| ' / | | | '_ \ / _ \ | | | '_ \ / _ \  _____  | | | | __) | | |
| . \ |_| | |_) |  __/ |_| | | | |  __/ |_____| | |_| |/ __/ _| |
|_|\_\__,_|_.__/ \___|\___/|_| |_|\___|         |_(_)_|_____(_)_|
                                                                 
                                                                        
                   Kubermatic Virtualization Details                    
╭──────────────────────────────────────────────────────────────────────╮
│             Component                           Version              │
│ Kubermatic Virtualization          45e32153805fbae3cb86aac6c4938758f │
│                                    0…                                │
│ Kubernetes                         v1.33.0                           │
│ KubeOVN CNI                        v1.13.2                           │
│ Multus CNI                         v4.2.2                            │
│ Kyverno                            3.5.0                             │
│ Metal LB                           0.15.2                            │
│ Cert Manager                       v1.18.2                           │
│ Longhorn                           1.9.1                             │
│ Kubevirt                           v1.5.2                            │
╰──────────────────────────────────────────────────────────────────────╯
 root  b55f121c8b63  home  kubermatic  #  
```
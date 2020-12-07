# Addon: Theia IDE

Customized KKP addon for quickly using [Eclipse Theia IDE](https://theia-ide.org/) at your Kubernetes cluster.

*NOTE*: Currently the service get exposed by http, what is **NOT** recommended using in production!

### Build & Run locally
The current [`Dockerfile`](./Dockerfile) is based on [theiaide/theia-go](https://github.com/theia-ide/theia-apps/tree/master/theia-go-docker)
```
docker build -t local/theia . && docker run -it --init -p 3000:3000  local/theia
```
To include a local filesystem a folder can get mounted:
```
docker build -t local/theia . && docker run -it --init -p 3000:3000 -v `pwd`:/home/project/ local/theia
```

### TODOs
- add secure connection infront of the service: Ingress
- add authentication layer: IAP as used for KKP monitoring
    - pot. alternative: https://github.com/theia-ide/theia-apps/tree/master/theia-https-docker
- potential integrate to kubeone / KKP native


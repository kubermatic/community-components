### specify kubectl version e.g. 1.19
ARG BITNAMI_KUBECTL_VERSION
FROM bitnami/kubectl:${BITNAMI_KUBECTL_VERSION}

### specify trident release version e.g. 20.07.0
ARG TRIDENT_VERSION

RUN cd /opt \
  && wget https://github.com/NetApp/trident/releases/download/v${TRIDENT_VERSION}/trident-installer-${TRIDENT_VERSION}.tar.gz \
  && tar -xf trident-installer-${TRIDENT_VERSION}.tar.gz
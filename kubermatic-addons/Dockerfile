### specify kubermatic release version e.g. v2.14.0-rc.1
ARG KUBERMATIC_VERSION
FROM quay.io/kubermatic/addons:$KUBERMATIC_VERSION

LABEL maintainer="ps@loodse.com"

ADD ./custom-addon/ /addons/
RUN echo "Delete non *.yaml files:" && find /addons/*/ -type f -not -name '*.yaml' -print -delete
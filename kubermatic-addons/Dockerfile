### specify kubermatic release version e.g. v2.14.0-rc.1
ARG KKP_VERSION
FROM quay.io/kubermatic/addons:$KKP_VERSION

LABEL maintainer="ps@loodse.com"

ADD ./custom-addon/ /addons/
RUN echo "Delete non *.yaml files:" && find /addons/*/ -type f -not -name '*.yaml' -print -delete \
    && echo "Set file system permissions of addons: " \
    && find /addons/ -type d -exec chmod 755 {} \; \
    && find /addons/ -type f -exec chmod 644 {} \;

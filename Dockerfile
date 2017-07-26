FROM centos:7
MAINTAINER ManageIQ https://github.com/ManageIQ/manageiq-appliance-build

## Set build ARGs
ARG REF=master

ENV CONTAINER_SCRIPTS_ROOT=/opt/manageiq/container-scripts \
    IMAGE_VERSION=${REF}

## Atomic/OpenShift Labels
LABEL name="manageiq-tools" \
      vendor="ManageIQ" \
      version="Master" \
      release=${REF} \
      url="http://manageiq.org/" \
      summary="ManageIQ helper tools" \
      description="ManageIQ helper tools" \
      io.k8s.display-name="ManageIQ-tools" \
      io.k8s.description="ManageIQ helper tools" \
      io.openshift.tags="ManageIQ,miq,manageiq"

## Install tools
RUN yum install -y centos-release-scl-rh && \
    yum install -y --setopt=tsflags=nodocs  \
                rh-postgresql95-postgresql  \ 
                rh-postgresql95-postgresql-server \
                &&                          \
    yum clean all

## Copy scripts
COPY docker-assets/user-setup /tmp/
COPY docker-assets/entrypoint /bin
ADD  docker-assets/container-scripts ${CONTAINER_SCRIPTS_ROOT}

## Setup user for build execution and application runtime
ENV USER_NAME=manageiq \
    USER_UID=10001
RUN chmod -R ug+x ${CONTAINER_SCRIPTS_ROOT} /tmp/user-setup && \
    /tmp/user-setup

## User name recognition at runtime w/ an arbitrary uid - for OpenShift deployments
RUN sed "s@${USER_NAME}:x:${USER_UID}:@${USER_NAME}:x:\${USER_ID}:@g" /etc/passwd > /etc/passwd.template

## Containers should NOT run as root as a good practice
USER 10001
WORKDIR ${CONTAINER_SCRIPTS_ROOT}
ENTRYPOINT [ "entrypoint" ]

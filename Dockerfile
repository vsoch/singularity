FROM golang:stretch

# Overview:
# image with the go tools for developing Singularity
# you should bind your singularity/src folder to /code, or
# develop in the container. If you do the first and make
# changes in the container, be careful about permissions of the
# files outside of the container (Docker runs as root user and o
# the files will be root owned on the local development machine
#
# Building: 
# docker build -t vanessa/singularity-dev .
# 
# Interactive Session
# docker run --privileged -it --entrypoint bash vanessa/singularity-dev
#
# Testing (inside container) example
# docker run --privileged -it --entrypoint go vanessa/singularity-dev test ./tests/

ENV PATH="${GOPATH}/bin:${PATH}"

RUN echo "Installing build dependencies!\n" && apt-get update && \
    apt-get install -y squashfs-tools \
                       libssl-dev \
                       uuid-dev \
                       curl \
                       libarchive-dev \ 
                       libgpgme11-dev


WORKDIR /code
ENV SRC_DIR=/go/src/github.com/singularityware/singularity
ADD . $SRC_DIR
WORKDIR $SRC_DIR

RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh && \
    dep ensure -vendor-only

# Compile the Singularity binary
RUN ./mconfig && \
     cd ./builddir && \
    make dep && make && make install

WORKDIR $SRC_DIR
RUN test -z $(go fmt ./...)

# HEALTHCHECK go test ./tests/

ENTRYPOINT ["singularity"]

FROM iron/go:dev

# Overview:
# alpine image with the go tools for developing Singularity
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
# docker run -it --entrypoint sh vanessa/singularity-dev

# For future - if we want the Dockerfile isolated from repo -
#   We can take the repository username / branch as build-arg
#   below shows setting defaults
#   ARG REPO=singularityware
#   ARG BRANCH=development-3.x
#   and then clone the repository here (instead of ADD . /code)

RUN echo "Installing build dependencies!\n" && \
    apk add --update alpine-sdk linux-headers \
                     e2fsprogs bash tar rsync squashfs-tools \
                     openssl-dev util-linux-dev

WORKDIR /code
ENV SRC_DIR=/go/src/github.com/singularityware/singularity
ADD . $SRC_DIR
WORKDIR $SRC_DIR

# Dependencies
RUN go get -v github.com/golang/dep/cmd/dep && \
    dep ensure -v

# Compile the Singularity binary
RUN ./mconfig && \
    cd ./builddir && \
    make dep && make && make install

ENTRYPOINT ["singularity"]

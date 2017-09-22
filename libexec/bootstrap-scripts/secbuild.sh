#!/bin/bash
# 
# Copyright (c) 2017, SingularityWare, LLC. All rights reserved.
# 
# See the COPYRIGHT.md file at the top-level directory of this distribution and at
# https://github.com/singularityware/singularity/blob/master/COPYRIGHT.md.
# 
# This file is part of the Singularity Linux container project. It is subject to the license
# terms in the LICENSE.md file found in the top-level directory of this distribution and
# at https://github.com/singularityware/singularity/blob/master/LICENSE.md. No part
# of Singularity, including this file, may be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE.md file.
#
# 

## Basic sanity
if [ -z "$SINGULARITY_libexecdir" ]; then
    echo "Could not identify the Singularity libexecdir."
    exit 1
fi

SECBUILD_IMAGE="$SINGULARITY_libexecdir/singularity/bootstrap-scripts/secbuild.img"

if [ ! -f "${SECBUILD_IMAGE:-}" ]; then
    echo
    echo "$SECBUILD_IMAGE is missing, build it as root by typing:"
    echo
    echo "make secbuildimg"
    echo
    exit 1
fi

## Load functions
if [ -f "$SINGULARITY_libexecdir/singularity/functions" ]; then
    . "$SINGULARITY_libexecdir/singularity/functions"
else
    echo "Error loading functions: $SINGULARITY_libexecdir/singularity/functions"
    exit 1
fi
if [ -f "$SINGULARITY_libexecdir/singularity/bootstrap-scripts/functions" ]; then
    . "$SINGULARITY_libexecdir/singularity/bootstrap-scripts/functions"
else
    echo "Error loading functions: $SINGULARITY_libexecdir/singularity/bootstrap-scripts/functions"
    exit 1
fi

if [ -z "${SINGULARITY_ROOTFS:-}" ]; then
    message ERROR "Singularity root file system not defined\n"
    exit 1
fi

if [ -z "${SINGULARITY_BUILDDEF:-}" ]; then
    message ERROR "Singularity bootstrap definition file not defined!\n"
    exit 1
fi

if [ ! -f "${SINGULARITY_BUILDDEF:-}" ]; then
    message ERROR "Singularity bootstrap definition file not found!\n"
    exit 1
fi

BUILDDEF_DIR_NAME=$(dirname ${SINGULARITY_BUILDDEF:-})
BUILDDEF_DIR=$(realpath ${BUILDDEF_DIR_NAME:-})

if [ -z "${BUILDDEF_DIR:-}" ]; then
    message ERROR "Can't find parent directory of $SINGULARITY_BUILDDEF\n"
    exit 1
fi

BUILDDEF=$(basename ${SINGULARITY_BUILDDEF:-})

# create a temporary dir per build instance
export SINGULARITY_WORKDIR=$(mktemp -d)

# create /tmp and /var/tmp into WORKDIR
mkdir -p $SINGULARITY_WORKDIR/tmp $SINGULARITY_WORKDIR/var_tmp

# set sticky bit for these directories
chmod 1777 $SINGULARITY_WORKDIR/tmp
chmod 1777 $SINGULARITY_WORKDIR/var_tmp

# setup a fake root directory
cp -a /etc/skel $SINGULARITY_WORKDIR/root

REPO_DIR="/root/repo"
STAGED_BUILD_IMAGE="/root/build"

mkdir ${SINGULARITY_WORKDIR}${REPO_DIR}
mkdir ${SINGULARITY_WORKDIR}${STAGED_BUILD_IMAGE}

BUILD_SCRIPT="$SINGULARITY_WORKDIR/tmp/build-script"
TMP_CONF_FILE="$SINGULARITY_WORKDIR/tmp.conf"
FSTAB_FILE="$SINGULARITY_WORKDIR/fstab"

cat > "$FSTAB_FILE" << FSTAB
none $STAGED_BUILD_IMAGE      bind    dev     0 0
FSTAB

cat > "$TMP_CONF_FILE" << CONF
config passwd = no
config group = no
mount proc = no
mount sys = no
mount home = no
mount dev = minimal
mount tmp = no
enable overlay = no
user bind control = no
bind path = $SINGULARITY_WORKDIR/root:/root
bind path = $SINGULARITY_WORKDIR/tmp:/tmp
bind path = $SINGULARITY_WORKDIR/var_tmp:/var/tmp
bind path = $SINGULARITY_ROOTFS:$STAGED_BUILD_IMAGE
bind path = $BUILDDEF_DIR:$REPO_DIR
bind path = $FSTAB_FILE:/etc/fstab
CONF

# here build pre-stage
cat > "$BUILD_SCRIPT" << SCRIPT
#!/bin/sh

mount -r --no-mtab -t proc proc /proc
if [ \$? != 0 ]; then
    echo "Can't mount /proc directory"
    exit 1
fi

mount -r --no-mtab -t sysfs sysfs /sys
if [ \$? != 0 ]; then
    echo "Can't mount /sys directory"
    exit 1
fi

mount -o remount,dev $STAGED_BUILD_IMAGE
if [ \$? != 0 ]; then
    echo "Can't remount $STAGED_BUILD_IMAGE"
    exit 1
fi

cd $REPO_DIR
singularity build -f -s $STAGED_BUILD_IMAGE $BUILDDEF
exit \$?
SCRIPT

chmod +x $BUILD_SCRIPT

unset SINGULARITY_IMAGE

${SINGULARITY_bindir}/singularity -c $TMP_CONF_FILE exec -e -i -p $SECBUILD_IMAGE /tmp/build-script
if [ $? != 0 ]; then
    rm -rf $SINGULARITY_WORKDIR
    exit 1
fi

rm -rf $SINGULARITY_WORKDIR
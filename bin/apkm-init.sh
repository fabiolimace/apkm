#!/bin/sh

#
# Initializes the APKM in the current directory.
#
# Also:
#
# *   Initializes a GIT repository, commiting all existing markdown files.
#
# Usage:
#
#     # Backup!
#     apkm-init.sh
#
# How to undo initialization:
#
#     # Be careful and backup!
#     rm -rf DIRECTORY/.apkm
#     rm -rf DIRECTORY/.git
#
# Where DIRECTORY is where this init script was executed.
#

. "`dirname "$0"`/apkm-common.sh";

apkm_init_fs() {
    
    echo "----------------------"
    echo "Init directory"
    echo "----------------------"
    echo "mkdir -p \"$WORKING_DIR/.apkm\""
    
    mkdir -p "$WORKING_DIR/.apkm"
    mkdir -p "$WORKING_DIR/.apkm/hist"
    mkdir -p "$WORKING_DIR/.apkm/html"
    mkdir -p "$WORKING_DIR/.apkm/meta"
    mkdir -p "$WORKING_DIR/.apkm/link"
    
cat > "$WORKING_DIR/.apkm/conf.txt" <<EOF
busybox.httpd.port=127.0.0.1:9000
EOF

}

apkm_init_git() {
    
    echo "----------------------"
    echo "Init GIT"
    echo "----------------------"
    
    git init --initial-branch=main
    git config user.name "apkm"
    git config user.email "apkm@example.com"
    find "$WORKING_DIR/" -type f -name "*.md" -exec git add {} \;
    git commit -m "[apkm] init"

cat > .gitignore <<EOF
.git/*
.apkm/*
.gitignore
EOF

}

if [ ! -d "$WORKING_DIR" ];
then
    echo "Base directory not found."
    exit 1;
fi;

if [ -d "$WORKING_DIR/.apkm" ];
then
    echo "APKM already initialized in this directory."
    exit 1;
fi;

# TODO: remove it after file history is ready
if [ -d "$WORKING_DIR/.git" ];
then
    echo "GIT already initialized in this directory." 1>&2;
    exit 1;
fi;

main() {
    apkm_init_fs;
    [ $ENABLE_GIT -eq 1 ] && apkm_init_git;
}

main;


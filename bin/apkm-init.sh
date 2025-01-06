#!/bin/sh

#
# Initializes the APKM in the current directory.
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

main() {
    apkm_init_fs;
}

main;


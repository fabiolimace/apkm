#!/bin/bash

#
# Saves metadata and links in `meta` folder and `apkm.db`.
#
# Usage:
#
#     apwm-save.sh FILE
#

source "`dirname "$0"`/apkm-common.sh" || exit 1;
validate_program_and_working_paths || exit 1;

FIND_REGEX=".*.\(md\|txt\)$";
IGNORE_REGEX="\\.\(apkm\|git\)";

while read -s line; do

    FILE=`echo $line | sed 's,^\./,,'`; # remove leading "./"
    
    "$PROGRAM_DIR/apkm-save-hist.sh" "$FILE";
    "$PROGRAM_DIR/apkm-save-html.sh" "$FILE";
    "$PROGRAM_DIR/apkm-save-meta.sh" "$FILE";
    "$PROGRAM_DIR/apkm-save-links.sh" "$FILE";

done < <(cd "$WORKING_DIR"; find . -type f -regex "$FIND_REGEX" | grep -v "$IGNORE_REGEX");


#!/bin/sh

#
# Saves metadata and links in `meta` folder and `apkm.db`.
#
# Usage:
#
#     apwm-save.sh FILE
#

. "`dirname "$0"`/apkm-common.sh";

# find .md and .txt files
find_regex=".*.\(md\|txt\)$";

# ignore .apkm and .git folders
ignore_regex="\\.\(apkm\|git\)";

main() {
    cd "$WORKING_DIR";
    find . -type f -regex "${find_regex}" | grep -v "${ignore_regex}" | while read -r line; do
        file=`echo $line | sed 's,^\./,,'`; # remove leading "./"
        "$PROGRAM_DIR/apkm-save-hist.sh" "$file";
        "$PROGRAM_DIR/apkm-save-html.sh" "$file";
        "$PROGRAM_DIR/apkm-save-meta.sh" "$file";
#        "$PROGRAM_DIR/apkm-save-link.sh" "$file";
    done;
}

main;


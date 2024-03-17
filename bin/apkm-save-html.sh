#!/bin/bash

#
# Saves HTML in `meta/html` folder.
#
# Usage:
#
#     apwm-save-html.sh FILE
#

source "`dirname "$0"`/apkm-common.sh" || exit 1;
validate_program_and_working_paths || exit 1;

function save_html {
    local FILE="${1}"
    local HTML=`path_html "$FILE"`
    mkdir --parents "`dirname "$HTML"`"
    "$PROGRAM_DIR/apkm-html.awk" "$FILE" > "$HTML"
}

FILE="${1}"

if [[ ! -f "$FILE" ]];
then
    echo "File not found: '$FILE'" 1>&2
    exit 1;
fi;

save_html "$FILE"


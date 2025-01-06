#!/bin/sh

#
# Saves HTML in `html` folder.
#
# Usage:
#
#     apwm-save-html.sh FILE
#

. "`dirname "$0"`/apkm-common.sh";

file="${1}"
require_file "${file}";

main() {
    local file="${1}"
    local html=`make_html "${file}"`
    mkdir -p "`dirname "${html}"`"
    "$PROGRAM_DIR/apkm-html.awk" "${file}" > "${html}"
}

main "${file}";


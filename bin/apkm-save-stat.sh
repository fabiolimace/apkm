#!/bin/sh

#
# Saves a STAT file in in `data` folder.
#
# Usage:
#
#     apwm-save-stat.sh FILE
#

. "`dirname "$0"`/apkm-common.sh";

file="${1}"
require_file "${file}";

main() {
    local file="${1}"
    local uuid=`path_uuid "${file}"`;
    local stat=`make_stat "${file}"`;
    LC_ALL=C "$PROGRAM_DIR/apkm-stat.awk" -v WRITETO=/dev/stdout "${file}" > "${stat}"
}

main "${file}";


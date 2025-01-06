#!/bin/sh

#
# Saves history in `hist` folder.
#
# Usage:
#
#     apwm-save-hist.sh FILE
#
# History file structure:
#
#     1. History file info '##'.
#     2. Start of diff '#@'.
#     3. End of diff '#%'.
# 

. "`dirname "$0"`/apkm-common.sh";

file="${1}"
require_file "${file}";

file_diff() {
    "$PROGRAM_DIR/apkm-load-hist.sh" "${file}" | diff -u /dev/stdin "${file}";
}

main() {

    local file="${1}"
    
    local uuid=`path_uuid "${file}"`;
    local hist=`make_hist "${uuid}"`;
    
    local path="${file}"
    local updt="`file_updt "${file}"`"
    local hash="`file_hash "${file}"`"
    
    if [ ! -f "${hist}" ]; then
        echo "$HIST_FILE_INFO uuid=${uuid}" >> "${hist}"
        echo "$HIST_FILE_INFO path=${path}" >> "${hist}"
    fi;
    
    cat >> "${hist}" <<EOF
${HIST_DIFF_START} ${updt}${HT}${hash}
`file_diff "${hist}"`
${HIST_DIFF_END}
EOF

}

main "${file}";


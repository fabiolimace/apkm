#!/bin/sh

#
# Saves history in `hist` folder and `apkm.db`.
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

last_hash() {
    local hist="${1}"
    tac "${hist}" | awk 'BEGIN { FS="'"${HT}"'" } /^'"${HIST_DIFF_START}"'/ { print $2; exit 0; }';
}

file_diff() {
    "$PROGRAM_DIR/apkm-load-hist.sh" "${file}" | diff -u /dev/stdin "${file}";
}

save_hist_fs() {

    local hist="${1}"
    local uuid="${2}"
    local path="${3}"
    local updt="${4}"
    local hash="${5}"
    
    if [ ! -f "${hist}" ]; then
        echo "$HIST_FILE_INFO uuid=${uuid}" >> "${hist}"
        echo "$HIST_FILE_INFO path=${path}" >> "${hist}"
    fi;
    
    if [ "${hash}" = "`last_hash "${hist}"`" ]; then
        return;
    fi;
    
    cat >> "${hist}" <<EOF
${HIST_DIFF_START} ${updt}${HT}${hash}
`file_diff "${path}"`
${HIST_DIFF_END}
EOF

}

save_hist_db() {

    local hist="${1}"
    local uuid="${2}"
    local path="${3}"
    local updt="${4}"
    local hash="${5}"
    
    if [ -f "${hist}" ]; then
        echo "INSERT OR REPLACE INTO hist_ values ('${uuid}', '${path}', '${updt}', '${hash}');" | sqlite3 "$DATABASE";
    fi;
}

main() {

    local file="${1}"
    local hist="`path_hist "${file}"`"
    
    local uuid="`path_uuid "${file}"`"
    local path="${file}"
    local updt="`file_updt "${file}"`"
    local hash="`file_hash "${file}"`"
    
    save_hist_fs "${hist}" "${uuid}" "${path}" "${updt}" "${hash}"
    [ $ENABLE_DB -eq 1 ] && save_hist_db "${hist}" "${uuid}" "${path}" "${updt}" "${hash}"
}

main "${file}";


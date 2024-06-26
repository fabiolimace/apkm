#!/bin/bash

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

FILE="${1}"

if [[ ! -f "$FILE" ]];
then
    echo "File not found: '$FILE'" 1>&2
    exit 1;
fi;

source "`dirname "$0"`/apkm-common.sh" || exit 1;
validate_program_and_working_paths || exit 1;

function last_hash {
    local HIST="${1}"
    tac "${HIST}" | awk 'BEGIN { FS="'"${TAB}"'" } /^'"${HIST_DIFF_START}"'/ { print $2; exit 0; }';
}

function file_diff {
    "$PROGRAM_DIR/apkm-load-hist.sh" "$FILE" | diff -u /dev/stdin "${FILE}";
}

function save_hist_fs {

    local FILE="${1}"
    local UUID="${2}"
    local UPDT="${3}"
    local HASH="${4}"
    
    local HIST="`path_hist "$FILE"`"
    
    if [[ ! -f "${HIST}" ]];
    then
        echo "$HIST_FILE_INF0 path=${FILE}" >> "${HIST}"
        echo "$HIST_FILE_INF0 uuid=${UUID}" >> "${HIST}"
    fi;
    
    if [[ "${HASH}" == "`last_hash "${HIST}"`" ]];
    then
        return;
    fi;
    
    cat >> "${HIST}" <<EOF
${HIST_DIFF_START} ${UPDT}${TAB}${HASH}
$(file_diff "$FILE")
${HIST_DIFF_END}
EOF

}

function save_hist_db {

    local FILE="${1}"
    local UUID="${2}"
    local UPDT="${3}"
    local HASH="${4}"
    
    echo "INSERT OR REPLACE INTO hist_ values ('$UUID', '$UPDT', '$HASH');" | sqlite3 "$DATABASE";
}

function save_hist {

    local FILE="${1}"
    local UUID="`path_uuid "$FILE"`"
    local UPDT="`file_updt "$FILE"`"
    local HASH="`file_hash "$FILE"`"
    
    save_hist_fs "$FILE" "$UUID" "$UPDT" "$HASH"
    save_hist_db "$FILE" "$UUID" "$UPDT" "$HASH"
}

save_hist "$FILE"


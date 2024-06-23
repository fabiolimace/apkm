#!/bin/bash

#
# Saves history in `hist` folder and `apkm.db`.
#
# Usage:
#
#     apwm-save-hist.sh FILE
#
# Notes:
# 1. File headers start with '#%'.
# 2. Diff headers start with '#@'.
# 

source "`dirname "$0"`/apkm-common.sh" || exit 1;
validate_program_and_working_paths || exit 1;

FILE="${1}"

if [[ ! -f "$FILE" ]];
then
    echo "File not found: '$FILE'" 1>&2
    exit 1;
fi;

function apply_patch {

    local TEMP_FILE="${1}"
    local TEMP_DIFF="${2}"
    local TEMP_HASH="${3}"
    
    patch -s -u "${TEMP_FILE}" "${TEMP_DIFF}";
    
    if [[ -n "${TEMP_HASH}" ]];
    then
        if [[ "`file_hash "${TEMP_FILE}"`" != "${TEMP_HASH}" ]];
        then
            echo "Error while replaying history: hashes don't match." > /dev/stderr;
            rm -f "${TEMP_FILE}" "${TEMP_DIFF}";
            exit 1;
        fi;
    fi;
}

function file_diff {

    local FILE="${1}"
    
    local HIST="`path_hist "$FILE"`"
    
    local TEMP_HASH="";
    local TEMP_DIFF="`make_temp`"
    local TEMP_FILE="`make_temp`"
    
    while IFS= read -r line; do
    
        if [[ $line =~ ^#% ]];  # file header
        then
            continue;
        elif [[ $line =~ ^#@ ]]; # diff header
        then
            apply_patch "${TEMP_FILE}" "${TEMP_DIFF}" "${TEMP_HASH}";
            
            TEMP_HASH="`echo "${line}" | sed -E 's/^#@ *//' | awk 'BEGIN { FS="'"${TAB}"'" } {print $2}'`";
            cat /dev/null > "${TEMP_DIFF}";
            continue;
        fi;

        echo "${line}" >> "${TEMP_DIFF}";
    
    done < <(cat "${HIST}")
    
    apply_patch "${TEMP_FILE}" "${TEMP_DIFF}" "${TEMP_HASH}";
    
    cat "${TEMP_FILE}" | diff -u /dev/stdin "${FILE}" && rm -f "${TEMP_FILE}" "${TEMP_DIFF}";
}

function last_hash {
    local HIST="${1}"
    tac "${HIST}" | awk 'BEGIN { FS="'"${TAB}"'" } /^#@/ { print $2; exit 0; }';
}

function save_hist_fs {

    local FILE="${1}"
    local UUID="${2}"
    local UPDT="${3}"
    local HASH="${4}"
    
    local HIST="`path_hist "$FILE"`"
    
    if [[ ! -f "${HIST}" ]];
    then
        echo "#% file=${FILE}" >> "${HIST}"
        echo "#% uuid=${UUID}" >> "${HIST}"
    fi;
    
    if [[ "${HASH}" == "`last_hash "${HIST}"`" ]];
    then
        return;
    fi;
    
    cat >> "${HIST}" <<EOF
#@ ${UPDT}${TAB}${HASH}
$(file_diff "$FILE")
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


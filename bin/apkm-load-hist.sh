#!/bin/bash

#
# Load a file version from file history.
#
# Usage:
#
#     apwm-save-load.sh FILE [DATE|HASH]
#
# Returns the first version that matches DATE or HASH, otherwise returns the latest version.
#
# Hints:
# 
#     1. You can search using the leading chars of HASH, e.g: "eeb180fa".
#     2. You can use ">" to load the first version whose date is greater than a date, e.g: ">2024-06-24"
#     2. You can use "<" to load the last version whose date is lower than a date, e.g: "<2024-06-24"
# 
# History file structure:
#
#     1. History file info '##'.
#     2. Start of diff '#@'.
#     3. End of diff '#&'.
# 

source "`dirname "$0"`/apkm-common.sh" || exit 1;
validate_program_and_working_paths || exit 1;

FILE="${1}"
DATE="${2}"
HASH="${2}" # yeah, 2.

if [[ ! -f "$FILE" ]];
then
    echo "File not found: '$FILE'" 1>&2
    exit 1;
fi;

# if patch is a symlink or alias for busybox patch applet
BUSYBOX=$(patch --help 2>&1 | head -n 1 | grep -i busybox -c);

function busybox_patch {

    local TEMP_FILE="${1}"
    local TEMP_DIFF="${2}"

    # Workaround for busybox: remove the empty old file before calling the applet "patch".
    # Summary of the only issue I found: https://github.com/bazelbuild/rules_go/issues/2042
    # 1.  "can't open 'BUILD.bazel': File exists"
    # 2.  "I suspect patch on Alpine is following POSIX semantics and requires the -E flag."
    # 3.  "-E  --remove-empty-files Remove output files that are empty after patching."
    # 4.  Busybox don't have the option '-E', which is a GNU extension, i.e. not POSIX.
    if [[ ! -s "${TEMP_FILE}" ]];
    then
        rm "${TEMP_FILE}"
    fi;
    
    patch -u "${TEMP_FILE}" "${TEMP_DIFF}" > /dev/null;
    
    touch "${TEMP_FILE}" # undo the workaround
}

function gnu_patch {

    local TEMP_FILE="${1}"
    local TEMP_DIFF="${2}"
    
    patch -u "${TEMP_FILE}" "${TEMP_DIFF}" > /dev/null;
}

function apply_patch {

    local TEMP_FILE="${1}"
    local TEMP_DIFF="${2}"
    local TEMP_HASH="${3}"
    
    if [[ $BUSYBOX -eq 1 ]];
    then
        busybox_patch "${TEMP_FILE}" "${TEMP_DIFF}";
    else
        gnu_patch "${TEMP_FILE}" "${TEMP_DIFF}";
    fi;
    
    if [[ -n "${TEMP_HASH}" ]];
    then
        if [[ "`file_hash "${TEMP_FILE}"`" != "${TEMP_HASH}" ]];
        then
            echo "Error while loading history: hashes don't match." > /dev/stderr;
            rm -f "${TEMP_FILE}" "${TEMP_DIFF}";
            exit 1;
        fi;
    fi;
}

function load_hist {

    local FILE="${1}"
    local DATE="${2}"
    local HASH="${3}"
    
    local HIST="`path_hist "$FILE"`"
    
    if [[ ! "${HIST}" ]];
    then
        echo "No history for file '$FILE'." > /dev/stderr;
        exit 1;
    fi;
    
    local TEMP_DATE="";
    local TEMP_HASH="";
    local TEMP_DIFF="`make_temp`"
    local TEMP_FILE="`make_temp`"
    
    while IFS= read -r line; do
    
        if [[ $line =~ ^$HIST_FILE_INF0 ]];
        then
            # ignore
            continue;
        elif [[ $line =~ ^$HIST_DIFF_START ]];
        then
        
            cat /dev/null > "${TEMP_DIFF}";
            
            TEMP_DATE="`echo "${line}" \
                | sed -E "s/^$HIST_DIFF_START *//" \
                | awk 'BEGIN { FS="'"${TAB}"'" } {print $1}'`";
            TEMP_HASH="`echo "${line}" \
                | sed -E "s/^$HIST_DIFF_START *//" \
                | awk 'BEGIN { FS="'"${TAB}"'" } {print $2}'`";
            
            continue;
        elif [[ $line =~ ^$HIST_DIFF_END ]];
        then
        
            if [[ -n "${DATE}" && "${DATE}" =~ ^\< ]];
            then
                if [[ `unix_secs "${TEMP_DATE}"` -ge `unix_secs "${DATE/</}"` ]];
                then
                    break;
                fi;
            fi;
            
            apply_patch "${TEMP_FILE}" "${TEMP_DIFF}" "${TEMP_HASH}";
            
            if [[ -n "${HASH}" && "${TEMP_HASH}" =~ ^"${HASH}" ]];
            then
                break;
            fi;
            
            if [[ -n "${DATE}" && "${TEMP_DATE}" == "${DATE}" ]];
            then
                break;
            fi;
            
            if [[ -n "${DATE}" && "${DATE}" =~ ^\> ]];
            then
                if [[ `unix_secs "${TEMP_DATE}"` -gt `unix_secs "${DATE/>/}"` ]];
                then
                    break;
                fi;
            fi;
            
            continue;
        fi;

        echo "${line}" >> "${TEMP_DIFF}";
    
    done < <(cat "${HIST}")
    
    cat "${TEMP_FILE}" && rm -f "${TEMP_FILE}" "${TEMP_DIFF}";
}

load_hist "$FILE" "$DATE" "$HASH"


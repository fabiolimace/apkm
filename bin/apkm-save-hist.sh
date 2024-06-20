#!/bin/bash

#
# Saves history in `hist` folder and `hist.db`.
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

function file_diff {
    local FILE="${1}"
    
    # TODO: generate a real diff
    cat <<EOF
--- lao	2002-02-21 23:30:39.942229878 -0800
+++ tzu	2002-02-21 23:30:50.442260588 -0800
@@ -1,7 +1,6 @@
-The Way that can be told of is not the eternal Way;
-The name that can be named is not the eternal name.
 The Nameless is the origin of Heaven and Earth;
-The Named is the mother of all things.
+The named is the mother of all things.
+
 Therefore let there always be non-being,
   so we may see their subtlety,
 And let there always be being,
@@ -9,3 +8,6 @@
 The two are the same,
 But after they are produced,
   they have different names.
+They both may be called deep and profound.
+Deeper and more profound,
+The door of all subtleties!
EOF

}

function save_hist_fs {

    local FILE="${1}"
    local UUID="${2}"
    
    local HIST=`path_meta "$FILE" "hist"`
    mkdir --parents "`dirname "$HIST"`"
    
    local UPDT # Update date
    local HASH # File hash
    local DIFF # Unified DIFF

    UPDT="`now`"
    HASH="`file_hash "$FILE"`"
    DIFF="`file_diff "$FILE"`" # FIXME: escape doublequotes
    
    if [[ ! -f "${HIST}" ]];
    then
        echo "#% path=${FILE}" >> "${HIST}"
        echo "#% uuid=${UUID}" >> "${HIST}"
        echo >> "${HIST}"
    fi;
    
    cat >> "$HIST" <<EOF
#@ ${UPDT}${TAB}${HASH}
${DIFF}
EOF

}

function save_hist_db {

    local FILE="${1}"
    local UUID="${2}"
    
    local HIST=`path_meta "$FILE" "hist"`

    local UPDT # Update date
    local HASH # File hash
    local DIFF # Unified DIFF
    
    # reading it backwards
    while read -s line; do
    
        if [[ "$line" =~ ^#@ ]];
        then
            # found the last diff header; time to get its values and break the loop
            UPDT="`echo "$line" | sed 's/^#@ *//' | awk 'BEGIN { FS="'"$TAB"'" } { print $1 }'`"
            HASH="`echo "$line" | sed 's/^#@ *//' | awk 'BEGIN { FS="'"$TAB"'" } { print $2 }'`"
            break;
        else
            DIFF="${line}${LF}${DIFF}" # FIXME: escape singlequotes
        fi;
        
    done < <(tac "${HIST}")
    
    if [[ -z "$UPDT" || -z "$HASH" ]];
    then
        echo "Error while saving history: '$FILE'" 1>&2
        exit 1;
    fi;
    
    echo "INSERT OR REPLACE INTO hist_ values ('$UUID', '$UPDT', '$HASH', '$DIFF');" | sed "s/''/NULL/g" | sqlite3 "$DATABASE";
}

FILE="${1}"
UUID="`path_uuid "$FILE"`"

if [[ ! -f "$FILE" ]];
then
    echo "File not found: '$FILE'" 1>&2
    exit 1;
fi;

save_hist_fs "$FILE" "$UUID"
save_hist_db "$FILE" "$UUID"


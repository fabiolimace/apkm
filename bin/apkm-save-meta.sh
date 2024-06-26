#!/bin/bash

#
# Saves metadata in `meta` folder and `apkm.db`.
#
# Usage:
#
#     apwm-save-meta.sh FILE
#

FILE="${1}"

if [[ ! -f "$FILE" ]];
then
    echo "File not found: '$FILE'" 1>&2
    exit 1;
fi;

source "`dirname "$0"`/apkm-common.sh" || exit 1;
validate_program_and_working_paths || exit 1;

function save_meta_fs {

    local FILE="${1}"
    local META=`path_meta "$FILE" "meta"`
    
    mkdir --parents "`dirname "$META"`"
    
    local UUID # UUIDv8 of the file path
    local ROAD # Path relative to the base directory
    local NAME # File name
    local HASH # File hash
    local CRDT # Create date
    local UPDT # Update date
    local TAGS # Comma separated values

    UUID="`path_uuid "$FILE"`"
    ROAD="$FILE"
    NAME="`basename "$FILE"`"
    HASH="`file_hash "$FILE"`"
    CRDT="`now`"
    UPDT="`now`"
    
    # read list of tags
    while read -s line; do
        if [[ -z "$TAGS" ]]; then
            TAGS="$line";
        else
            TAGS="$TAGS,$line";
        fi;
    done < <("$PROGRAM_DIR/apkm-tags.awk" "$FILE");

    cat > "$META" <<EOF
uuid=$UUID
path=$ROAD
name=$NAME
hash=$HASH
crdt=$CRDT
updt=$CRDT
tags=$TAGS
EOF

}

function save_meta_db {

    local FILE="${1}"
    local META=`path_meta "$FILE" "meta"`

    local UUID # UUIDv8 of the file path
    local ROAD # Path relative to the base directory
    local NAME # File name
    local HASH # File hash
    local CRDT # Create date
    local UPDT # Update date
    local TAGS # Comma separated values
    
    while read -s line; do
        case "$line" in
            uuid=*)
                UUID=`echo "$line" | grep "^uuid=" | sed "s/^uuid=//"`
                ;;
            path=*)
                ROAD=`echo "$line" | grep "^path=" | sed "s/^path=//"`
                ;;
            name=*)
                NAME=`echo "$line" | grep "^name=" | sed "s/^name=//"`
                ;;
            hash=*)
                HASH=`echo "$line" | grep "^hash=" | sed "s/^hash=//"`
                ;;
            crdt=*)
                CRDT=`echo "$line" | grep "^crdt=" | sed "s/^crdt=//"`
                ;;
            updt=*)
                UPDT=`echo "$line" | grep "^updt=" | sed "s/^updt=//"`
                ;;
            tags=*)
                TAGS=`echo "$line" | grep "^tags=" | sed "s/^tags=//"`
                ;;
        esac
    done < "$META"
    
    echo "INSERT OR REPLACE INTO meta_ values ('$UUID', '$ROAD', '$NAME', '$HASH', '$CRDT', '$UPDT', '$TAGS');" | sed "s/''/NULL/g" | sqlite3 "$DATABASE";
}

save_meta_fs "$FILE"
save_meta_db "$FILE"



#!/bin/bash

#
# Saves links in `meta` folder and `meta.db`.
#
# Usage:
#
#     apwm-save-links.sh FILE
#

source "`dirname "$0"`/apkm-common.sh" || exit 1;
validate_program_and_working_paths || exit 1;

function save_links_fs {
    local FILE="${1}"
    local META=`path_meta "$FILE" "link"`
    mkdir --parents "`dirname "$META"`"
    "$PROGRAM_DIR/apkm-list-links.awk" "$FILE" > "$META"
}

function save_links_db {

    local FILE="${1}"
    local META=`path_meta "$FILE" "link"`
    
    local ORIG # UUIDv8 of the origin file
    local DEST # UUIDv8 of the destination file
    local HREF # Path relative to the origin file (as is) or URL
    local ROAD # Path relative to the base directory (normalized)
    local TYPE # Link type: Internal (I), External (E)
    local BROK # Broken link: unknown (0), broken (1)
    
    while read -s line; do
        
        HREF="$line"
        ORIG="`path_uuid "$FILE"`"
        
        if [[ "$HREF" =~ https?:\/\/ ]];
        then
            local STATUS="`http_status "$HREF"`"
            if [[ "$STATUS" == "200" ]];
            then
                BROK="0";
                ROAD="";
                DEST="";
            else
                BROK="1";
                ROAD="";
                DEST="";
            fi;
            TYPE="E";
        else
            local NORM_HREF=`normalize_href "$HREF"`
            if [[ -f "$NORM_HREF" ]];
            then
                BROK="0";
                ROAD="$NORM_HREF"
                DEST="`path_uuid "$ROAD"`";
            else
                BROK="1";
                ROAD=""
                DEST="";
            fi;
            TYPE="I";
        fi;
        
        echo "INSERT INTO link_ values ('$ORIG', '$DEST', '$HREF', '$ROAD', '$TYPE', '$BROK');" | sed "s/''/NULL/g" | sqlite3 "$DATABASE";
        
    done < "$META"
}

function http_status {
    local HREF="$1"
    timeout 5s wget --server-response --spider --quiet "$HREF" 2>&1 | awk 'NR==1{print $2}'
}

function normalize_href {

    local FILE="${1}"
    local HREF="${1}"
    
    local BASE=`dirname "$FILE"`
    
    local NORM_HREF=""
    local NORM_HREF_OPTION_1="$BASE/$HREF"
    local NORM_HREF_OPTION_2=`path_remove_dots "$BASE/$HREF"`
    
    # use option 2, without dots, if both HREFs ponit to same file
    if [[ -f "$NORM_HREF_OPTION_1" && -f "$NORM_HREF_OPTION_2" ]];
    then
        # check if both options of HREF point to the same file, i.e. the same inode on the file system
        if [[ "`stat -c %d:%i "$NORM_HREF_OPTION_1"`" == "`stat -c %d:%i "$NORM_HREF_OPTION_2"`" ]]; then
            NORM_HREF="$NORM_HREF_OPTION_2";
        else
            NORM_HREF="$NORM_HREF_OPTION_1";
        fi;
    else
        NORM_HREF="$NORM_HREF_OPTION_1";
    fi;
    
    echo "$NORM_HREF";
}

FILE="${1}"
save_links_fs "$FILE"
save_links_db "$FILE"



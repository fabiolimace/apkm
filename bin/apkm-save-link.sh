#!/bin/sh

#
# Saves links in `link` folder and `apkm.db`.
#
# Usage:
#
#     apwm-save-link.sh FILE
#

. "`dirname "$0"`/apkm-common.sh";

file="${1}"
require_file "${file}";

save_link_fs() {
    local file="${1}"
    local link=`path_link "${file}"`
    "$PROGRAM_DIR/apkm-link.awk" "${file}" > "${link}"
}

save_link_db() {

    local file="${1}"
    local link=`path_link "${file}"`
    
    local orig # UUIDv8 of the origin file
    local dest # UUIDv8 of the destination file
    local href # Path relative to the origin file (as is) or URL
    local path # Path relative to the base directory (normalized)
    local type # Link type: Internal (I), External (E)
    local brok # Broken link: unknown (0), broken (1)
    
    while read -r line; do
        
        href="$line"
        orig="`path_uuid "${file}"`"
        
        if match "${href}" "https?:\/\/";
        then
            local status="`http_status "${href}"`"
            if [ "${status}" = "200" ]; then
                brok="0";
                path="";
                dest="";
            else
                brok="1";
                path="";
                dest="";
            fi;
            type="E";
        else
            local norm_href=`normalize_href "${href}"`
            if [ -f "$norm_href" ]; then
                brok="0";
                path="$norm_href"
                dest="`path_uuid "${path}"`";
            else
                brok="1";
                path="";
                dest="";
            fi;
            type="I";
        fi;
        
        echo "INSERT OR REPLACE INTO link_ values ('${orig}', '${dest}', '${href}', '${path}', '${type}', '${brok}');" | sed "s/''/NULL/g" | sqlite3 "$DATABASE";
        
    done < "${link}"
}

http_status() {
    local href="$1"
    timeout 5s wget --server-response --spider --quiet "${href}" 2>&1 | awk 'NR==1 { print $2 }'
}

normalize_href() {

    local file="${1}"
    local href="${1}"
    
    local base=`dirname "${file}"`
    
    local norm_href=""
    local norm_href_option_1="${base}/${href}"
    local norm_href_option_2=`path_remove_dots "${base}/${href}"`
    
    # use option 2, without dots, if both HREFs ponit to same file
    if [ -f "${norm_href_option_1}" ] && [ -f "${norm_href_option_2}" ]; then
        # check if both options of HREF point to the same file, i.e. the same inode on the file system
        if [ "`stat -c %d:%i "${norm_href_option_1}"`" = "`stat -c %d:%i "${norm_href_option_2}"`" ]; then
            norm_href="${norm_href_option_2}";
        else
            norm_href="${norm_href_option_1}";
        fi;
    else
        norm_href="${norm_href_option_1}";
    fi;
    
    echo "$norm_href";
}

main() {
    local file="${1}"
    save_link_fs "${file}"
    [ $ENABLE_DB -eq 1 ] && save_link_db "${file}"
}

main "${file}";


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
temp=`make_temp`
require_file "${file}";

save_link_fs() {

    local link="${1}"
    local orig="${2}"
    local dest="${3}"
    local href="${4}"
    local path="${5}"
    local type="${6}"
    local brok="${7}"
    
    sort "${temp}" | uniq > "${link}";
}


save_link_db() {

    local link="${1}"
    local orig="${2}"
    local dest="${3}"
    local href="${4}"
    local path="${5}"
    local type="${6}"
    local brok="${7}"
    
    if [ -f "${link}" ]; then
        echo "DELETE FROM link_ WHERE orig_ = '${orig}';" | sed "s/''/NULL/g" | sqlite3 "$DATABASE";
        
        while read -r line; do
            
            orig=`echo "${line}" | awk -F "\t" '{ print $1 }'`
            dest=`echo "${line}" | awk -F "\t" '{ print $2 }'`
            href=`echo "${line}" | awk -F "\t" '{ print $3 }'`
            path=`echo "${line}" | awk -F "\t" '{ print $4 }'`
            type=`echo "${line}" | awk -F "\t" '{ print $5 }'`
            brok=`echo "${line}" | awk -F "\t" '{ print $6 }'`
            
            echo "INSERT OR REPLACE INTO link_ values ('${orig}', '${dest}', '${href}', '${path}', '${type}', '${brok}');" | sed "s/''/NULL/g" | sqlite3 "$DATABASE";
            
        done < "${link}"
    fi;
}

http_status() {
    local href="$1"
    timeout 1s wget --server-response --spider --quiet "${href}" 2>&1 | awk 'NR==1 { print $2 }'
}

normalize_href() {

    local href=`path_remove_slashes "${1}"`
    
    local norm_href=""
    local norm_href_option_1="${href}"
    local norm_href_option_2=`path_remove_dots "${href}"`
    
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
    local link=`path_link "${file}"`
    
    local orig=`path_uuid "${file}"` # UUIDv8 of the origin file
    local dest # UUIDv8 of the destination file
    local href # Path relative to the origin file (as is) or URL
    local path # Path relative to the base directory (normalized)
    local type # Link type: Internal (I), External (E), Fragment (F)
    local brok # Broken link: unknown (0), broken (1)
    
    "$PROGRAM_DIR/apkm-link.awk" "${file}" | while read -r line; do
        
        href="$line";
        
        if match "${href}" "https?:\/\/";
        then
            local status="`http_status "${href}"`"
            if [ "${status}" = "200" ]; then
                brok="0";
            else
                brok="1";
            fi;
            dest="";
            path="";
            type="E";
        elif match "${href}" "^#"; then
            brok="0"; # TODO: check if the fragment is exists in the current file
            dest="";
            path="";
            type="F";
        else
            local norm_href=`normalize_href "${href}"`
            if [ -f "$norm_href" ]; then
                brok="0";
                dest="`path_uuid "${path}"`";
            else
                brok="1";
                dest="";
            fi;
            path="$norm_href";
            type="I";
        fi;
        
        printf "${orig}\t${dest}\t${href}\t${path}\t${type}\t${brok}\n" >> "${temp}";
        
    done;
    
    save_link_fs "${link}" "${orig}" "${dest}" "${href}" "${path}" "${type}" "${brok}"
    [ $ENABLE_DB -eq 1 ] && save_link_db "${link}" "${orig}" "${dest}" "${href}" "${path}" "${type}" "${brok}"
    
    rm -f "${temp}";
}

main "${file}";


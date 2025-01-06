#!/bin/sh

#
# Saves metadata and links in `meta` folder.
#
# Usage:
#
#     apwm-save.sh FILE
#

. "`dirname "$0"`/apkm-common.sh";

# find only .md files
find_regex=".*.\(md\)$";

# ignore the .apkm folder
ignore_regex="\\.\(apkm\)";


file_changed() {

    local file="${1}"
    local hash=`file_hash "${file}"`
    local uuid=`path_uuid "${file}"`;
    local meta=`make_meta "${uuid}"`;
    
    local result=1;
    
    if [ -f "${meta}" ];
    then
        local prev=`grep -E "^hash=" "${meta}" | head -n 1 | sed "s/^hash=//";`
    
        if [ "${hash}" = "${prev}" ];
        then
            result=0;
        fi;
    fi;
    
    echo ${result};
}

main() {
    cd "$WORKING_DIR";
    find . -type f -regex "${find_regex}" | grep -v "${ignore_regex}" | while read -r line; do
    
        file=`echo $line | sed 's,^\./,,'`; # remove leading "./"
        changed=`file_changed "${file}"`;
        
        if [ ${changed} -eq 1 ]; then
            "$PROGRAM_DIR/apkm-save-meta.sh" "$file";
            "$PROGRAM_DIR/apkm-save-link.sh" "$file";
            "$PROGRAM_DIR/apkm-save-hist.sh" "$file";
            "$PROGRAM_DIR/apkm-save-html.sh" "$file";
        fi;
    done;
}

main;


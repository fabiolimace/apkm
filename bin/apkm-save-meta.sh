#!/bin/sh

#
# Saves metadata in `meta` folder and `apkm.db`.
#
# Usage:
#
#     apwm-save-meta.sh FILE
#

. "`dirname "$0"`/apkm-common.sh";

file="${1}"
require_file "${file}"

save_meta_fs() {

    local file="${1}"
    local meta=`path_meta "${file}" "meta"`
    
    local uuid # UUIDv8 of the file path
    local path # Path relative to the base directory
    local name # File name without extension
    local hash # File hash
    local crdt # Create date
    local updt # Update date
    local tags # Comma separated values

    uuid="`path_uuid "${file}"`"
    path="${file}"
    name="`basename --suffix=.md "${file}"`"
    hash="`file_hash "${file}"`"
    crdt="`now`"
    updt="`now`"
    tags="`list_tags "${file}"`"

    if [ -f "${meta}" ];
    then
        sed -i "s/^hash=.*/hash=${hash}/" "${meta}";
        sed -i "s/^updt=.*/updt=${updt}/" "${meta}";
        sed -i "s/^tags=.*/tags=${tags}/" "${meta}";
    else

    cat > "${meta}" <<EOF
uuid=${uuid}
path=${path}
name=${name}
hash=${hash}
crdt=${crdt}
updt=${updt}
tags=${tags}
EOF

    fi;
}

save_meta_db() {

    local file="${1}"
    local meta=`path_meta "${file}" "meta"`

    local uuid # UUIDv8 of the file path
    local path # Path relative to the base directory
    local name # File name
    local hash # File hash
    local crdt # Create date
    local updt # Update date
    local tags # Comma separated values
    
    while read -r line; do
        case "${line}" in
            uuid=*)
                uuid=`echo "${line}" | grep "^uuid=" | sed "s/^uuid=//"`
                ;;
            path=*)
                path=`echo "${line}" | grep "^path=" | sed "s/^path=//"`
                ;;
            name=*)
                name=`echo "${line}" | grep "^name=" | sed "s/^name=//"`
                ;;
            hash=*)
                hash=`echo "${line}" | grep "^hash=" | sed "s/^hash=//"`
                ;;
            crdt=*)
                crdt=`echo "${line}" | grep "^crdt=" | sed "s/^crdt=//"`
                ;;
            updt=*)
                updt=`echo "${line}" | grep "^updt=" | sed "s/^updt=//"`
                ;;
            tags=*)
                tags=`echo "${line}" | grep "^tags=" | sed "s/^tags=//"`
                ;;
        esac
    done < "${meta}"
    
    echo "INSERT OR REPLACE INTO meta_ values ('${uuid}', '${path}', '${name}', '${hash}', '${crdt}', '${updt}', '${tags}');" | sed "s/''/NULL/g" | sqlite3 "$DATABASE";
}

main() {
    local file="${1}"
    save_meta_fs "${file}"
    [ $ENABLE_DB -eq 1 ] && save_meta_db "${file}"
}

main "${file}";


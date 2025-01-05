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
    local road # Path relative to the base directory
    local name # File name
    local hash # File hash
    local crdt # Create date
    local updt # Update date
    local tags # Comma separated values

    uuid="`path_uuid "${file}"`"
    road="${file}"
    name="`basename "${file}"`"
    hash="`file_hash "${file}"`"
    crdt="`now`"
    updt="`now`"
    
    # read list of tags
    "$PROGRAM_DIR/apkm-tags.awk" "${file}" | while read -r line; do
        if [ -z "${tags}" ]; then
            tags="${line}";
        else
            tags="${tags},${line}";
        fi;
    done;

    cat > "${meta}" <<EOF
uuid=${uuid}
path=${road}
name=${name}
hash=${hash}
crdt=${crdt}
updt=${updt}
tags=${tags}
EOF

}

save_meta_db() {

    local file="${1}"
    local meta=`path_meta "${file}" "meta"`

    local uuid # UUIDv8 of the file path
    local road # Path relative to the base directory
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
                road=`echo "${line}" | grep "^path=" | sed "s/^path=//"`
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
    
    echo "INSERT OR REPLACE INTO meta_ values ('${uuid}', '${road}', '${name}', '${hash}', '${crdt}', '${updt}', '${tags}');" | sed "s/''/NULL/g" | sqlite3 "$DATABASE";
}

main() {
    local file="${1}"
    save_meta_fs "${file}"
    [ $ENABLE_DB -eq 1 ] && save_meta_db "${file}"
}

main "${file}";


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

last_hash() {
    local meta="${1}"
    grep -E "^hash=" "${meta}" | head -n 1 | sed "s/^hash=//";
}

save_meta_fs() {

    local file="${1}"
    local uuid="${2}"
    local path="${3}"
    local name="${4}"
    local hash="${5}"
    local crdt="${6}"
    local updt="${7}"
    local tags="${8}"
    
    local meta=`path_meta "${file}" "meta"`;
    
    cat > "${meta}" <<EOF
uuid=${uuid}
path=${path}
name=${name}
hash=${hash}
crdt=${crdt}
updt=${updt}
tags=${tags}
EOF

}

save_meta_db() {

    local file="${1}"
    local uuid="${2}"
    local path="${3}"
    local name="${4}"
    local hash="${5}"
    local crdt="${6}"
    local updt="${7}"
    local tags="${8}"
    
    if [ -f "${file}" ]; then
        echo "INSERT OR REPLACE INTO meta_ values ('${uuid}', '${path}', '${name}', '${hash}', '${crdt}', '${updt}', '${tags}');" | sed "s/''/NULL/g" | sqlite3 "$DATABASE";
    fi;
}

main() {

    local file="${1}"
    local uuid="`path_uuid "${file}"`"         # UUIDv8 of the file path
    local path="${file}"                       # Path relative to base directory
    local name="`basename -s ".md" "${file}"`" # File name without extension
    local hash="`file_hash "${file}"`"         # File hash
    local crdt="`now`"                         # Create date
    local updt="`now`"                         # Update date
    local tags="`list_tags "${file}"`"         # Comma separated values
    
    local meta=`path_meta "${file}" "meta"`;
    
    if [ -f "${meta}" ];
    then
        if [ "${hash}" = "`last_hash "${meta}"`" ];
        then
            return;
        fi;
        crdt=`grep -E "^crdt=" "${meta}" | head -n 1 | sed "s/^crdt=//"`;
    fi;
    
    save_meta_fs "${file}" "${uuid}" "${path}" "${name}" "${hash}" "${crdt}" "${updt}" "${tags}"
    [ $ENABLE_DB -eq 1 ] && save_meta_db "${file}" "${uuid}" "${path}" "${name}" "${hash}" "${crdt}" "${updt}" "${tags}"
}

main "${file}";


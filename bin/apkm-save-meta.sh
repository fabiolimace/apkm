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

    local meta="${1}"
    local uuid="${2}"
    local path="${3}"
    local name="${4}"
    local hash="${5}"
    local crdt="${6}"
    local updt="${7}"
    local tags="${8}"
    
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

    local meta="${1}"
    local uuid="${2}"
    local path="${3}"
    local name="${4}"
    local hash="${5}"
    local crdt="${6}"
    local updt="${7}"
    local tags="${8}"
    
    if [ -f "${meta}" ]; then
        echo "INSERT OR REPLACE INTO meta_ values ('${uuid}', '${path}', '${name}', '${hash}', '${crdt}', '${updt}', '${tags}');" | sed "s/''/NULL/g" | sqlite3 "$DATABASE";
    fi;
}

main() {

    local file="${1}"
    local meta=`path_meta "${file}" "meta"`;
    
    local uuid # UUIDv8 of the file path
    local path # Path relative to base directory
    local name # File name without extension
    local hash # File hash
    local crdt # Create date
    local updt # Update date
    local tags # Comma separated values
    
    local uuid="`path_uuid "${file}"`"
    local path="${file}"
    local name="`basename -s ".md" "${file}"`"
    local hash="`file_hash "${file}"`"
    local crdt="`now`"
    local updt="`now`"
    local tags="`list_tags "${file}"`"
    
    if [ -f "${meta}" ];
    then
        crdt=`grep -E "^crdt=" "${meta}" | head -n 1 | sed "s/^crdt=//"`;
    fi;
    
    save_meta_fs "${meta}" "${uuid}" "${path}" "${name}" "${hash}" "${crdt}" "${updt}" "${tags}"
    [ $ENABLE_DB -eq 1 ] && save_meta_db "${meta}" "${uuid}" "${path}" "${name}" "${hash}" "${crdt}" "${updt}" "${tags}"
}

main "${file}";


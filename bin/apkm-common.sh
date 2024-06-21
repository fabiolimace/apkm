#!/bin/bash

#
# Common variables and functions for APKM.
#
# Usage:
# 
#    source "`dirname "$0"`/apkm-common.sh" || exit 1;
#    validate_program_and_working_paths || exit 1;
#
#    OR (in the case of apkm-init.sh):
#
#    source "`dirname "$0"`/apkm-common.sh" || exit 1;
#    validate_program_path || exit 1;
#

PROGRAM_DIR=`dirname "$0"` # The place where the bash and awk scripts are
WORKING_DIR=`pwd -P` # The place where the markdown files are

HTML_DIR="$WORKING_DIR/.apkm/html";
META_DIR="$WORKING_DIR/.apkm/meta";
DATABASE="$WORKING_DIR/.apkm/meta.db"

CR=$'\r'
LF=$'\n'
TAB=$'\t'

function validate_program_path {

    if [[ ! -f "$PROGRAM_DIR/apkm-init.sh" ]];
    then
        echo "Not the APKM program directory: '$PROGRAM_DIR'" 1>&2
        exit 1;
    fi;
    
    while read -r line; do
        if [[ ! -e "$line" ]];
        then
            echo "File or directory not found: '$line'" 1>&2
            exit 1;
        fi;
    done <<EOF
$PROGRAM_DIR/apkm-html.awk
$PROGRAM_DIR/apkm-links.awk
$PROGRAM_DIR/apkm-tags.awk
$PROGRAM_DIR/apkm-httpd.sh
$PROGRAM_DIR/apkm-save.sh
$PROGRAM_DIR/apkm-save-html.sh
$PROGRAM_DIR/apkm-save-links.sh
$PROGRAM_DIR/apkm-save-meta.sh
$PROGRAM_DIR/apkm-save-hist.sh
EOF

}

function validate_working_path {
    if [[ ! -d "$WORKING_DIR/.apkm" ]];
    then
        echo "Not a APKM markdown directory: '$WORKING_DIR'" 1>&2
        exit 1;
    fi;
    
    while read -r line; do
        if [[ ! -e "$line" ]];
        then
            echo "File or directory not found: '$line'" 1>&2
            exit 1;
        fi;
    done <<EOF
$WORKING_DIR/.apkm/html
$WORKING_DIR/.apkm/meta
$WORKING_DIR/.apkm/meta.db
$WORKING_DIR/.apkm/conf.txt
EOF

    if [[ "$PWD" != "$WORKING_DIR" ]];
    then
        echo "Out of the APKM markdown directory: '$PWD' != '$WORKING_DIR'" 1>&2
        exit 1;
    fi;
}

function validate_program_and_working_paths {
     validate_program_path || exit 1;
     validate_working_path || exit 1;
}

function now {
    date -Iseconds; # ISO-8601: 0000-00-00T00:00:00+00:00
}

function file_hash {
    local FILE="${1}"
    sha1sum "${FILE}" | head -c 40
}

function path_hash {
    local FILE="${1}"
    echo -n "${FILE}" | sha1sum | head -c 40
}

function file_uuid {
    local FILE="${1}"
    local HASH=`file_hash "$FILE"`
    uuid "$HASH"
}

function path_uuid {
    local FILE="${1}"
    local HASH=`path_hash "$FILE"`
    uuid "$HASH"
}

# get hash UUID
function uuid {
    local HASH="${1}"
    # generate a UUIDv8 using the first 32 chars of the file hash
    printf "%s-%s-%s%s-%s%s-%s" "${HASH:0:8}" "${HASH:8:4}" '8' "${HASH:13:3}" '8' "${HASH:17:3}" "${HASH:20:12}"
}

function path {
    local FILE=${1}
    
    if [[ ! -f "$FILE" ]];
    then
        echo "File not found: '$FILE'"
        exit 1;
    fi;
    # TODO
}

function path_meta {
    local FILE="${1}"
    local SUFF="${2}"
    local NAME=`basename "$FILE"`
    local ROAD=`dirname "$FILE" | sed 's,^/,,'`
    echo "$META_DIR/$ROAD/$NAME.$SUFF"
}

function path_html {
    local FILE="${1}"
    local SUFF="html"
    local NAME=`basename "$FILE"`
    local ROAD=`dirname "$FILE" | sed 's,^/,,'`
    echo "$HTML_DIR/$ROAD/$NAME.$SUFF"
}

# Remove all "./" and "../" from paths,
# except "../" in the start of the path.
# The folder before "../" is also deleted.
# ./a/b/./c/file.txt -> ./a/b/c/file.txt
# ../a/b/../c/file.txt -> ../a/c/file.txt
function path_remove_dots {
    local FILE="${1}"
    echo "$FILE" \
    | awk '{ while ($0 ~ /\/\.\//) { sub(/\/\.\//, "/") }; print }' \
    | awk '{ while ($0 ~ /\/[^\/]+\/\.\.\//) { sub(/\/[^\/]+\/\.\.\//, "/") }; print }' \
    | awk '{ sub(/^\.\//, "") ; print }'
}


#!/bin/sh

#
# Common variables and functions for APKM.
#
# Usage:
# 
#    . "`dirname "$0"`/apkm-common.sh";
#

PROGRAM_DIR=`dirname "$0"` # The place where the bash and awk scripts are
WORKING_DIR=`pwd -P` # The place where the markdown files are

HIST_DIR="$WORKING_DIR/.apkm/hist";
HTML_DIR="$WORKING_DIR/.apkm/html";
META_DIR="$WORKING_DIR/.apkm/meta";
LINK_DIR="$WORKING_DIR/.apkm/link";
DATABASE="$WORKING_DIR/.apkm/apkm.db"

CR="`printf "\r"`" # POSIX <carriage-return>
LF="`printf "\n"`" # POSIX <newline>
HT="`printf "\t"`" # POSIX <tab>

HIST_FILE_INFO="##"
HIST_DIFF_START="#@"
HIST_DIFF_END="#%"

NUMB_REGEX="^-?[0-9]+$";
HASH_REGEX="^[a-f0-9]{40}$";
DATE_REGEX="^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$"
UUID_REGEX="^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$";

validate_program_deps() {
    for dep in awk git sqlite3; do
        if [ -z "$(which $dep)" ];
        then
            echo "Dependency not installed: '$dep'" 1>&2
            exit 1;
        fi;
    done;
}

validate_program_path() {

    if [ ! -f "$PROGRAM_DIR/apkm-init.sh" ];
    then
        echo "Not the APKM program directory: '$PROGRAM_DIR'" 1>&2
        exit 1;
    fi;
    
    while read -r line; do
        if [ ! -e "$line" ];
        then
            echo "File or directory not found: '$line'" 1>&2
            exit 1;
        fi;
    done <<EOF
$PROGRAM_DIR/apkm-html.awk
$PROGRAM_DIR/apkm-link.awk
$PROGRAM_DIR/apkm-tags.awk
$PROGRAM_DIR/apkm-httpd.sh
$PROGRAM_DIR/apkm-save.sh
$PROGRAM_DIR/apkm-save-html.sh
$PROGRAM_DIR/apkm-save-link.sh
$PROGRAM_DIR/apkm-save-meta.sh
$PROGRAM_DIR/apkm-save-hist.sh
EOF

}

validate_working_path() {

    if [ ! -d "$WORKING_DIR/.apkm" ];
    then
        echo "Not a APKM markdown directory: '$WORKING_DIR'" 1>&2
        exit 1;
    fi;
    
    while read -r line; do
        if [ ! -e "$line" ];
        then
            echo "File or directory not found: '$line'" 1>&2
            exit 1;
        fi;
    done <<EOF
$WORKING_DIR/.apkm/hist
$WORKING_DIR/.apkm/html
$WORKING_DIR/.apkm/meta
$WORKING_DIR/.apkm/link
$WORKING_DIR/.apkm/apkm.db
$WORKING_DIR/.apkm/conf.txt
EOF

    if [ "$PWD" != "$WORKING_DIR" ];
    then
        echo "Out of the APKM markdown directory: '$PWD' != '$WORKING_DIR'" 1>&2
        exit 1;
    fi;
}

now() {
    date_time;
}

unix_secs() {
    local input=${1};
    date -d "${input}" +%s;
}

date_time() {
    local input=${1};
    if [ -n "${input}" ];
    then
        if match "${input}" ${DATE_REGEX}; then
            date -d "${input}" +"%F %T";
        elif match "${input}" ${NUMB_REGEX}; then
            date -d @"${input}" +"%F %T";
        else
            date -d @0 +"%F %T"; # epoch
        fi;
    else
        date +"%F %T";
    fi;
}

file_updt() {
    local file="${1}"
    date_time $(stat -c %Y "${file}");
}

file_hash() {
    local file="${1}"
    sha1sum "${file}" | head -c 40
}

path_uuid() {
    local path="${1}"
    local hash=`echo -n "${path}" | sha256sum`;
    echo "${hash}" | awk '{ print substr($0,1,8) "-" substr($0,9,4) "-8" substr($0,14,3) "-8" substr($0,18,3) "-" substr($0,21,12) }'
}

make_path() {
    local base="${1}"
    local file="${2}"
    local suff="${3}"
    path_remove_dots "$base/$file.$suff"
}

path_meta() {
    make_path "${META_DIR}" "${1}" "meta"
}

path_link() {
    make_path "${LINK_DIR}" "${1}" "link"
}

path_hist() {
    make_path "${HIST_DIR}" "${1}" "hist"
}

path_html() {
    make_path "${HTML_DIR}" "${1}" "html"
}

# Remove all "./" and "../" from paths,
# except "../" in the start of the path.
# The folder before "../" is also deleted.
# ./a/b/./c/file.txt -> ./a/b/c/file.txt
# ../a/b/../c/file.txt -> ../a/c/file.txt
path_remove_dots() {
    local file="${1}"
    echo "$file" \
    | awk '{ while ($0 ~ /\/\.\//) { sub(/\/\.\//, "/") }; print }' \
    | awk '{ while ($0 ~ /\/[^\/]+\/\.\.\//) { sub(/\/[^\/]+\/\.\.\//, "/") }; print }' \
    | awk '{ sub(/^\.\//, "") ; print }'
}

make_temp() {
    # prefere the tmpfs device
    if [ -d "/dev/shm" ]; then
        mktemp -p /dev/shm;
    else
        mktemp;
    fi;
}

require_file() {
    local file="${1}";
    local mesg="${2}";
    if [ ! -f "${file}" ]; then
        test -n "${mesg}" \
            && (echo "${mesg}" 1>&2) \
            || (echo "File not found: '${file}'" 1>&2);
        exit 1;
    fi;
}

symlinked_busybox() {
    program=`which "${1}"` && (stat -c "%N" "${program}" | grep -q busybox)
}

match() {
    local text="${1}";
    local rexp="${2}";
    echo "${text}" | grep -E -q "${rexp}";
}

validate() {

    if [ -n "$validate" ] && [ "$validate" -eq 0 ]; then
        return;
    fi;
    
    validate_program_deps || exit 1;
    validate_program_path || exit 1;
    if match "$0" "apkm-init.sh"; then
        :
    else
        validate_working_path || exit 1;
    fi;
}

main() {
    validate;
}

main;

# See [POSIX Definitions](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap03.html):
# 3.40 Basename
# 3.129 Directory
# 3.130 Directory Entry (or Link)
# 3.136 Dot
# 3.137 Dot-Dot
# 3.164 File
# 3.170 Filename
# 3.171 Filename String
# 3.193 Home Directory
# 3.235 Name
# 3.268 Parent Directory
# 3.271 Pathname
# 3.272 Pathname Component
# 3.273 Path Prefix
# 3.281 Portable Filename
# 3.282 Portable Filename Character Set
# 3.324 Relative Pathname
# 3.330 Root Directory
# 3.447 Working Directory (or Current Working Directory)


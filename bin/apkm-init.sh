#!/bin/bash

#
# Initializes the APKM in the current directory.
#
# Also:
#
# *   Initializes a SQLite database, creating its tables.
# *   Initializes a GIT repository, commiting all existing markdown files.
#
# Usage:
#
#     # Backup!
#     apkm-init.sh
#
# How to undo initialization:
#
#     # Be careful and backup!
#     rm -rf DIRECTORY/.apkm
#     rm -rf DIRECTORY/.git
#
# Where DIRECTORY is where this init script was executed.
#

source "`dirname "$0"`/apkm-common.sh" || exit 1;
validate_program_path || exit 1;

function apkm_init_fs {
    
    echo "----------------------"
    echo "Init directory"
    echo "----------------------"
   
    mkdir --verbose --parents "$WORKING_DIR/.apkm"
    mkdir --verbose --parents "$WORKING_DIR/.apkm/html"
    mkdir --verbose --parents "$WORKING_DIR/.apkm/meta"
    
cat > "$WORKING_DIR/.apkm/conf.txt" <<EOF
busybox.httpd.port=127.0.0.1:9000
EOF

}

function apkm_init_db {

    echo "----------------------"
    echo "Init SQLite"
    echo "----------------------"
    
    sqlite3 -echo "$WORKING_DIR/.apkm/meta.db" <<EOF
-- Create metadata table
CREATE TABLE meta_ (
    uuid_ TEXT PRIMARY KEY, -- UUIDv8 of the file path
    path_ TEXT NOT NULL, -- Path relative to the base directory
    name_ TEXT NOT NULL, -- File name
    hash_ TEXT NOT NULL, -- File hash
    crdt_ TEXT NOT NULL, -- Create date
    updt_ TEXT NOT NULL, -- Update date
    tags_ TEXT NULL, -- Comma separated values
    CHECK (crdt_ REGEXP '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'),
    CHECK (updt_ REGEXP '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'),
    CHECK (uuid_ REGEXP '[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}')
) STRICT;
-- Create links table
CREATE TABLE link_ (
    orig_ TEXT NOT NULL, -- UUIDv8 of the origin file
    dest_ TEXT NULL, -- UUIDv8 of the destination file
    href_ TEXT NOT NULL, -- Path relative to the origin file (as is) or URL
    path_ TEXT NULL, -- Path relative to the base directory (normalized)
    type_ TEXT NOT NULL, -- Link type: Internal (I), External (E)
    brok_ INTEGER DEFAULT 0 NOT NULL, -- Broken link: unknown (0), broken (1)
    CHECK (type_ IN ('I', 'E')),
    CHECK (brok_ IN (0, 1)),
    CHECK (orig_ REGEXP '[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}'),
    CHECK (dest_ REGEXP '[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}'),
    FOREIGN KEY (orig_) REFERENCES meta_ (uuid_),
    FOREIGN KEY (dest_) REFERENCES meta_ (uuid_),
    PRIMARY KEY (orig_, href_)
) STRICT;
EOF

}

function apkm_init_git {
    
    echo "----------------------"
    echo "Init GIT"
    echo "----------------------"
    
    git init --initial-branch=main
    git config user.name "apkm"
    git config user.email "apkm@example.com"
    find "$WORKING_DIR/" -type f -name "*.md" -exec git add {} \;
    git commit -m "[apkm] init"

cat > .gitignore <<EOF
.git/*
.apkm/*
.gitignore
EOF

}

if [[ ! -d "$WORKING_DIR" ]];
then
    echo "Base directory not found."
    exit 1;
fi;

if [[ -d "$WORKING_DIR/.apkm" ]];
then
    echo "APKM already initialized in this directory."
    exit 1;
fi;

if [[ -f "$WORKING_DIR/.apkm/meta.db" ]];
then
    echo "SQLite already initialized in this directory." 1>&2;
    exit 1;
fi;

if [[ -d "$WORKING_DIR/.git" ]];
then
    echo "GIT already initialized in this directory." 1>&2;
    exit 1;
fi;

apkm_init_fs;
apkm_init_db;
apkm_init_git;



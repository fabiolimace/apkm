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
busybox.httpd.bind=localhost:9000
EOF

}

function apkm_init_db {

    echo "----------------------"
    echo "Init SQLite"
    echo "----------------------"
    
    sqlite3 -echo "$WORKING_DIR/.apkm/meta.db" <<EOF
-- Create metadata table
CREATE TABLE meta_ (
    uuid_ TEXT, -- UUIDv8 of the file path
    path_ TEXT, -- Path relative to the base directory
    name_ TEXT, -- File name
    hash_ TEXT, -- File hash
    crdt_ TEXT, -- Create date
    updt_ TEXT, -- Update date
    tags_ TEXT, -- Comma separated values
    CONSTRAINT meta_uuid_ PRIMARY KEY (uuid_)
) STRICT;
-- Create links table
CREATE TABLE link_ (
    orig_ TEXT, -- UUIDv8 of the origin file
    dest_ TEXT, -- UUIDv8 of the destination file
    href_ TEXT NOT NULL, -- Link destination as in the text
    type_ TEXT NOT NULL, -- Link type: Internal (I), External (E)
    brok_ INTEGER DEFAULT 0, -- Broken link: unknown (0), broken (1)
    CHECK (type_ IN ('I', 'E')),
    CHECK (brok_ IN (0, 1)),
    PRIMARY KEY (orig_, dest_),
    FOREIGN KEY (orig_) REFERENCES meta_ (uuid_),
    FOREIGN KEY (dest_) REFERENCES meta_ (uuid_)
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



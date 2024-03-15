APKM
======================================================

APKM stands for Awk Personal Knowledge Management.

It is a set of tools for managing a collection of markdown files.

Directory structure
------------------------------------------------------

This is the basic directory structure:

```
base
├── .apkm
│   ├── conf.txt
│   ├── html
│   ├── meta
│   └── meta.db
└── .git
```

The markdown files will be saved in the `base` directory.

The files related to APKM tools will be saved in `base/.apkm`, including configurations, metadata and HTML files. The `.apkm` directory is managed by the APKM tools. The base directory can be anyone that has a `.apkm` directory inside of it.

Additionally, git related files will be in `base/.git`. The `.git` directory is managed by the `git` program. The version management will be provided by this software.

Metadata Structure
------------------------------------------------------

### Metadata files

The metadata file structure:

```
uuid: # UUIDv8 of the file path
path: # Path relative to the base directory
name: # File name
hash: # File hash
crdt: # Create date
updt: # Update date
tags: # Comma separated values
```

The list of links file structure:

```
1: link1
2: link2
3: link3
```

The metadata file and the list of links file have the same relative path of the markdown files, with an additional suffix. The suffix for metadata is ".meta", while the suffix for list of links is ".link".

Both files are updated before the respective entities in the SQLite tables. The function that updates the SQLite tables reads these files instead of the markdown files. In other words, the SQL database is build and refreshed based on them.

These files also serve as backups for reconstruction of the SQL detabase if it eventually gets corrupted.

### Metadata tables

The metadata table schema:

```sql
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
```

The links table schema:

```sql
CREATE TABLE link_ (
    orig_ TEXT, -- UUIDv8 of the origin file
    dest_ TEXT, -- UUIDv8 of the destination file
    href_ TEXT, -- Link destination as in the text
    type_ TEXT NOT NULL, -- Link type: Internal (I), External (E)
    brok_ INTEGER DEFAULT 0, -- Broken link: unknown (0), broken (1)
    CHECK (type_ IN ('I', 'E')),
    CHECK (brok_ IN (0, 1)),
    PRIMARY KEY (orig_, dest_),
    FOREIGN KEY (orig_) REFERENCES meta_ (uuid_),
    FOREIGN KEY (dest_) REFERENCES meta_ (uuid_)
) STRICT;
```

The links table is more detailed than the list of links file.

To Do List
------------------------------------------------------

This is a list of features to be implemented:

* A function to normalize relative paths.
* A function to check wether a link is internal or external.
    - If a link is internal, `link_.dest_` is a UUID and HREF is the relative path to a file.
    - If a link is external, `link_.dest_` is NULL and HREF is the URL to an external resource.
* A function to check if internal links are broken, verifying whether the file pointed by the path exists.
* A function to check if external links may be broken, verifying whether a HTTP request returns 200 (OK) or 404 (NOK).
* A function to move a file from a path to another, while updating and normalizing links.
* A function to remove a file from a path to another, while deleting marking links pointing to it as broken.
* A script to convert markdown texts to HTML files, placing the output into .apkm/html
* A simple script to serve the HTML files in `.apkm/html` in the local interface at a specific port.
* A script to generate metadata about markdown texts, placing the output into .apkm/meta
    - The metadata will be saved as files in .apkm/meta.
    - The metadata will also be saved in a SQLite database in .apkm/meta.db.

Goals:
* Make it Busybox `awk` and GNU's `gawk`

References for Busybox `awk`:

* https://wiki.alpinelinux.org/wiki/Awk
* https://wiki.alpinelinux.org/wiki/Regex

License
------------------------------------------------------

This project is Open Source software released under the [MIT license](https://opensource.org/licenses/MIT).


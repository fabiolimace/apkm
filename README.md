APKM
======================================================

APKM stands for Awk Personal Knowledge Management.

It is a set of tools for managing a collection of markdown files.

Dependencies:

* Git (optional);
* SQLite (optional);
* Ubuntu's `mawk`, GNU's `gawk` or Busybox's `awk`.
* Ubuntu's `dash`, GNU's `bash` or Busybox's `ash`.

You must `cd` to the directory where your markdown collection in order to use the tools.

Directory structure
------------------------------------------------------

This is the basic directory structure:

```
base
├── .apkm
│   ├── apkm.db
│   ├── conf.txt
│   ├── hist
│   ├── html
│   ├── link
│   └── meta
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

The metadata file and the list of links file have the same relative path of the markdown files, with an additional suffix. The suffix for metadata is ".meta", while the suffix for list of links is ".link".

Both files are updated before the respective entities in the SQLite tables. The function that updates the SQLite tables reads these files instead of the markdown files. In other words, the SQL database is build and refreshed based on them.

These files also serve as backups for reconstruction of the SQL detabase if it eventually gets corrupted.

### Metadata tables

The metadata table schema:

```sql
CREATE TABLE meta_ (
    uuid_ TEXT PRIMARY KEY, -- UUIDv8 of the file path
    path_ TEXT NOT NULL, -- Path relative to the base directory
    name_ TEXT NOT NULL, -- File name
    hash_ TEXT NOT NULL, -- File hash
    crdt_ TEXT NOT NULL, -- Create date
    updt_ TEXT NOT NULL, -- Update date
    tags_ TEXT NULL, -- Comma separated values
    CHECK (hash_ REGEXP '^[a-f0-9]{40}$'),
    CHECK (crdt_ REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'),
    CHECK (updt_ REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'),
    CHECK (uuid_ REGEXP '^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')
) STRICT;
```

The links table schema:

```sql
CREATE TABLE link_ (
    orig_ TEXT NOT NULL, -- UUIDv8 of the origin file
    dest_ TEXT NULL, -- UUIDv8 of the destination file
    href_ TEXT NOT NULL, -- Path relative to the origin file (as is) or URL
    path_ TEXT NULL, -- Path relative to the base directory (normalized)
    type_ TEXT NOT NULL, -- Link type: Internal (I), External (E)
    brok_ INTEGER DEFAULT 0 NOT NULL, -- Broken link: unknown (0), broken (1)
    CHECK (type_ IN ('I', 'E')),
    CHECK (brok_ IN (0, 1)),
    CHECK (orig_ REGEXP '^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$'),
    CHECK (dest_ REGEXP '^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$'),
    FOREIGN KEY (orig_) REFERENCES meta_ (uuid_),
    FOREIGN KEY (dest_) REFERENCES meta_ (uuid_),
    PRIMARY KEY (orig_, href_)
) STRICT;
```

The history table schema:

```sql
CREATE TABLE hist_ (
    uuid_ TEXT, -- UUIDv8 of the file path
    updt_ TEXT NOT NULL, -- Update date
    hash_ TEXT NOT NULL, -- File hash
    CHECK (uuid_ REGEXP '^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$'),
    CHECK (updt_ REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'),
    CHECK (hash_ REGEXP '^[a-f0-9]{40}$'),
    FOREIGN KEY (uuid_) REFERENCES meta_ (uuid_),
    PRIMARY KEY (uuid_, updt_, hash_)
) STRICT;
```

Note: the links table is more detailed than the list of links file.

To Do List
------------------------------------------------------

This is a list of features to be implemented:

* [x] A function to normalize relative paths.
* [x] A function to check whether a link is internal or external.
    - If a link is internal, `link_.dest_` is a UUID, HREF is relative to the file and PATH is relative to the base directory.
    - If a link is external, `link_.dest_` is NULL and HREF is the URL to an external resource and PATH is NULL.
* [x] A function to check if internal links are broken, verifying whether the file pointed by the path exists.
* [x] A function to check if external links may be broken, verifying whether a HTTP request returns 200 (OK) or 404 (NOK).
* [ ] A function to move a file from a path to another, while updating and normalizing links.
* [ ] A function to remove a file from a path to another, while deleting marking links pointing to it as broken.
* [x] A script to convert markdown texts to HTML files, placing the output into .apkm/html
* [x] A simple script to serve the HTML files in `.apkm/html` in the local interface at a specific port.
* [x] A script to generate metadata about markdown texts, placing the output into .apkm/meta
    - The metadata will be saved as files in .apkm/meta.
    - The metadata will also be saved in a SQLite database in .apkm/apkm.db.
* [x] Implement a [UUIDv8](https://gist.github.com/fabiolimace/8821bb4635106122898a595e76102d3a)
* [x] History directory to track file changes.
* [ ] An index page that lists all HTML pages.
* [ ] A search box in the top of the index page.
* [ ] A simple bag of words for searching HTML pages.
* [ ] A simple access counter for HTML page access.
* [ ] A simple change history for each HTML page.
* [ ] Tests for Ubuntu's `dash`, GNU's `bash`, and BusyBox's `ash`.
* [ ] Tests for Ubuntu's `mawk`, GNU's `gawk`, and BusyBox's `awk`.

References for Busybox `awk`:

* https://wiki.alpinelinux.org/wiki/Awk
* https://wiki.alpinelinux.org/wiki/Regex

License
------------------------------------------------------

This project is Open Source software released under the [MIT license](https://opensource.org/licenses/MIT).


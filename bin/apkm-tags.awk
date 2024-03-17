#!/usr/bin/awk -f

#
# Lists all tags found in a markdown file.
#
# Tags must be in Twitter format: letters, numbers and underscore.
#
# Usage:
#
#     awk -f apkm-tags.awk FILE
#     busybox awk -f apkm-tags.awk FILE
#
# It works with gawk and Busybox.
#
# Busybox don't support diacritics. Avoid them.
#

# https://unix.stackexchange.com/q/379385/
function find_all(str, regex, matches,    n) {
    
    n = 0;
    delete matches;
    
    while (match(str, regex) > 0) {
        matches[++n] = substr(str, RSTART, RLENGTH);
        if (str == "") break;
        str = substr(str, RSTART + (RLENGTH ? RLENGTH : 1));
    }
    
    return n;
}

$0 !~ "^#" && $0 ~ "#[[:alpha:]][[:alnum:]]+" {

    n = find_all($0, "#[[:alpha:]][[:alnum:]]+", tags);
    

    for (i = 1; i <= n; i++) {
        printf "%s\n", substr(tags[i], 2);
    }
}


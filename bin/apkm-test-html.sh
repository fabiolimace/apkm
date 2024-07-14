#!/bin/sh

#
# Runs the Markdown tests.
#

validate="0"

. "`dirname "$0"`/apkm-common.sh";

file=/tmp/test.md
html=/tmp/test.html
tmpl=/tmp/tmpl.html

generate_template() {
    cat /dev/null > "${tmpl}"
    echo "---" |"$PROGRAM_DIR/apkm-html.awk" > "${tmpl}"
}

exit_error() {
    echo ""
    echo "Test ${1} failed!";
    exit 1;
}

run_test() {

    local file="${1}"
    local html="${2}"
    local numb="${3}"
    
    generate_template;
    
    sed -E '/<hr>/,$d' "${tmpl}" >> "${html}.temp"
    cat "${html}" >> "${html}.temp"
    sed -E '1,/<hr>/d' "${tmpl}" >> "${html}.temp"
    mv "${html}.temp" "${html}"
    
    "$PROGRAM_DIR/apkm-html.awk" "${file}" | diff - "${html}" \
        || exit_error ${3};
}

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cat <<EOF > /tmp/test.md
This is an _italic_ word.
EOF

cat <<EOF > /tmp/test.html
<p>
This is an <em>italic</em> word.
</p>
EOF
    
run_test "${file}" "${html}" 1;

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cat <<EOF > /tmp/test.md
A First Level Header
====================

A Second Level Header
---------------------

Now is the time for all good men to come to
the aid of their country. This is just a
regular paragraph.

The quick brown fox jumped over the lazy
dog's back.

### Header 3
> This is a blockquote.
> 
> This is the second paragraph in the blockquote.
>
> ## This is an H2 in a blockquote
EOF

cat <<EOF > /tmp/test.html
<h1>
A First Level Header
</h1>
<h2>
A Second Level Header
</h2>
<p>
Now is the time for all good men to come to the aid of their country. This is just a regular paragraph.
</p>
<p>
The quick brown fox jumped over the lazy dog's back.
</p>
<h3>
Header 3
</h3>
<blockquote>
<p>
This is a blockquote.
</p>
<p>
This is the second paragraph in the blockquote.
</p>
<h2>
This is an H2 in a blockquote
</h2>
</blockquote>
EOF

run_test "${file}" "${html}" 2;

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


